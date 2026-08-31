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

#include "glbackend.h"

#include "renderhandles.h"
#include "resourceregistry.h"

#include <framework/graphics/framebuffer.h>
#include <framework/graphics/graphics.h>
#include <framework/graphics/glutil.h>
#include <framework/graphics/painter.h>
#include <framework/graphics/paintershaderprogram.h>
#include <framework/graphics/shadermanager.h>
#include <framework/graphics/texture.h>
#include <framework/platform/platformwindow.h>

namespace
{
    // The renderer-facing blend vocabulary mapped back onto the producer-facing one Painter
    // speaks. The two are 1:1 and deliberately separate - `BlendMode::AddWeird` exists so that
    // nobody implements `CompositionMode::ADD` as additive blending - so this is where GL, the
    // one backend that already had the table, joins them back up.
    [[nodiscard]] constexpr CompositionMode compositionOf(const BlendMode mode)
    {
        switch (mode) {
            case BlendMode::Normal:        return CompositionMode::NORMAL;
            case BlendMode::Multiply:      return CompositionMode::MULTIPLY;
            case BlendMode::AddWeird:      return CompositionMode::ADD;
            case BlendMode::Replace:       return CompositionMode::REPLACE;
            case BlendMode::DestBlend:     return CompositionMode::DESTINATION_BLENDING;
            case BlendMode::LightModulate: return CompositionMode::LIGHT;
        }
        return CompositionMode::NORMAL;
    }

    static_assert(compositionOf(blendModeOf(CompositionMode::ADD)) == CompositionMode::ADD);
    static_assert(compositionOf(blendModeOf(CompositionMode::LIGHT)) == CompositionMode::LIGHT);
}

bool GLBackend::initialize()
{
    if (!g_window.hasGLContext())
        return false;

    glEnable(GL_BLEND);
    m_blendEnabled = true;
    return true;
}

void GLBackend::shutdown()
{
    ResourceRegistry::instance().clearTargets();
}

void GLBackend::resize(const Size& drawableSize)
{
    // The viewport belongs to a pass, not to the backend, so there is nothing to do here but
    // make sure the painter agrees about the backbuffer's size for any pass that targets it.
    g_painter->setResolution(drawableSize, g_painter->getTransformMatrix(drawableSize));
}

void GLBackend::setBlendEnabled(const bool enabled)
{
    if (m_blendEnabled == enabled)
        return;

    m_blendEnabled = enabled;
    if (enabled)
        glEnable(GL_BLEND);
    else
        glDisable(GL_BLEND);
}

void GLBackend::applyUploads(const RenderFrame& frame)
{
    for (const auto& upload : frame.uploads) {
        auto* texture = ResourceRegistry::instance().resolveTexture(upload.texture);
        if (!texture || texture->getSize() != upload.size)
            continue;

        // The cast is to satisfy a signature, not to permit a write: updatePixels takes a
        // mutable pointer only because it forwards to glTexSubImage2D, which reads through it.
        texture->updatePixels(const_cast<uint8_t*>(upload.pixels.data()));
    }
}

PainterShaderProgram* GLBackend::resolveMaterial(const MaterialHandle material) const
{
    if (material.isDefault())
        return nullptr; // Painter selects Textured or SolidColor from the geometry

    switch (static_cast<BuiltinMaterial>(material.id)) {
        case BuiltinMaterial::SolidColor:
            // Painter reaches the same program by seeing untextured geometry; saying it twice
            // would be the only way for the two paths to disagree about it.
            return nullptr;
        case BuiltinMaterial::ReplaceColor:
            return g_painter->getReplaceColorShader().get();
        default:
            break;
    }

    if (material.id < static_cast<uint16_t>(BuiltinMaterial::FirstModule))
        return nullptr;

    const auto id = static_cast<uint8_t>(material.id - static_cast<uint16_t>(BuiltinMaterial::FirstModule));
    if (const auto& program = g_shaders.getShaderById(id))
        return program.get();

    return nullptr;
}

void GLBackend::drawPacket(const RenderPass& pass, const DrawPacket& packet)
{
    if (packet.vertexCount == 0 || !pass.arena)
        return;

    uint32_t glTextureId = 0;
    uint16_t textureMatrixId = 0;

    if (packet.textured && packet.texture.isValid()) {
        if (RenderHandles::isRenderTargetTexture(packet.texture)) {
            // A packet sampling another pass's result. The target's texture carries the
            // upside-down transform matrix that makes GL's bottom-left storage read correctly,
            // which is why the handle resolves to the texture rather than to a raw id.
            auto* target = ResourceRegistry::instance().resolveTarget(RenderTargetHandle{ packet.texture.id });
            if (!target || !target->isValid())
                return;

            const auto& texture = target->getTexture();
            glTextureId = texture->getId();
            textureMatrixId = texture->getTransformMatrixId();
        } else {
            auto* texture = ResourceRegistry::instance().resolveTexture(packet.texture);
            if (!texture)
                return;

            glTextureId = texture->getId();
            textureMatrixId = texture->getTransformMatrixId();
        }
    }

    g_painter->setColor(packet.color);
    g_painter->setOpacity(packet.opacity);
    g_painter->setCompositionMode(compositionOf(packet.blend));
    g_painter->setClipRect(packet.scissorEnabled ? packet.scissor : Rect());
    g_painter->setTransformMatrix(packet.transform);
    g_painter->setAlphaWriting(packet.alphaWrite);
    setBlendEnabled(packet.blendEnabled);

    auto* program = resolveMaterial(packet.material);
    if (!program && !packet.material.isDefault() && !m_loggedMissingMaterial) {
        m_loggedMissingMaterial = true;
        g_logger.warning("[render] material {} has no GL program; drawing with the default",
                         packet.material.id);
    }
    g_painter->setShaderProgram(program);

    // The typed parameter block, mapped onto the legacy uniform slots.
    //
    // TIME AND RESOLUTION ARE DELIBERATELY NOT UPLOADED HERE. Painter writes both on every draw
    // from inside drawArrays - u_Time through updateTime(), which subtracts the program's own
    // start time and so is per-program, and u_Resolution from the painter's current resolution.
    // Uploading the frame-global values over the top would change what the GL path renders,
    // which is the one thing this backend exists not to do. The frame's copies of those two
    // fields are for backends that have no Painter underneath them.
    //
    // Everything else is uploaded in full, which it could not be before Phase 6 moved
    // ShaderManager::ITEM_ID_UNIFORM off slot 10. That slot is where PainterShaderProgram binds
    // u_TransformMatrix and writes it on every draw, so a float landing there corrupted the
    // transform for every subsequent draw - the collision MaterialParams retires structurally,
    // reintroduced by hand at the only place that still speaks the old index space.
    if (program && packet.params) {
        program->bind();
        program->setUniformValue(ShaderManager::MAP_ZOOM, packet.params->mapZoom);
        program->setUniformValue(ShaderManager::MAP_WALKOFFSET,
                                 packet.params->walkOffset.x, packet.params->walkOffset.y);
        program->setUniformValue(ShaderManager::MAP_CENTER_COORD,
                                 packet.params->mapCenterCoord.x, packet.params->mapCenterCoord.y);
        program->setUniformValue(ShaderManager::MAP_GLOBAL_COORD,
                                 packet.params->mapGlobalCoord.x, packet.params->mapGlobalCoord.y);
        // The block stores these as floats because std140 has no integer-and-float mixing that
        // survives a naturally written GLSL block; a shader declaring `uniform float u_ItemId`
        // reads them correctly, and no shipped shader declares them at all.
        program->setUniformValue(ShaderManager::ITEM_ID_UNIFORM, packet.params->itemId);
        program->setUniformValue(ShaderManager::OUTFIT_ID_UNIFORM, packet.params->outfitId);
        program->setUniformValue(ShaderManager::MOUNT_ID_UNIFORM, packet.params->mountId);
        program->setUniformValue(ShaderManager::SHADER_ID_UNIFORM, packet.params->shaderId);
        program->setUniformValue(ShaderManager::TEXT_OFFSET_UNIFORM,
                                 packet.params->textOffset.x, packet.params->textOffset.y);
        program->setUniformValue(ShaderManager::TEXT_CENTER_UNIFORM,
                                 packet.params->textCenter.x, packet.params->textCenter.y);
    }

    g_painter->setTexture(glTextureId, textureMatrixId);

    const auto offset = static_cast<size_t>(packet.vertexOffset) * 2;
    g_painter->drawArrays(pass.arena->positions() + offset,
                          pass.arena->texCoords() + offset,
                          static_cast<int>(packet.vertexCount),
                          packet.textured);
}

void GLBackend::runPass(const RenderPass& pass)
{
    FrameBuffer* target = nullptr;

    if (!pass.target.isBackbuffer()) {
        target = ResourceRegistry::instance().resolveTarget(pass.target);

        // A transient target is sized HERE, immediately before it is bound, because a handle
        // names a temporary SLOT at a nesting depth rather than one buffer: several widgets
        // can each bind depth 0 in the same frame, at different sizes, and they reuse the slot
        // sequentially. Sizing them all up front collapses them onto whichever came last - the
        // earlier blits then sample a texture smaller than their source rect and clamp, which
        // renders as the sprite's last row smeared across the rest of the quad. GL avoids this
        // for the same reason it never noticed the problem: its bind callback resizes right
        // before it binds.
        if (target && RenderHandles::isTransientTarget(pass.target) && pass.viewport.size().isValid())
            target->resize(pass.viewport.size());

        if (!target || !target->isValid()) {
            // A pass whose target the frame runner did not bind. Dropping it silently would
            // lose draws; dropping it loudly, once, keeps the rest of the frame on screen.
            if (!m_loggedMissingTarget) {
                m_loggedMissingTarget = true;
                g_logger.warning("[render] pass '{}' targets unbound handle {}; skipped",
                                 pass.label, pass.target.id);
            }
            return;
        }
        target->bindAsTarget();
    } else {
        // Resolution drives glViewport and the scissor y-flip, so it is the DEVICE size; the
        // projection spans the logical extent, which is the same thing everywhere except a
        // target rasterising above the space its geometry is recorded in.
        g_painter->setResolution(pass.viewport.size(),
                                 g_painter->getTransformMatrix(pass.projectionSize()));
    }

    if (pass.load == LoadAction::Clear) {
        // Reset first, because a clear inherits blend state, the colour mask and the scissor
        // exactly as it does in the legacy path, where FrameBuffer::bind clears immediately
        // after resetting the painter.
        g_painter->resetState();
        setBlendEnabled(true);

        if (target)
            g_painter->setAlphaWriting(target->hasAlphaWriting());

        if (pass.clearColor != Color::alpha && target)
            target->drawClearQuad(pass.clearColor);
        else
            g_painter->clear(pass.clearColor);
    }

    for (const auto& packet : pass.packets)
        drawPacket(pass, packet);

    if (target)
        target->releaseAsTarget();
}

bool GLBackend::render(const RenderFrame& frame)
{
    if (!g_window.hasGLContext())
        return false;

    // GL_BLEND is enabled once at Graphics::init and toggled by three other places (atlas
    // maintenance among them), so the frame cannot assume what it inherits.
    glEnable(GL_BLEND);
    m_blendEnabled = true;

    applyUploads(frame);

    for (const auto& pass : frame.passes)
        runPass(pass);

    // Leave the painter in the state the legacy path leaves it in at the end of a frame, so
    // that anything running between frames - atlas maintenance, a readback, a fallback to the
    // legacy path - starts from the same place either way.
    g_painter->resetState();
    setBlendEnabled(true);

    return true;
}

bool GLBackend::readPixels(const ReadbackRequest& request, ReadbackResult& out)
{
    out.ok = false;

    if (!g_window.hasGLContext())
        return false;

    FrameBuffer* target = nullptr;
    // The backbuffer's size is the viewport's, taken from Graphics rather than from the
    // painter: a readback runs between frames, and the painter's resolution is whatever the
    // last pass left it at.
    Size targetSize = g_graphics.getViewportSize();

    if (!request.source.isBackbuffer()) {
        target = ResourceRegistry::instance().resolveTarget(request.source);
        if (!target || !target->isValid())
            return false;
        targetSize = target->getSize();
    }

    Rect region = request.region.isValid() ? request.region : Rect(0, 0, targetSize);
    region = region.intersection(Rect(0, 0, targetSize));
    if (!region.isValid())
        return false;

    const int width = region.width();
    const int height = region.height();

    // The request is top-left origin; GL reads bottom-left. The conversion lives here rather
    // than at the call site, which is the whole point of expressing a readback as a request.
    const int glBottom = targetSize.height() - region.top() - height;

    std::vector<uint8_t> raw(static_cast<size_t>(width) * height * 4, 0);

    if (target)
        target->bindAsTarget();

    glReadPixels(region.left(), glBottom, width, height, GL_RGBA, GL_UNSIGNED_BYTE, raw.data());

    if (target)
        target->releaseAsTarget();

    // Deliver top-left, as the contract says. The callers used to do this themselves with
    // Image::flipVertically after every single readback.
    out.size = Size(width, height);
    out.pixels.resize(raw.size());

    const size_t stride = static_cast<size_t>(width) * 4;
    for (int y = 0; y < height; ++y) {
        const uint8_t* src = raw.data() + static_cast<size_t>(height - 1 - y) * stride;
        std::copy_n(src, stride, out.pixels.data() + static_cast<size_t>(y) * stride);
    }

    out.ok = true;
    return true;
}
