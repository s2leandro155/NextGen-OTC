/*
 * Copyright (c) 2010-2026 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "drawpool.h"
#include <framework/util/profiler.h>

#include "painter.h"
#include "textureatlas.h"
#include "render/linetriangulation.h"
#include "render/poolcompiler.h"
#include "graphics.h"

bool DrawPool::s_compileFrames = false;

DrawPool* DrawPool::create(const DrawPoolType type)
{
    auto pool = new DrawPool;
    if (type == DrawPoolType::MAP || type == DrawPoolType::FOREGROUND) {
        pool->setFramebuffer({});
        if (type == DrawPoolType::MAP) {
            pool->m_framebuffer->m_useAlphaWriting = false;
            pool->m_framebuffer->disableBlend();
        } else if (type == DrawPoolType::FOREGROUND) {
            pool->setFPS(10);

            // creates a temporary framebuffer with smoothing.
            pool->m_temporaryFramebuffers.emplace_back(std::make_shared<FrameBuffer>());
        }
    } else if (type == DrawPoolType::LIGHT) {
        pool->m_hashCtrl = true;
    } else {
        pool->m_alwaysGroupDrawings = true; // CREATURE_INFORMATION & TEXT
        pool->setFPS(500);
    }

    pool->m_type = type;
    return pool;
}

void DrawPool::add(const Color& color, const TexturePtr& texture, DrawMethod&& method, const CoordsBufferPtr& coordsBuffer)
{
    const AtlasRegion* atlasRegion = nullptr;

    if (texture) {
        if (!method.src.isValid() && (!coordsBuffer || coordsBuffer->size() == 0)) {
            resetOnlyOnceParameters();
            return; // invalid draw: texture has no source rect and no vertex coordinates
        }

        if (m_atlas) {
            if (const auto region = texture->getAtlasRegion(m_atlas->getType())) {
                if (region->isEnabled()) {
                    atlasRegion = region;

                    if (method.src.isValid())
                        method.src.translate(region->x, region->y);
                }
            }
        }
    }

    if (!updateHash(method, atlasRegion ? atlasRegion->atlas : texture.get(), color, coordsBuffer != nullptr)) {
        resetOnlyOnceParameters();
        return;
    }

    auto& list = m_objects[m_currentDrawOrder];
    auto& state = getCurrentState();

    // `!list.back().action` is what keeps an action object a BATCH BARRIER. It used to be
    // implied by actions having no coords, but a tagged action now carries its declared
    // geometry there, and merging live geometry into it would delete that geometry from the
    // GL render - drawObject runs the callback and never looks at coords.
    if (!list.empty() && list.back().coords && !list.back().action && list.back().state == state) {
        auto& last = list.back();
        coordsBuffer ? last.coords->append(coordsBuffer.get()) : addCoords(*last.coords, method);
    } else if (m_alwaysGroupDrawings) {
        auto& coords = m_coords.try_emplace(state.hash, nullptr).first->second;
        if (!coords) {
            coords = list.emplace_back(getState(texture, atlasRegion, color), getCoordsBuffer()).coords.get();
        }
        coordsBuffer ? coords->append(coordsBuffer.get()) : addCoords(*coords, method);
    } else {
        auto& draw = list.emplace_back(getState(texture, atlasRegion, color), getCoordsBuffer());
        coordsBuffer ? draw.coords->append(coordsBuffer.get()) : addCoords(*draw.coords, method);
    }

    resetOnlyOnceParameters();
}

void DrawPool::addCoords(CoordsBuffer& buffer, const DrawMethod& method)
{
    if (method.type == DrawMethodType::BOUNDING_RECT) {
        buffer.addBoudingRect(method.dest, method.intValue);
    } else if (method.type == DrawMethodType::RECT) {
        buffer.addRect(method.dest, method.src);
    } else if (method.type == DrawMethodType::TRIANGLE) {
        buffer.addTriangle(method.a, method.b, method.c);
    } else if (method.type == DrawMethodType::UPSIDEDOWN_RECT) {
        buffer.addUpsideDownRect(method.dest, method.src);
    } else if (method.type == DrawMethodType::REPEATED_RECT) {
        buffer.addRepeatedRects(method.dest, method.src);
    }
}

bool DrawPool::updateHash(const DrawMethod& method, const Texture* texture, const Color& color, const bool hasCoord) {
    auto& state = getCurrentState();
    state.hash = 0;

    { // State Hash
        if (m_bindedFramebuffers > -1)
            stdext::hash_combine(state.hash, m_lastFramebufferId);

        if (state.blendEquation != BlendEquation::ADD) {
            // Tagged, because the two enums now live in the same small integer range. They used
            // to carry GL constants (MAX was 0x8008) so their hashes could not collide; plain
            // enumerators put BlendEquation::MAX and CompositionMode::MULTIPLY both at 1, and
            // PoolState equality is hash equality - two states differing only in these fields
            // would batch together and render with the wrong one. Dormant today (nothing sets a
            // non-ADD equation) but it would be silent when it fires.
            stdext::hash_combine(state.hash, 0x100u | static_cast<uint32_t>(state.blendEquation));
        }

        if (state.compositionMode != CompositionMode::NORMAL)
            stdext::hash_combine(state.hash, state.compositionMode);

        if (state.opacity < 1.f)
            stdext::hash_combine(state.hash, state.opacity);

        if (state.clipRect.isValid())
            stdext::hash_union(state.hash, state.clipRect.hash());

        if (state.shaderProgram)
            stdext::hash_union(state.hash, state.shaderProgram->hash());

        if (state.transformMatrix != DEFAULT_MATRIX3)
            stdext::hash_union(state.hash, state.transformMatrix.hash());

        if (color != Color::white)
            stdext::hash_union(state.hash, color.hash());

        if (texture)
            stdext::hash_union(state.hash, texture->hash());
    }

    if (hasFrameBuffer()) { // Pool Hash
        size_t hash = state.hash;

        if (method.type == DrawMethodType::TRIANGLE) {
            if (!method.a.isNull()) stdext::hash_union(hash, method.a.hash());
            if (!method.b.isNull()) stdext::hash_union(hash, method.b.hash());
            if (!method.c.isNull()) stdext::hash_union(hash, method.c.hash());
        } else if (method.type == DrawMethodType::BOUNDING_RECT) {
            if (method.intValue) stdext::hash_combine(hash, method.intValue);
        } else {
            if (method.dest.isValid()) stdext::hash_union(hash, method.dest.hash());
            if (method.src.isValid()) stdext::hash_union(hash, method.src.hash());
        }

        // check to skip the next drawing that is the same as the previous one.
        if (!hasCoord && m_hashCtrl.isLast(hash))
            return false;

        m_hashCtrl.put(hash);
    }

    return true;
}

DrawPool::PoolState DrawPool::getState(const TexturePtr& texture, const AtlasRegion* atlasRegion, const Color& color)
{
    PoolState copy = getCurrentState();

    if (copy.color != color)
        copy.color = color;

    if (atlasRegion) {
        Texture* textureAtlas = atlasRegion->atlas;
        // Texture is batched inside an atlas.
        //
        // The handle names the layer as a RENDER TARGET, not as a sampled texture, because that
        // is what a layer is: its pixels live wherever the active backend keeps target contents.
        // Resolving it through the texture plane happened to work on OpenGL, where a
        // FrameBuffer's colour attachment is an ordinary GL texture; it cannot work anywhere the
        // two are different objects.
        copy.textureId = textureAtlas->getId();
        copy.textureMatrixId = textureAtlas->getTransformMatrixId();
        copy.textureHandle = RenderHandles::targetTexture(atlasRegion->layerTarget);
        copy.textureRevision = textureAtlas->getContentRevision();
    } else if (texture) {
        if (texture->isEmpty() || // Texture not initialized in the current OpenGL context
            !texture->canCacheInAtlas() || // Texture is marked as non-atlas-cacheable (short-lived/temporary, e.g. minimap)
            (m_atlas && m_atlas->canAdd(texture)) // Force this texture to be packed into the current pool atlas,
                                                  // even if it might already belong to another DrawPool's atlas
        ) {
            copy.texture = texture;
        } else {
            // Standalone GL texture cached in memory (non-atlased)
            copy.textureId = texture->getId();
            copy.textureMatrixId = texture->getTransformMatrixId();
        }
        copy.textureHandle = TextureHandle{ texture->getUniqueId() };
        copy.textureRevision = texture->getContentRevision();
    }

    return copy;
}
void DrawPool::setCompositionMode(const CompositionMode mode, const bool onlyOnce)
{
    if (onlyOnce && !(m_onlyOnceStateFlag & STATE_COMPOSITE_MODE)) {
        m_previousCompositionMode = getCurrentState().compositionMode;
        m_onlyOnceStateFlag |= STATE_COMPOSITE_MODE;
    }
    getCurrentState().compositionMode = mode;
}

void DrawPool::setBlendEquation(const BlendEquation equation, const bool onlyOnce)
{
    if (onlyOnce && !(m_onlyOnceStateFlag & STATE_BLEND_EQUATION)) {
        m_previousBlendEquation = getCurrentState().blendEquation;
        m_onlyOnceStateFlag |= STATE_BLEND_EQUATION;
    }
    getCurrentState().blendEquation = equation;
}

void DrawPool::setClipRect(const Rect& clipRect, const bool onlyOnce)
{
    if (onlyOnce && !(m_onlyOnceStateFlag & STATE_CLIP_RECT)) {
        m_previousClipRect = getCurrentState().clipRect;
        m_onlyOnceStateFlag |= STATE_CLIP_RECT;
    }
    getCurrentState().clipRect = clipRect;
}

void DrawPool::setOpacity(const float opacity, const bool onlyOnce)
{
    if (onlyOnce && !(m_onlyOnceStateFlag & STATE_OPACITY)) {
        m_previousOpacity = getCurrentState().opacity;
        m_onlyOnceStateFlag |= STATE_OPACITY;
    }
    getCurrentState().opacity = opacity;
}

void DrawPool::setShaderProgram(const PainterShaderProgramPtr& shaderProgram, const bool onlyOnce, const std::function<void()>& action)
{
    if (g_painter->isReplaceColorShader(getCurrentState().shaderProgram))
        return;

    if (onlyOnce && !(m_onlyOnceStateFlag & STATE_SHADER_PROGRAM)) {
        m_previousShaderProgram = getCurrentState().shaderProgram;
        m_previousShaderAction = getCurrentState().action;
        m_onlyOnceStateFlag |= STATE_SHADER_PROGRAM;
    }

    if (shaderProgram) {
        if (!g_painter->isReplaceColorShader(shaderProgram.get()))
            m_shaderRefreshDelay = FPS20;

        getCurrentState().shaderProgram = shaderProgram.get();
        getCurrentState().action = action;
    } else {
        getCurrentState().shaderProgram = nullptr;
        getCurrentState().action = nullptr;
    }
}

void DrawPool::resetState()
{
    m_coords.clear();
    m_parameters.clear();

    m_hashCtrl.reset();

    getCurrentState() = {};
    m_lastFramebufferId = 0;
    m_shaderRefreshDelay = 0;
    m_scale = DEFAULT_DISPLAY_DENSITY;
}

bool DrawPool::canRepaint()
{
    if (!m_enabled || shouldRepaint())
        return false;

    return canRefresh();
}

void DrawPool::release() {
    PROFILE_ZONE(PoolRelease);
    if (hasFrameBuffer() && !m_hashCtrl.wasModified() && !canRefresh()) {
        for (auto& objs : m_objects)
            objs.clear();
        m_objectsFlushed.clear();

        // Vulkan path: the blit's dest/src can change (map widget being moved) even when
        // the CONTENT hash is unchanged - GL takes them fresh from prepare() on every
        // draw, so we too publish them always, together with the old object list.
        SpinLock::Guard guard(m_threadLock);
        m_fbDest = m_pendingFbDest;
        m_fbSrc = m_pendingFbSrc;
        m_fbClearColor = m_pendingFbClearColor;
        m_mapHole = m_pendingMapHole;
        m_uploads.swap(m_pendingUploads);
        m_pendingUploads.clear();
        m_compositionMaterial = m_pendingCompositionMaterial;
        m_compositionExtraTex = m_pendingCompositionExtraTex;
        m_compositionParams = m_pendingCompositionParams;
        m_compositionOpacity = m_pendingCompositionOpacity;
        return;
    }

    m_refreshTimer.restart();

    {
        SpinLock::Guard guard(m_threadLock);

        // Publish the framebuffer dest/src for the Vulkan path - together with the object list,
        // under the same lock, so the feeder never sees rects from a different frame than the objects.
        m_fbDest = m_pendingFbDest;
        m_fbSrc = m_pendingFbSrc;
        m_fbClearColor = m_pendingFbClearColor;
        m_mapHole = m_pendingMapHole;
        m_uploads.swap(m_pendingUploads);
        m_pendingUploads.clear();
        m_compositionMaterial = m_pendingCompositionMaterial;
        m_compositionExtraTex = m_pendingCompositionExtraTex;
        m_compositionParams = m_pendingCompositionParams;
        m_compositionOpacity = m_pendingCompositionOpacity;

        m_objectsDraw[0].clear();

        if (!m_objectsFlushed.empty()) {
            if (m_objectsDraw[0].size() < m_objectsFlushed.size())
                m_objectsDraw[0].swap(m_objectsFlushed);

            if (!m_objectsFlushed.empty()) {
                m_objectsDraw[0].insert(
                    m_objectsDraw[0].end(),
                    std::make_move_iterator(m_objectsFlushed.begin()),
                    std::make_move_iterator(m_objectsFlushed.end()));
            }
            m_objectsFlushed.clear();
        }

        for (auto& objs : m_objects) {
            if (m_objectsDraw[0].size() < objs.size())
                m_objectsDraw[0].swap(objs);

            bool addFirst = true;

            if (!m_objectsDraw[0].empty() && !objs.empty()) {
                auto& last = m_objectsDraw[0].back();
                auto& first = objs.front();

                if (last.state == first.state && last.coords && first.coords
                    && !last.action && !first.action) {
                    last.coords->append(first.coords.get());
                    addFirst = false;
                }
            }

            if (!objs.empty()) {
                m_objectsDraw[0].insert(
                    m_objectsDraw[0].end(),
                    std::make_move_iterator(objs.begin() + (addFirst ? 0 : 1)),
                    std::make_move_iterator(objs.end()));
                objs.clear();
            }
        }

    } // m_threadLock

    // Compiled OUTSIDE the lock, deliberately. Phase 2 compiled inside it because the published
    // list is what a consumer may swap away the instant the lock drops - but that is only true
    // once m_shouldRepaint says so, and it does not yet. No consumer touches m_objectsDraw[0]
    // while the flag is false, so this window is exclusively the producer's, and Phase 3 needs
    // both paths live at once rather than a spinlock held for the length of a compile.
    compilePublishedObjects();

    {
        SpinLock::Guard guard(m_threadLock);
        m_programBuild.swap(m_programPublished);
        m_shouldRepaint.store(true, std::memory_order_relaxed);
    }
}

// The render thread's counterpart to release(). Takes the newly published program if there is
// one, and consumes the repaint flag exactly as DrawPoolManager::drawObjects does - which is
// not optional: the map thread blocks in canDrawMap until the flag is consumed.
//
// Three program slots rather than two, for the same reason the object list has two buffers and
// a publish slot: `build` is the producer's, `published` is the handover, `draw` is the
// consumer's and stays valid until the consumer itself replaces it. With only two, a second
// publish while the consumer was still reading would overwrite the object it was reading.
const PoolProgram* DrawPool::acquireProgram()
{
    SpinLock::Guard guard(m_threadLock);

    if (m_shouldRepaint.load(std::memory_order_relaxed)) {
        m_objectsDraw[0].swap(m_objectsDraw[1]);
        m_programPublished.swap(m_programDraw);
        m_shouldRepaint.store(false, std::memory_order_relaxed);
    }

    if (m_programDraw)
        refreshCompiledComposition(*m_programDraw);

    return m_programDraw.get();
}

// Whether the program this pool would contribute can be executed faithfully. Peeks without
// consuming, so a frame that has to fall back to the legacy path has not already eaten the
// repaint flags the legacy path needs.
bool DrawPool::hasUsableProgram()
{
    SpinLock::Guard guard(m_threadLock);

    const PoolProgram* program = m_shouldRepaint.load(std::memory_order_relaxed)
        ? m_programPublished.get()
        : m_programDraw.get();

    return program == nullptr || program->isComplete();
}

// The blit's dest, src, material and opacity can change while the CONTENT hash does not - a map
// widget being dragged is the standing example - and in that case release() takes its early
// return and never recompiles. GL has no equivalent problem because it reads them fresh from
// prepare() on every draw. So the consumer refreshes them here, on the program it is about to
// use, which it exclusively owns.
void DrawPool::refreshCompiledComposition(PoolProgram& program) const
{
    if (!program.hasComposition || !m_framebuffer || !m_framebuffer->isValid())
        return;

    const Rect full(0, 0, m_framebuffer->getSize());
    program.compositionDest = m_fbDest.isValid() ? m_fbDest : full;
    program.compositionSrc = m_fbSrc.isValid() ? m_fbSrc : full;
    program.compositionMaterial = m_compositionMaterial;
    program.compositionExtraTex = m_compositionExtraTex;
    program.compositionParams = m_compositionParams;
    program.compositionOpacity = m_compositionOpacity;
}

// Compiles what release() has just put in m_objectsDraw[0], into m_programBuild. The swap into
// m_programPublished is the caller's, under the lock, together with the repaint flag - so that a
// consumer never sees a program published ahead of the objects it describes.
void DrawPool::compilePublishedObjects()
{
    if (!s_compileFrames)
        return;

    PROFILE_ZONE(PoolCompile);

    if (!m_programBuild)
        m_programBuild = std::make_unique<PoolProgram>();

    PoolCompiler::compile(*this, g_graphics.getViewportSize(), *m_programBuild);

    // A program that could not express something is not a usable description of the frame.
    // Log it once per pool rather than per frame: if it happens at all it happens constantly,
    // and the useful signal is WHICH idiom was met, not how many times.
    if (!m_programBuild->isComplete() && !m_loggedUnsupported) {
        m_loggedUnsupported = true;
        for (const auto& reason : m_programBuild->unsupported)
            g_logger.warning("[render] pool {} could not be compiled: {}", static_cast<int>(m_type), reason);
    }
}

void DrawPool::flush()
{
    m_coords.clear();

    for (auto& objs : m_objects) {
        bool addFirst = true;
        if (!objs.empty() && !m_objectsFlushed.empty()) {
            auto& last = m_objectsFlushed.back();
            auto& first = objs.front();

            if (last.state == first.state && last.coords && first.coords
                && !last.action && !first.action) {
                last.coords->append(first.coords.get());
                addFirst = false;
            }
        }

        m_objectsFlushed.insert(
            m_objectsFlushed.end(),
            std::make_move_iterator(objs.begin() + (addFirst ? 0 : 1)),
            std::make_move_iterator(objs.end())
        );
        objs.clear();
    }
}

void DrawPool::scale(const float factor)
{
    if (m_scale == factor)
        return;

    m_scale = factor;
    getCurrentState().transformMatrix = DEFAULT_MATRIX3 * Matrix3{
      factor,   0.0f,  0.0f,
        0.0f, factor,  0.0f,
        0.0f,   0.0f,  1.0f
    }.transposed();
}

void DrawPool::translate(const float x, const float y)
{
    const Matrix3 translateMatrix = {
            1.0f,  0.0f,     x,
            0.0f,  1.0f,     y,
            0.0f,  0.0f,  1.0f
    };

    getCurrentState().transformMatrix = getCurrentState().transformMatrix * translateMatrix.transposed();
}

void DrawPool::rotate(const float angle)
{
    const Matrix3 rotationMatrix = {
            std::cos(angle), -std::sin(angle),  0.0f,
            std::sin(angle),  std::cos(angle),  0.0f,
                       0.0f,             0.0f,  1.0f
    };

    getCurrentState().transformMatrix = getCurrentState().transformMatrix * rotationMatrix.transposed();
}

void DrawPool::rotate(const float x, const float y, const float angle)
{
    translate(-x, -y);
    rotate(angle);
    translate(x, y);
}

void DrawPool::pushTransformMatrix()
{
    m_transformMatrixStack.emplace_back(getCurrentState().transformMatrix);
    assert(m_transformMatrixStack.size() < 100);
}

void DrawPool::popTransformMatrix()
{
    assert(!m_transformMatrixStack.empty());
    getCurrentState().transformMatrix = m_transformMatrixStack.back();
    m_transformMatrixStack.pop_back();
}

Rect DrawPool::scaleToDevice(const Rect& rect, const float scale)
{
    if (scale == 1.f || !rect.isValid())
        return rect;

    return { static_cast<int>(rect.left() * scale), static_cast<int>(rect.top() * scale),
             static_cast<int>(rect.width() * scale), static_cast<int>(rect.height() * scale) };
}

void DrawPool::PoolState::execute(DrawPool* pool) const {
    g_painter->setColor(color);
    g_painter->setOpacity(opacity);
    g_painter->setCompositionMode(compositionMode);
    g_painter->setBlendEquation(blendEquation);
    // A clip rect is recorded in the pool's LOGICAL coordinate space, but glScissor is in device
    // pixels - the one piece of painter state the projection cannot carry, since it is applied
    // outside it. Everything else here (geometry, transforms) rides the logical projection.
    g_painter->setClipRect(scaleToDevice(clipRect, pool ? pool->getContentScale() : 1.f));
    g_painter->setShaderProgram(shaderProgram);
    g_painter->setTransformMatrix(transformMatrix);
    if (action) action();
    if (texture) {
        texture->create();
        g_painter->setTexture(texture);
        if (texture->canCacheInAtlas() && pool->m_atlas && !texture->getAtlasRegion(pool->m_atlas->getType())) {
            pool->m_atlas->addTexture(texture);
        }
    } else
        g_painter->setTexture(textureId, textureMatrixId);
}

void DrawPool::setFramebuffer(const Size& size, const float contentScale) {
    if (!m_framebuffer) {
        m_framebuffer = std::make_shared<FrameBuffer>();
        m_framebuffer->m_isScene = true;
    }

    if (size.isValid() && m_framebuffer->resize(size, contentScale)) {
        m_framebuffer->prepare({}, {});
        repaint();
    }
}

void DrawPool::removeFramebuffer() {
    m_hashCtrl.reset();
    m_framebuffer = nullptr;
}

// A polyline, recorded as BOTH the GL line call and its triangulated equivalent. GL keeps
// drawing GL_LINE_STRIP; a compiler takes the triangles. Triangulating here rather than in
// the compiler costs a few hundred floats in the frames where a graph is actually visible,
// and keeps the declared form testable on its own.
void DrawPool::addLineStrip(const std::vector<Point>& points, const uint16_t width, const Color& color,
                            const std::function<void()>& glAction)
{
    auto coords = getCoordsBuffer();
    RenderLines::triangulateStrip(*coords, points, static_cast<float>(width));

    PoolState state = getCurrentState();
    state.color = color;
    state.texture = nullptr;
    state.textureId = 0;
    state.textureMatrixId = 0;
    state.textureHandle = {};

    addDeclaredAction(glAction, ActionIdiom::LineStrip, std::move(state), std::move(coords));
}

void DrawPool::addTextureUpload(const TextureHandle texture, const Size& size,
                                const uint8_t* pixels, const size_t byteCount)
{
    if (!texture.isValid() || !pixels || byteCount == 0)
        return;

    auto& update = m_pendingUploads.emplace_back();
    update.texture = texture;
    update.size = size;
    update.pixels.assign(pixels, pixels + byteCount);
}

void DrawPool::addLightOverlay(const TexturePtr& texture, const Rect& dest, const Rect& src,
                               const uint16_t tileSize, const std::function<void()>& glAction)
{
    auto coords = getCoordsBuffer();
    const auto& offset = src.topLeft();
    const auto& size = src.size();
    coords->addRect(
        RectF(dest.left(), dest.top(), dest.width(), dest.height()),
        RectF(static_cast<float>(offset.x) / tileSize, static_cast<float>(offset.y) / tileSize,
              static_cast<float>(size.width()) / tileSize, static_cast<float>(size.height()) / tileSize));

    PoolState state;
    state.compositionMode = CompositionMode::MULTIPLY;
    state.transformMatrix = DEFAULT_MATRIX3;
    state.color = Color::white;
    state.texture = texture;
    state.textureHandle = texture ? TextureHandle{ texture->getUniqueId() } : TextureHandle{};

    addDeclaredAction(glAction, ActionIdiom::LightOverlay, std::move(state), std::move(coords));
}

void DrawPool::setCompositionMaterial(const MaterialHandle material, const MaterialParams& params,
                                      const float opacity, const std::array<TextureHandle, 3>& extraTex)
{
    m_pendingCompositionMaterial = material;
    m_pendingCompositionParams = params;
    m_pendingCompositionOpacity = opacity;
    m_pendingCompositionExtraTex = extraTex;
}

void DrawPool::addAction(const std::function<void()>& action, size_t hash)
{
    addAction(action, ActionIdiom::Opaque, hash);
}

// Records an action TOGETHER WITH the geometry and state that action would have produced.
// The GL path runs the callback and ignores both; a frame compiler emits the declared form
// and never runs the callback. This is how an idiom stops being opaque without the GL path
// changing behaviour at all.
void DrawPool::addDeclaredAction(const std::function<void()>& action, const ActionIdiom idiom,
                                 PoolState&& state, std::shared_ptr<CoordsBuffer>&& coords, size_t hash)
{
    const uint8_t order = m_type == DrawPoolType::MAP ? THIRD : FIRST;
    auto& obj = m_objects[order].emplace_back(action);
    obj.idiom = idiom;
    obj.state = std::move(state);
    obj.coords = std::move(coords);

    if (hasFrameBuffer() && hash > 0 && !m_hashCtrl.isLast(hash)) {
        m_hashCtrl.put(hash);
    }
}

void DrawPool::addAction(const std::function<void()>& action, const ActionIdiom idiom, size_t hash)
{
    const uint8_t order = m_type == DrawPoolType::MAP ? THIRD : FIRST;
    m_objects[order].emplace_back(action).idiom = idiom;
    if (hasFrameBuffer() && hash > 0 && !m_hashCtrl.isLast(hash)) {
        m_hashCtrl.put(hash);
    }
}

void DrawPool::bindFrameBuffer(const Size& size, const Color& color)
{
    if (color != Color::white)
        getCurrentState().color = color;

    // Refuse rather than overflow the state array. Nesting this deep does not happen - the
    // surveyed sites go one or two deep - but the array is fixed and the index is not checked
    // anywhere else.
    if (!nextStateAndReset()) {
        ++m_refusedBinds;
        return;
    }

    ++m_bindedFramebuffers;
    ++m_lastFramebufferId;

    addAction([this, size, frameIndex = m_bindedFramebuffers] {
        static const PoolState state;

        state.execute(this);

        const auto& frame = getTemporaryFrameBuffer(frameIndex);
        frame->resize(size);
        frame->bind();
    });

    // Marker for the Vulkan feeder (see DrawObject in drawpool.h). addAction pushes the action
    // onto the end of the same bucket we are using here.
    auto& bindObject = m_objects[m_type == DrawPoolType::MAP ? THIRD : FIRST].back();
    bindObject.fbMarker = 1;
    bindObject.fbSize = size;
}
void DrawPool::releaseFrameBuffer(const Rect& dest)
{
    releaseFrameBuffer(dest, 0);
}

void DrawPool::releaseFrameBuffer(const Rect& dest, uint8_t flipDirection)
{
    // An unbalanced release has nothing to pop and nothing to blit. Returning here rather than
    // underflowing the state stack turns an out-of-bounds read into a no-op - but a no-op is
    // not the same as correct, so say so once. It is a caller bug either way.
    // Pair with a bind that was refused, before touching the state stack at all.
    if (m_refusedBinds > 0) {
        --m_refusedBinds;
        return;
    }

    if (!backState()) {
        if (!m_loggedUnbalancedRelease) {
            m_loggedUnbalancedRelease = true;
            g_logger.warning("[render] pool {} released a framebuffer that was never bound",
                             static_cast<int>(m_type));
        }
        return;
    }

    addAction([this, dest, flipDirection, frameIndex = m_bindedFramebuffers, drawState = getCurrentState()] {
        const auto& frame = getTemporaryFrameBuffer(frameIndex);
        frame->release();
        drawState.execute(this);
        frame->draw(dest, flipDirection);
    });

    // Marker for the Vulkan feeder (see DrawObject in drawpool.h).
    auto& releaseObject = m_objects[m_type == DrawPoolType::MAP ? THIRD : FIRST].back();
    releaseObject.fbMarker = 2;
    releaseObject.fbFlip = flipDirection;
    releaseObject.fbDest = dest;
    releaseObject.fbOpacity = getCurrentState().opacity;

    // The whole outer state, not just its opacity. GL applies exactly this before the blit -
    // it is the `drawState` the callback above captured - and the `useFramebuffer` shader
    // route depends on it: the shader is bound OUTSIDE the temporary target so that it runs on
    // the composited result. A consumer that reads only fbOpacity loses the material, the
    // colour and the transform, which is how Outline outfits came out unshaded.
    //
    // Invisible to the Vulkan feeder, which continues past an fbMarker object before it ever
    // looks at state.
    releaseObject.state = getCurrentState();

    if (hasFrameBuffer() && !dest.isNull()) m_hashCtrl.put(dest.hash());
    --m_bindedFramebuffers;
}

const FrameBufferPtr& DrawPool::getTemporaryFrameBuffer(const uint8_t index) {
    if (index < m_temporaryFramebuffers.size()) {
        return m_temporaryFramebuffers[index];
    }

    const auto& tempfb = m_temporaryFramebuffers.emplace_back(std::make_shared<FrameBuffer>());
    tempfb->setSmooth(false);
    return tempfb;
}

std::shared_ptr<CoordsBuffer> DrawPool::getCoordsBuffer() {
    CoordsBuffer* coordsBuffer = nullptr;

    if (!m_coordsCache.empty()) {
        coordsBuffer = m_coordsCache.back();
        m_coordsCache.pop_back();
    } else
        coordsBuffer = new CoordsBuffer();

    return std::shared_ptr<CoordsBuffer>(coordsBuffer, [this](CoordsBuffer* ptr) {
        if (m_enabled) {
            ptr->clear();
            m_coordsCache.emplace_back(ptr);
        } else {
            delete ptr;
        }
    });
}
