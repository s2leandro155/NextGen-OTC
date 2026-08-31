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

#include "drawpoolmanager.h"
#include <framework/util/profiler.h>

#include "graphics.h"
#include "painter.h"
#include "paintershaderprogram.h"
#include "textureatlas.h"
#include "render/glbackend.h"
#ifdef CRYSTALOTC_COCOA_WINDOW
#include "render/metal/metalbackend.h"
#endif
#include "render/renderhandles.h"
#include "render/resourceregistry.h"
#include <framework/core/graphicalapplication.h>
#include <framework/core/configmanager.h>
#include <framework/platform/platformwindow.h>

#include <cstdlib>

thread_local static uint8_t CURRENT_POOL = static_cast<uint8_t>(DrawPoolType::LAST);

void resetSelectedPool() {
    CURRENT_POOL = static_cast<uint8_t>(DrawPoolType::LAST);
}

DrawPoolManager g_drawPool;

namespace
{
    // Precedence, most specific first: a command-line flag, an environment variable, then
    // config.ini. The first two exist because the renderer-baseline harness has to capture the
    // same scene down both paths in one run of the same binary, and config.ini is a
    // restart-scoped, user-owned file that a capture must not rewrite.
    std::string requestedRenderPath()
    {
        static constexpr std::string_view FLAG = "--render-path=";

        const auto& options = g_app.getStartupOptions();
        if (const auto pos = options.find(FLAG); pos != std::string::npos) {
            const auto value = options.substr(pos + FLAG.size());
            return value.substr(0, value.find_first_of(" \t"));
        }

        if (const char* env = std::getenv("CRYSTALOTC_RENDER_PATH"); env && *env)
            return env;

        return g_configs.getPublicConfig().graphics.renderPath;
    }

    // Same precedence, for the graphics API underneath the frame path. `auto` is the default and
    // resolves by capability rather than by name: a window that never created a GL context has a
    // Metal layer to offer and nothing else, and a window that did has the opposite.
    std::string requestedRenderBackend()
    {
        static constexpr std::string_view FLAG = "--render-backend=";

        const auto& options = g_app.getStartupOptions();
        if (const auto pos = options.find(FLAG); pos != std::string::npos) {
            const auto value = options.substr(pos + FLAG.size());
            return value.substr(0, value.find_first_of(" \t"));
        }

        if (const char* env = std::getenv("CRYSTALOTC_RENDER_BACKEND"); env && *env)
            return env;

        const auto& configured = g_configs.getPublicConfig().graphics.renderBackend;

        // "gl" is the config DEFAULT and also the Vulkan feeder's "not vulkan" value, so it is not
        // evidence that anyone asked for OpenGL - it has to keep meaning "auto", or every machine
        // that has never opened the options screen would be requesting a backend it may not have.
        // "opengl" is the value the graphics-engine option writes when a user picks OpenGL
        // deliberately, and "auto" when they pick auto-select, so both are honoured as stated.
        if (configured == "metal" || configured == "opengl" || configured == "auto")
            return configured;

        return std::string{ "auto" };
    }

    std::unique_ptr<IRenderBackend> createBackend(const std::string& requestedName)
    {
        // A named backend this build cannot provide is downgraded to "auto" rather than attempted.
        // Without this, `--render-backend=gl` on a Cocoa window produced a client that drew
        // NOTHING: GLBackend::initialize() fails with no GL context, createBackend returned null,
        // the frame path was refused, and the legacy path it fell back to is the OpenGL renderer.
        // Auto always resolves to something that exists.
        std::string requested = requestedName;
        const auto available = DrawPoolManager::availableRenderBackends();
        if (requested != "auto"
            && std::find(available.begin(), available.end(), requested) == available.end()) {
            g_logger.warning("[render] backend '{}' is not available in this build; using auto",
                             requested);
            requested = "auto";
        }

        // "opengl" is a deliberate choice and is taken literally; "auto" resolves by capability,
        // because a window that never created a GL context has a Metal layer to offer and nothing
        // else, and a window that did has the opposite.
        const bool wantsMetal = requested == "metal"
            || (requested == "auto" && !g_window.hasGLContext());

#ifdef CRYSTALOTC_COCOA_WINDOW
        if (wantsMetal) {
            auto backend = std::make_unique<MetalBackend>();
            if (backend->initialize())
                return backend;

            g_logger.warning("[render] the Metal backend refused to initialise");
        }
#else
        if (wantsMetal)
            g_logger.warning("[render] this build has no Metal backend");
#endif

        auto backend = std::make_unique<GLBackend>();
        if (backend->initialize())
            return backend;

        return nullptr;
    }
}

std::vector<std::string> DrawPoolManager::availableRenderBackends()
{
    std::vector<std::string> backends{ "auto" };

#ifdef CRYSTALOTC_COCOA_WINDOW
    // The Cocoa window creates no OpenGL context, so OpenGL is not merely unselected there - it
    // cannot be provided at all, and offering it would hand the user a black client.
    backends.emplace_back("metal");
#else
    backends.emplace_back("opengl");
#ifdef WIN32
    // Vulkan is not an IRenderBackend: VkDrawFeeder intercepts the published draw lists instead.
    // It is still a graphics engine the user can select, and it is Windows-only.
    backends.emplace_back("vulkan");
#endif
#endif

    return backends;
}

void DrawPoolManager::init(const uint16_t spriteSize)
{
    if (spriteSize != 0)
        m_spriteSize = spriteSize;

    auto path = requestedRenderPath();

    if (!path.empty() && path != "frame" && path != "legacy") {
        g_logger.warning("[render] unknown render path '{}' - using 'legacy'", path);
        path = "legacy";
    }

    if (path != "frame" && !g_window.hasGLContext()) {
        // The legacy path IS the OpenGL renderer - it replays object lists onto Painter. A window
        // that deliberately creates no GL context has no such renderer to fall back to, so
        // "legacy" would mean "draw nothing" there. On that window the frame path is not a
        // preference, it is the only renderer there is.
        path = "frame";
    }

    if (path == "frame") {
        // Compiling has to be on before the first release(), or the first frames would find no
        // program and draw nothing.
        DrawPool::setCompileFrames(true);

        m_backend = createBackend(requestedRenderBackend());
        if (m_backend) {
            m_renderPath = RenderPath::Frame;
            g_logger.info("[render] render path: frame (backend '{}')", m_backend->name());
        } else {
            DrawPool::setCompileFrames(false);
            g_logger.warning("[render] frame render path requested but no backend would "
                             "initialise; staying on the legacy path");
        }
    }

    auto mapAtlasSize = g_configs.getPublicConfig().graphics.mapAtlasSize;
    auto foregroundAtlasSize = g_configs.getPublicConfig().graphics.foregroundAtlasSize;

    if (mapAtlasSize == 0)
        mapAtlasSize = g_graphics.getMaxTextureSize();

    if (foregroundAtlasSize == 0)
        foregroundAtlasSize = g_graphics.getMaxTextureSize();

    // The CPU-side texture atlases must stay OFF under the Vulkan backend. The VK feeder
    // snapshots a texture's pixels ONCE (then frees them), while these atlases keep
    // repacking NEW textures into the same growing image - everything packed after the
    // snapshot renders as stale pixels of the old snapshot (e.g. cyclopedia satellite
    // tiles bleeding into UI panels after fast tab switching). The feeder keeps its own
    // array atlas on the GPU, so CPU-side double-atlasing buys nothing in Vulkan mode.
    //
    // Metal used to join that rule, for two reasons that Phase 5 removed rather than worked
    // around: the atlas keyed its regions on a texture's OpenGL name, zero for everything a
    // non-GL backend creates, and `TextureAtlas::flush` was unguarded OpenGL from top to bottom.
    // Regions are keyed on the unique id now, and maintenance compiles to ordinary passes
    // (`TextureAtlas::compileMaintenance`), so an atlas is backend-neutral and Metal keeps it.
    if (g_configs.getPublicConfig().graphics.renderBackend == "vulkan") {
        mapAtlasSize = -1;
        foregroundAtlasSize = -1;
    }

    auto atlasMap = mapAtlasSize > 0 ? std::make_shared<TextureAtlas>(Fw::TextureAtlasType::MAP, mapAtlasSize) : nullptr;
    auto atlasForeground = foregroundAtlasSize > 0 ? std::make_shared<TextureAtlas>(Fw::TextureAtlasType::FOREGROUND, foregroundAtlasSize, true) : nullptr;

    m_atlases[Fw::TextureAtlasType::MAP] = atlasMap.get();
    m_atlases[Fw::TextureAtlasType::FOREGROUND] = atlasForeground.get();

    // Stated in the log because it is otherwise invisible and it changes what every later
    // measurement means: an atlas-backed draw and a standalone one produce the same picture but
    // are not the same frame. It was also a per-backend policy until Phase 5, so a regression
    // that quietly switched the atlases off again would look exactly like nothing happening.
    const auto describeAtlas = [](const TextureAtlasPtr& atlas) {
        if (!atlas)
            return std::string{ "disabled" };
        return std::to_string(atlas->getSize().width()) + "x" + std::to_string(atlas->getSize().height());
    };
    g_logger.info("[render] CPU atlases: map={} foreground={}",
                  describeAtlas(atlasMap), describeAtlas(atlasForeground));

    // Create Pools
    for (int8_t i = -1; ++i < static_cast<uint8_t>(DrawPoolType::LAST);) {
        auto pool = m_pools[i] = DrawPool::create(static_cast<DrawPoolType>(i));

        switch (static_cast<DrawPoolType>(i)) {
            case DrawPoolType::MAP:
                pool->m_atlas = atlasMap;
                break;

            case DrawPoolType::FOREGROUND:
            case DrawPoolType::FOREGROUND_MAP:
            case DrawPoolType::CREATURE_INFORMATION:
                pool->m_atlas = atlasForeground;
                break;

            default: break;
        }
    }
}

void DrawPoolManager::terminate()
{
    // The backend first, and explicitly rather than by letting the unique_ptr run at static
    // destruction time. A backend that owns GPU objects has to drain its in-flight frames before
    // releasing what they are reading, and it has to do that while the window it borrowed its
    // surface from still exists - neither of which static destruction order promises.
    if (m_backend) {
        m_backend->shutdown();
        m_backend.reset();
    }
    m_renderPath = RenderPath::Legacy;

    // Destroy Pools
    for (int_fast8_t i = -1; ++i < static_cast<uint8_t>(DrawPoolType::LAST);) {
        delete m_pools[i];
    }
}

DrawPoolType DrawPoolManager::getCurrentType() const { return static_cast<DrawPoolType>(CURRENT_POOL); }
bool DrawPoolManager::isValid() const { return CURRENT_POOL < static_cast<uint8_t>(DrawPoolType::LAST); }
DrawPool* DrawPoolManager::getCurrentPool() const { return m_pools[CURRENT_POOL]; }
void DrawPoolManager::select(DrawPoolType type) { CURRENT_POOL = static_cast<uint8_t>(type); }
bool DrawPoolManager::isPreDrawing() const { return CURRENT_POOL != static_cast<uint8_t>(DrawPoolType::LAST); }
bool DrawPoolManager::shaderNeedFramebuffer() const { return getCurrentPool()->getCurrentState().shaderProgram && getCurrentPool()->getCurrentState().shaderProgram->useFramebuffer(); }

void DrawPoolManager::draw()
{
    PROFILE_ZONE(FrameDraw);

    // One entry point, dispatching internally, so that the render loop above knows nothing
    // about which renderer is running and a declined frame falls back within the same tick
    // rather than being lost.
    if (m_renderPath == RenderPath::Frame && drawFrame())
        return;

    // The fallback is the OpenGL renderer, so it is only a fallback where OpenGL exists. On a
    // window with no GL context a declined frame has to consume the pools instead, or the map
    // thread blocks in canDrawMap forever waiting for flags nobody took - the same obligation
    // every non-drawing frame owes, stated in one more place.
    if (!g_window.hasGLContext()) {
        consumeAll();
        return;
    }

    drawLegacy();
}

void DrawPoolManager::drawLegacy()
{
    if (m_size != g_graphics.getViewportSize()) {
        m_size = g_graphics.getViewportSize();
        m_transformMatrix = g_painter->getTransformMatrix(m_size);
        g_painter->setResolution(m_size, m_transformMatrix);
    }

    for (int8_t i = -1; ++i < static_cast<uint8_t>(DrawPoolType::LAST);) {
        drawPool(static_cast<DrawPoolType>(i));
    }
}

bool DrawPoolManager::drawFrame()
{
    if (!m_backend)
        return false;

    if (m_size != g_graphics.getViewportSize()) {
        m_size = g_graphics.getViewportSize();
        m_transformMatrix = g_painter->getTransformMatrix(m_size);
        g_painter->setResolution(m_size, m_transformMatrix);

        // A resize invalidates every retained target's contents without changing the objects
        // that drew into them, which is exactly the case a content hash cannot see.
        m_frameAssembler.invalidateRetainedTargets();
        m_backend->resize(m_size);
    }

    // Completeness is checked BEFORE anything is consumed. A program that could not express
    // some idiom must not drive the backend, and the fallback needs the repaint flags intact -
    // consuming first and then bailing would drop a frame's worth of published work.
    for (int8_t i = -1; ++i < static_cast<int8_t>(DrawPoolType::LAST);) {
        auto* pool = get(static_cast<DrawPoolType>(i));
        if (!pool->isEnabled() || pool->hasUsableProgram())
            continue;

        if (!m_loggedFrameFallback) {
            m_loggedFrameFallback = true;
            g_logger.warning("[render] pool {} compiled incompletely; this frame and any like it "
                             "fall back to the legacy path", i);
        }
        return false;
    }

    FrameAssembler::Programs programs{};
    for (int8_t i = -1; ++i < static_cast<int8_t>(DrawPoolType::LAST);) {
        auto* pool = get(static_cast<DrawPoolType>(i));
        // A disabled pool is skipped without consuming, matching drawPool's early return.
        if (pool->isEnabled())
            programs[i] = pool->acquireProgram();
    }

    // Re-checked after acquiring, not only before it. A producer can publish between the peek
    // and the acquire, and falling back here is safe even though the flags are now consumed:
    // the legacy path treats an already-consumed pool exactly as it treats one that did not
    // repaint, which is a situation it is built for.
    if (!FrameAssembler::isComplete(programs)) {
        if (!m_loggedFrameFallback) {
            m_loggedFrameFallback = true;
            g_logger.warning("[render] a pool published an incomplete program mid-frame; "
                             "falling back to the legacy path");
        }
        return false;
    }

    prepareResources(programs);

    {
        PROFILE_ZONE(FrameAssemble);
        m_frameAssembler.assemble(programs, m_atlasPrograms, m_size, PainterShaderProgram::currentTime(), m_frame);
        bindFrameTargets(m_frame);
    }

    {
        PROFILE_ZONE(BackendRender);
        if (!m_backend->render(m_frame))
            return false;
    }

    // Only once the frame is actually submitted. compileAtlasMaintenance() left the pending
    // composites in place precisely so that a declined frame falls back to the legacy path with
    // the work still to do, rather than to a drained atlas whose regions are marked composited
    // and whose sprites would render as whatever was in that shelf space before.
    commitAtlasMaintenance();

    return true;
}

void DrawPoolManager::prepareResources(const FrameAssembler::Programs& programs)
{
    // Residency and atlas maintenance for every pool, before any pass runs.
    //
    // The GL path interleaves both with drawing - PoolState::execute creates a texture and
    // offers it to the atlas as each object is drawn, and the atlas is flushed after each
    // pool's objects. Hoisting all of it in front of the frame is equivalent, and the reason is
    // worth stating: a region created during frame N is not consulted until the PRODUCER runs
    // for frame N+1, because it is DrawPool::add that translates a source rect into atlas
    // coordinates. So nothing this frame draws can see a region this frame created, whichever
    // order the two happen in - and the compositing writes land in shelf space no draw in this
    // frame addresses.
    for (int8_t i = -1; ++i < static_cast<int8_t>(DrawPoolType::LAST);) {
        auto* pool = get(static_cast<DrawPoolType>(i));

        if (const auto* program = programs[i]) {
            for (const auto& texture : program->residency) {
                if (!texture)
                    continue;

                texture->create();

                if (texture->canCacheInAtlas() && pool->m_atlas
                    && !texture->getAtlasRegion(pool->m_atlas->getType()))
                    pool->m_atlas->addTexture(texture);
            }
        }
    }

    compileAtlasMaintenance();
}

void DrawPoolManager::compileAtlasMaintenance()
{
    // Driven per ATLAS rather than per pool, because the pools share them: all three foreground
    // pools point at one atlas, so a per-pool loop would drain the pending list on the first and
    // compile two empty programs after it.
    //
    // This is the last piece of frame work that used to be undescribable. `TextureAtlas::flush`
    // performs it through g_painter with a raw glDisable(GL_BLEND) bracket; `compileMaintenance`
    // states the same three draws per pending texture as ordinary blend-off packets on a
    // Keep-loaded pass over the layer's target.
    m_atlasPrograms = {};

    for (size_t i = 0; i < m_atlases.size(); ++i) {
        if (auto* atlas = m_atlases[i])
            m_atlasPrograms[i] = atlas->compileMaintenance();
    }
}

void DrawPoolManager::commitAtlasMaintenance()
{
    for (size_t i = 0; i < m_atlases.size(); ++i) {
        if (m_atlasPrograms[i] && m_atlases[i])
            m_atlases[i]->commitMaintenance();
    }

    m_atlasPrograms = {};
}

void DrawPoolManager::bindFrameTargets(const RenderFrame& frame)
{
    auto& registry = ResourceRegistry::instance();
    registry.clearTargets();

    // Every pool target, whether or not a pass writes to it this frame: a pool whose content
    // was unchanged contributes no pass but its composition packet still samples the target.
    for (int8_t i = -1; ++i < static_cast<int8_t>(DrawPoolType::LAST);) {
        const auto type = static_cast<DrawPoolType>(i);
        registry.bindTarget(RenderHandles::poolTarget(type), get(type)->getFrameBuffer().get());
    }

    // Every atlas layer that exists, whether or not this frame maintains one. A layer is
    // registered even when no pass writes to it because ordinary draws SAMPLE it: an atlas-backed
    // packet names its layer by target handle, so the handle has to resolve on any frame that
    // draws a packed sprite - which is nearly all of them, and mostly not the frames that pack.
    for (auto* atlas : m_atlases) {
        if (!atlas)
            continue;

        atlas->forEachLayer([&registry](const RenderTargetHandle handle, FrameBuffer* framebuffer) {
            if (framebuffer)
                registry.bindTarget(handle, framebuffer);
        });
    }

    // Transient targets exist only where a pass names one. They are registered here but SIZED
    // in the backend, at the moment each pass runs: one handle is a temporary slot at a nesting
    // depth, and several passes can reuse that slot at different sizes within one frame.
    for (const auto& pass : frame.passes) {
        if (!RenderHandles::isTransientTarget(pass.target))
            continue;

        auto* pool = get(RenderHandles::poolOf(pass.target));
        const auto depth = static_cast<uint8_t>(RenderHandles::transientDepthOf(pass.target));
        if (const auto& target = pool->getTemporaryFrameBuffer(depth))
            registry.bindTarget(pass.target, target.get());
    }
}

void DrawPoolManager::drawObject(DrawPool* pool, const DrawPool::DrawObject& obj)
{
    if (obj.action) {
        obj.action();
    } else if (obj.coords) {
        obj.state.execute(pool);
        g_painter->drawCoords(*obj.coords, DrawMode::TRIANGLES);
    }
}

void DrawPoolManager::addTexturedCoordsBuffer(const TexturePtr& texture, const CoordsBufferPtr& coords, const Color& color) const
{
    getCurrentPool()->add(color, texture, DrawPool::DrawMethod{}, coords);
}

void DrawPoolManager::addTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color) const
{
    if (dest.isEmpty() || src.isEmpty()) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, texture, DrawPool::DrawMethod{
        .type = DrawPool::DrawMethodType::RECT,
        .dest = dest, .src = src
    });
}

void DrawPoolManager::addUpsideDownTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color) const
{
    if (dest.isEmpty() || src.isEmpty()) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, texture, DrawPool::DrawMethod{ .type = DrawPool::DrawMethodType::UPSIDEDOWN_RECT, .dest =
                              dest,
                              .src = src
                          });
}

void DrawPoolManager::addTexturedRepeatedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color) const
{
    if (dest.isEmpty() || src.isEmpty()) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, texture, DrawPool::DrawMethod{ .type = DrawPool::DrawMethodType::REPEATED_RECT, .dest =
                              dest,
                              .src = src
                          });
}

void DrawPoolManager::addFilledRect(const Rect& dest, const Color& color) const
{
    if (dest.isEmpty()) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, nullptr, DrawPool::DrawMethod{ .type = DrawPool::DrawMethodType::RECT, .dest = dest });
}

void DrawPoolManager::addFilledTriangle(const Point& a, const Point& b, const Point& c, const Color& color) const
{
    if (a == b || a == c || b == c) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, nullptr, DrawPool::DrawMethod{
            .type = DrawPool::DrawMethodType::TRIANGLE,
            .a = a,
            .b = b,
            .c = c
     });
}

void DrawPoolManager::addBoundingRect(const Rect& dest, const Color& color, const uint16_t innerLineWidth) const
{
    if (dest.isEmpty() || innerLineWidth == 0) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, nullptr, DrawPool::DrawMethod{
        .type = DrawPool::DrawMethodType::BOUNDING_RECT,
        .dest = dest,
        .intValue = innerLineWidth
    });
}

void DrawPoolManager::preDraw(const DrawPoolType type, const std::function<void()>& f, const std::function<void()>& beforeRelease, const Rect& dest, const Rect& src, const Color& colorClear)
{
    select(type);
    const auto pool = getCurrentPool();

    // dest/src go to the pool as declared data (see comment in drawpool.h), because a consumer
    // that does not run GL actions cannot recover them. Two Rect copies per frame.
    pool->m_pendingFbDest = dest;
    pool->m_pendingFbSrc = src;
    pool->m_pendingFbClearColor = colorClear;

    pool->resetState();

    if (f) f();

    if (beforeRelease)
        beforeRelease();

    if (pool->hasFrameBuffer()) {
        addAction([pool, dest, src, colorClear] {
            pool->m_framebuffer->prepare(dest, src, colorClear);
        }, ActionIdiom::PoolTargetPrepare);
    }

    pool->release();

    resetSelectedPool();
}

void DrawPoolManager::consumeAll()
{
    for (int8_t i = -1; ++i < static_cast<int8_t>(DrawPoolType::LAST);) {
        auto* pool = get(static_cast<DrawPoolType>(i));
        if (!pool)
            continue;

        SpinLock::Guard guard(pool->m_threadLock);
        if (pool->m_shouldRepaint.load(std::memory_order_relaxed)) {
            pool->m_objectsDraw[0].swap(pool->m_objectsDraw[1]);
            pool->m_shouldRepaint.store(false, std::memory_order_relaxed);
        }
    }
}

void DrawPoolManager::drawObjects(DrawPool* pool) {
    const auto hasFramebuffer = pool->hasFrameBuffer();

    const auto shouldRepaint = pool->shouldRepaint();
    if (!shouldRepaint && hasFramebuffer)
        return;

    if (hasFramebuffer)
        pool->m_framebuffer->bind();

    if (shouldRepaint) {
        SpinLock::Guard guard(pool->m_threadLock);
        pool->m_objectsDraw[0].swap(pool->m_objectsDraw[1]);
        pool->m_shouldRepaint.store(false, std::memory_order_relaxed);
    }

    for (auto& obj : pool->m_objectsDraw[1]) {
        drawObject(pool, obj);
    }

    if (hasFramebuffer) {
        pool->m_framebuffer->release();
    }

    if (pool->m_atlas)
        pool->m_atlas->flush();
}

void DrawPoolManager::drawPool(const DrawPoolType type) {
    const auto pool = get(type);

    if (!pool->isEnabled())
        return;

    drawObjects(pool);

    if (pool->hasFrameBuffer()) {
        g_painter->resetState();

        if (pool->m_beforeDraw) pool->m_beforeDraw();
        pool->m_framebuffer->draw();
        if (pool->m_afterDraw) pool->m_afterDraw();
    }
}

void DrawPoolManager::removeTextureFromAtlas(uint32_t id, bool smooth) {
    for (auto pool : m_pools) {
        if (pool->m_atlas)
            pool->m_atlas->removeTexture(id, smooth);
    }
}

std::string DrawPoolManager::getAtlasStats() const
{
    std::stringstream ss;
    const auto* mapAtlas = get(DrawPoolType::MAP)->getAtlas();
    const auto* fgAtlas = get(DrawPoolType::FOREGROUND)->getAtlas();

    ss << "map=" << (mapAtlas ? mapAtlas->getStats() : "disabled");
    ss << " | fg=" << (fgAtlas ? fgAtlas->getStats() : "disabled");
    return ss.str();
}
