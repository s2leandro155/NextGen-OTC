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

#pragma once

#include <framework/graphics/declarations.h>
#include <framework/graphics/drawpool.h>
#include <framework/graphics/framebuffer.h>
#include <framework/graphics/render/frameassembler.h>
#include <framework/graphics/render/irenderbackend.h>

#include <memory>

class DrawPoolManager
{
public:
    // Which of the two renderers executes a frame.
    //
    //   Legacy - DrawPool objects are replayed straight onto Painter, GL callbacks and all.
    //            This is what has always shipped and it stays the behavioural reference.
    //   Frame  - each pool compiles to a PoolProgram, the programs assemble into a RenderFrame,
    //            and a backend consumes it. No callback is executed and no GL type is named
    //            above the boundary.
    //
    // Both paths are live at once during Phase 3 precisely so their pixels can be compared;
    // the frame path falls back to the legacy one, per frame, if it cannot describe the frame.
    enum class RenderPath : uint8_t
    {
        Legacy,
        Frame,
    };

    [[nodiscard]] RenderPath getRenderPath() const { return m_renderPath; }
    [[nodiscard]] IRenderBackend* getBackend() const { return m_backend.get(); }

    // What is ACTUALLY running, as opposed to what was asked for. Both are resolved rather than
    // configured - a requested path falls back when no backend will initialise, and a window with
    // no GL context has no legacy path to fall back to - so anything reporting on a run has to
    // read them here rather than re-reading the flags. The renderer-baseline benchmark does
    // exactly that, and reported `path=legacy` for a Metal frame until it did.
    [[nodiscard]] std::string getRenderPathName() const
    { return m_renderPath == RenderPath::Frame ? "frame" : "legacy"; }
    [[nodiscard]] std::string getRenderBackendName() const
    { return m_backend ? m_backend->name() : "none"; }

    // Which graphics APIs THIS BINARY can actually provide, most-preferred first, always
    // beginning with "auto".
    //
    // Compile-time rather than runtime, deliberately. `hasGLContext()` answers what the window
    // currently HAS, which is not the same question: a Windows client configured for Vulkan has
    // no GL context but can still be switched back to OpenGL, and would drop that option from
    // its own settings screen if this asked the window. What determines availability is which
    // sources were compiled in.
    //
    // The options UI builds its graphics-engine list from this, so a backend absent here is one
    // the user is never offered - which is the point. Before Phase 6 that list was a fixed
    // literal offering "DirectX 12" and "Vulkan (experimental)" on macOS, where the first has
    // never existed anywhere in this codebase and the second is Windows-only.
    [[nodiscard]] static std::vector<std::string> availableRenderBackends();

    // The same list, as an instance method, because the Lua singleton binding takes a
    // pointer-to-member and cannot bind a static one.
    [[nodiscard]] std::vector<std::string> getAvailableRenderBackends() const
    { return availableRenderBackends(); }
    DrawPool* get(const DrawPoolType type) const { return m_pools[static_cast<uint8_t>(type)]; }

    void select(DrawPoolType type);
    void preDraw(const DrawPoolType type, const std::function<void()>& f) { preDraw(type, f, nullptr, {}, {}, Color::alpha); }
    void preDraw(const DrawPoolType type, const std::function<void()>& f, const Rect& dest, const Rect& src, const Color& colorClear = Color::alpha) { preDraw(type, f, nullptr, dest, src, colorClear); }
    void preDraw(DrawPoolType type, const std::function<void()>& f, const std::function<void()>& beforeRelease, const Rect& dest, const Rect& src, const Color& colorClear = Color::alpha);

    void addTexturedPoint(const TexturePtr& texture, const Point& point, const Color& color = Color::white) const
    { addTexturedRect(Rect(point, texture->getSize()), texture, color); }

    void addTexturedPos(const TexturePtr& texture, const int x, const int y, const Color& color = Color::white) const
    { addTexturedRect(Rect(x, y, texture->getSize()), texture, color); }

    void addTexturedRect(const Rect& dest, const TexturePtr& texture, const Color& color = Color::white) const
    { addTexturedRect(dest, texture, Rect(Point(), texture->getSize()), color); }

    void addTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color = Color::white) const;
    void addTexturedCoordsBuffer(const TexturePtr& texture, const CoordsBufferPtr& coords, const Color& color = Color::white) const;
    void addUpsideDownTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color = Color::white) const;
    void addTexturedRepeatedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color = Color::white) const;
    void addFilledRect(const Rect& dest, const Color& color = Color::white) const;
    void addFilledTriangle(const Point& a, const Point& b, const Point& c, const Color& color = Color::white) const;
    void addBoundingRect(const Rect& dest, const Color& color = Color::white, uint16_t innerLineWidth = 1) const;
    void addAction(const std::function<void()>& action, size_t hash = 0) const { getCurrentPool()->addAction(action, hash); }
    void addAction(const std::function<void()>& action, const ActionIdiom idiom, size_t hash = 0) const { getCurrentPool()->addAction(action, idiom, hash); }
    void addLineStrip(const std::vector<Point>& points, const uint16_t width, const Color& color, const std::function<void()>& glAction) const
    { getCurrentPool()->addLineStrip(points, width, color, glAction); }
    void addLightOverlay(const TexturePtr& texture, const Rect& dest, const Rect& src, const uint16_t tileSize, const std::function<void()>& glAction) const
    { getCurrentPool()->addLightOverlay(texture, dest, src, tileSize, glAction); }
    void addTextureUpload(const TextureHandle texture, const Size& size, const uint8_t* pixels, const size_t byteCount) const
    { getCurrentPool()->addTextureUpload(texture, size, pixels, byteCount); }
    void setCompositionMaterial(const MaterialHandle material, const MaterialParams& params, const float opacity,
                                const std::array<TextureHandle, 3>& extraTex = {}) const
    { getCurrentPool()->setCompositionMaterial(material, params, opacity, extraTex); }

    // Registers the rect of UIMap's alpha-0 cutout as declared data (see DrawPool::m_mapHole).
    void setMapHole(const Rect& rect) const { getCurrentPool()->m_pendingMapHole = rect; }

    void bindFrameBuffer(const Size& size, const Color& color = Color::white) const { getCurrentPool()->bindFrameBuffer(size, color); }
    void releaseFrameBuffer(const Rect& dest) const { getCurrentPool()->releaseFrameBuffer(dest); };
    void releaseFrameBuffer(const Rect& dest, uint8_t flipDirection) const { getCurrentPool()->releaseFrameBuffer(dest, flipDirection); };

    void setOpacity(const float opacity, const bool onlyOnce = false) const { getCurrentPool()->setOpacity(opacity, onlyOnce); }
    void setClipRect(const Rect& clipRect, const bool onlyOnce = false) const { getCurrentPool()->setClipRect(clipRect, onlyOnce); }
    void setBlendEquation(const BlendEquation equation, const bool onlyOnce = false) const { getCurrentPool()->setBlendEquation(equation, onlyOnce); }
    void setCompositionMode(const CompositionMode mode, const bool onlyOnce = false) const { getCurrentPool()->setCompositionMode(mode, onlyOnce); }
    void setDrawOrder(DrawOrder order)const { getCurrentPool()->setDrawOrder(order); }

    bool shaderNeedFramebuffer() const;
    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram, const std::function<void()>& action) const { getCurrentPool()->setShaderProgram(shaderProgram, false, action); }
    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram, const bool onlyOnce = false, const std::function<void()>& action = nullptr) const { getCurrentPool()->setShaderProgram(shaderProgram, onlyOnce, action); }

    float getOpacity() const { return getCurrentPool()->getOpacity(); }
    Rect getClipRect() const { return getCurrentPool()->getClipRect(); }

    void resetState() const { getCurrentPool()->resetState(); }
    void resetOpacity() const { getCurrentPool()->resetOpacity(); }
    void resetClipRect() const { getCurrentPool()->resetClipRect(); }
    void resetShaderProgram() const { getCurrentPool()->resetShaderProgram(); }
    void resetCompositionMode() const { getCurrentPool()->resetCompositionMode(); }
    void resetDrawOrder() const { getCurrentPool()->resetDrawOrder(); }
    void resetOnlyOnceParameters() const { getCurrentPool()->resetOnlyOnceParameters(); }

    void pushTransformMatrix() const { getCurrentPool()->pushTransformMatrix(); }
    void popTransformMatrix() const { getCurrentPool()->popTransformMatrix(); }
    void scale(const float factor) const { getCurrentPool()->scale(factor); }
    void translate(const float x, const float y) const { getCurrentPool()->translate(x, y); }
    void translate(const Point& p) const { getCurrentPool()->translate(p); }
    void rotate(const float angle) const { getCurrentPool()->rotate(angle); }
    void rotate(const float x, const float y, const float angle) const { getCurrentPool()->rotate(x, y, angle); }
    void rotate(const Point& p, const float angle) const { getCurrentPool()->rotate(p, angle); }

    void setScaleFactor(const float scale) const { getCurrentPool()->setScaleFactor(scale); }
    float getScaleFactor() const { return getCurrentPool()->getScaleFactor(); }
    bool isScaled() const { return getCurrentPool()->isScaled(); }
    uint16_t getScaledSpriteSize() const { return m_spriteSize * getScaleFactor(); }
    const auto getAtlas() const { return getCurrentPool()->getAtlas(); }
    bool isValid() const;
    auto getDrawOrder() const { return getCurrentPool()->getDrawOrder(); }

    template<typename T>
    void setParameter(std::string_view name, T&& value) { getCurrentPool()->setParameter(name, value); }
    void removeParameter(const std::string_view name) { getCurrentPool()->removeParameter(name); }

    template<typename T>
    T getParameter(const std::string_view name) { return getCurrentPool()->getParameter<T>(name); }
    bool containsParameter(const std::string_view name) { return getCurrentPool()->containsParameter(name); }

    void flush() const { if (getCurrentPool()) getCurrentPool()->flush(); }

    DrawPoolType getCurrentType() const;

    void repaint(const DrawPoolType drawPool) const {
        get(drawPool)->repaint();
    }

    bool isPreDrawing() const;

    void removeTextureFromAtlas(uint32_t id, bool smooth);
    std::string getAtlasStats() const;

private:
    DrawPool* getCurrentPool() const;

    void draw();

    // Swap and clear every pool's pending flags without drawing anything. Needed whenever
    // a frame is produced by something other than the GL draw path: the map thread blocks
    // in GraphicalApplication::canDrawMap until the shouldRepaint flags are consumed, so a
    // frame that skips draw() must still consume them or map production stops for good.
    // The Vulkan feeder does the same thing for the same reason (VkDrawFeeder::consumeAllPools).
    void consumeAll();

    void init(uint16_t spriteSize);
    void terminate();
    void drawObject(DrawPool* pool, const DrawPool::DrawObject& obj);
    void drawPool(DrawPoolType type);
    void drawObjects(DrawPool* pool);

    // The legacy renderer: replay every pool's object list onto Painter.
    void drawLegacy();

    // The compiled renderer. False means it declined this frame - nothing was drawn and no
    // repaint flag was consumed - and the caller must fall back to drawLegacy().
    bool drawFrame();

    // Makes every texture the compiled programs deferred resident, and runs atlas maintenance.
    // Both are render-thread work the compiler could not do; see PoolProgram::residency and
    // PoolProgram::requiresAtlasMaintenance.
    void prepareResources(const FrameAssembler::Programs& programs);

    // CPU atlas maintenance, compiled rather than performed. Fills m_atlasPrograms with whatever
    // each atlas owes this frame; the assembler puts those passes ahead of every pool.
    void compileAtlasMaintenance();

    // Retire it, once the frame carrying it has been submitted.
    void commitAtlasMaintenance();

    // Points the registry's target table at the framebuffers this frame's passes name, sizing
    // transient ones on the way. Decoding a handle back to a pool is arithmetic, so this is the
    // only place that needs to know a target handle came from a DrawPool at all.
    void bindFrameTargets(const RenderFrame& frame);

    RenderPath m_renderPath{ RenderPath::Legacy };
    std::unique_ptr<IRenderBackend> m_backend;
    FrameAssembler m_frameAssembler;
    RenderFrame m_frame;

    // The distinct atlases, by type. The pools share them - all three foreground pools point at
    // one - so maintenance has to be driven per ATLAS rather than per pool, or the second and
    // third pool would compile an empty program over an already-drained pending list.
    //
    // NON-OWNING, deliberately. The pools own them and the pools are never deleted, so an atlas
    // outlives static destruction; holding a shared_ptr here instead made `g_drawPool`'s own
    // teardown destroy them, which reached ~Texture through the layer framebuffers at
    // __cxa_finalize time and aborted on a mutex that had already been destroyed.
    std::array<TextureAtlas*, Fw::TextureAtlasType::LAST> m_atlases{};
    FrameAssembler::AtlasPrograms m_atlasPrograms{};
    bool m_loggedFrameFallback{ false };

    inline bool isDrawing(const DrawPoolType type) const {
        auto pool = get(type);
        return pool->isEnabled() && pool->shouldRepaint();
    }

    std::array<DrawPool*, static_cast<uint8_t>(DrawPoolType::LAST)> m_pools{};

    Size m_size;
    Matrix3 m_transformMatrix;

    uint16_t m_spriteSize{ 32 };

    friend class GraphicalApplication;
};

extern DrawPoolManager g_drawPool;
