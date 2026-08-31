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

#include "declarations.h"
#include "framebuffer.h"
#include "render/renderdeclarations.h"
#include "render/renderframe.h"
#include "render/poolprogram.h"

#include <memory>
#include "framework/core/timer.h"

#include "../stdext/storage.h"
#include <framework/util/spinlock.h>

struct DrawHashController
{
    DrawHashController(bool agroup = false) : m_agroup(agroup) {}

    bool put(size_t hash) {
        if ((m_agroup && m_hashs.emplace(hash).second) || m_lastObjectHash != hash) {
            m_lastObjectHash = hash;
            stdext::hash_union(m_currentHash, hash);
            return true;
        }

        return false;
    }

    bool isLast(const size_t hash) const {
        return m_lastObjectHash == hash;
    }

    void forceUpdate() {
        m_currentHash = 1;
    }

    bool wasModified() const {
        return m_currentHash != m_lastHash;
    }

    void reset() {
        if (m_currentHash != 1)
            m_lastHash = m_currentHash;

        m_hashs.clear();
        m_currentHash = 0;
        m_lastObjectHash = 0;
    }

private:
    stdext::set<size_t> m_hashs;

    size_t m_lastHash{ 0 };
    size_t m_currentHash{ 0 };
    size_t m_lastObjectHash{ 0 };
    bool m_agroup{ false };
};

class DrawPool
{
public:
    static constexpr uint16_t
        FPS1 = 1000 / 1,
        FPS10 = 1000 / 10,
        FPS20 = 1000 / 20,
        FPS60 = 1000 / 60;

    ~DrawPool() { m_enabled = false; }

    void setEnable(const bool v) { m_enabled = v; }

    DrawPoolType getType() const { return m_type; }

    bool isEnabled() const { return m_enabled; }
    bool isType(const DrawPoolType type) const { return m_type == type; }

    bool isValid() const { return !m_framebuffer || m_framebuffer->isValid(); }
    bool hasFrameBuffer() const { return m_framebuffer != nullptr; }
    FrameBufferPtr getFrameBuffer() const { return m_framebuffer; }

    bool canRepaint();
    void repaint() { m_hashCtrl.forceUpdate(); m_refreshTimer.update(-1000); }
    void resetState();
    void scale(float factor);

    void agroup(const bool agroup) { m_alwaysGroupDrawings = agroup; }

    void setScaleFactor(const float scale) { m_scaleFactor = scale; }
    float getScaleFactor() const { return m_scaleFactor; }
    bool isScaled() const { return m_scaleFactor != DEFAULT_DISPLAY_DENSITY; }

    void setFramebuffer(const Size& size, float contentScale = 1.f);
    float getContentScale() const { return m_framebuffer ? m_framebuffer->getContentScale() : 1.f; }

    // Logical coordinate space -> device pixels. Clip rects need it because the scissor test is
    // applied outside the projection; nothing else does.
    static Rect scaleToDevice(const Rect& rect, float scale);
    void removeFramebuffer();

    void onBeforeDraw(std::function<void()>&& f) { m_beforeDraw = std::move(f); }
    void onAfterDraw(std::function<void()>&& f) { m_afterDraw = std::move(f); }

    auto& getHashController() {
        return m_hashCtrl;
    }

    const auto getAtlas() const {
        return m_atlas.get();
    }

    bool shouldRepaint() const {
        return m_shouldRepaint.load(std::memory_order_relaxed);
    }

    void release();

    auto& getThreadLock() { return m_threadLock; }

    // Compiling is OFF by default and costs nothing when off - the GL path is what ships, and
    // it does not read a PoolProgram. Turning it on makes release() additionally compile the
    // list it just published, so the two representations of one frame can be compared.
    // Phase 3 replaces this switch with the `graphics.renderPath` config flag.
    static void setCompileFrames(bool v) { s_compileFrames = v; }
    static bool isCompilingFrames() { return s_compileFrames; }

    // The most recently compiled program, or nullptr if compiling is off or nothing has been
    // published yet. Read on the consumer side under getThreadLock().
    const PoolProgram* getCompiledProgram() const { return m_programPublished.get(); }

    // The render thread's counterpart to release(): takes the newly published program if there
    // is one and consumes the repaint flag. See the definition for why there are three slots.
    const PoolProgram* acquireProgram();

    // Whether this pool's program can be executed faithfully, peeked without consuming.
    bool hasUsableProgram();

protected:

    enum class DrawMethodType
    {
        RECT,
        TRIANGLE,
        REPEATED_RECT,
        BOUNDING_RECT,
        UPSIDEDOWN_RECT,
    };

    struct DrawMethod
    {
        DrawMethodType type{ DrawMethodType::RECT };
        Rect dest{}, src{};
        Point a{}, b{}, c{};
        uint16_t intValue{ 0 };
    };

    struct PoolState
    {
        Matrix3 transformMatrix = DEFAULT_MATRIX3;
        float opacity{ 1.f };
        CompositionMode compositionMode{ CompositionMode::NORMAL };
        BlendEquation blendEquation{ BlendEquation::ADD };
        Rect clipRect;
        PainterShaderProgram* shaderProgram{ nullptr };
        std::function<void()> action{ nullptr };
        Color color{ Color::white };
        TexturePtr texture;
        uint32_t textureId{ 0 };
        uint16_t textureMatrixId{ 0 };

        // Logical identity of whatever this state draws with, valid in BOTH the deferred
        // (`texture`) and the already-resolved (`textureId`) case. The GL path ignores it;
        // a frame compiler needs it because `textureId` is a native id and native ids may
        // not cross the renderer boundary.
        TextureHandle textureHandle;

        // "Have the pixels behind that handle changed?", answered for the one case the handle
        // itself cannot answer and neither can `texture`, which is null whenever the draw was
        // resolved to an atlas layer. A layer's pixels change when a new sprite is composited
        // into it, including into shelf space a destroyed sprite just vacated - which produces a
        // byte-identical packet drawing entirely different art. Carried, never hashed for
        // batching: two draws from the same layer still batch together.
        uint32_t textureRevision{ 0 };

        size_t hash{ 0 };

        bool operator==(const PoolState& s2) const { return hash == s2.hash; }
        void execute(DrawPool* pool) const;
    };

    struct DrawObject
    {
        DrawObject(std::function<void()> action) : action(std::move(action)) {}
        DrawObject(PoolState&& state, std::shared_ptr<CoordsBuffer>&& coords) : coords(std::move(coords)), state(std::move(state)) {}
        std::function<void()> action{ nullptr };
        std::shared_ptr<CoordsBuffer> coords;
        PoolState state;

        // Declared temporary-framebuffer boundary. bind/releaseFrameBuffer push opaque GL
        // lambdas, and the objects between them have coordinates LOCAL to that temporary
        // framebuffer - so any consumer that does not EXECUTE the lambdas needs the boundary
        // stated as data. These fields state it: where a nested target begins, how big it is,
        // and how its result is blitted back out.
        //
        // Introduced for the Vulkan feeder, which is why they were originally named vkFb*.
        // They are not Vulkan-specific and never were: they are the declared input any frame
        // compiler needs, and the pool compiler is their second consumer. The GL path ignores
        // them (a dozen or so bytes per object) because it just runs the lambdas.
        // What an `action` callback MEANS, for consumers that cannot execute it. Only read
        // when `action` is set. Deliberately separate from fbMarker: the framebuffer markers
        // are consumed by the shipped Vulkan feeder as raw 1/2, and this migration does not
        // change code it cannot compile and run.
        ActionIdiom idiom{ ActionIdiom::Opaque };

        uint8_t fbMarker{ 0 };   // 0 = regular object, 1 = bind, 2 = release
        uint8_t fbFlip{ 0 };     // as in FrameBuffer::prepare: 0 none, 1 horizontal, 2 vertical
        float fbOpacity{ 1.f };  // opacity of the state GL would blit the framebuffer with
        Size fbSize;             // size of the temporary framebuffer (at bind)
        Rect fbDest;             // destination rect of the blit (at release)
    };

    struct DrawObjectState
    {
        CompositionMode compositionMode{ CompositionMode::NORMAL };
        BlendEquation blendEquation{ BlendEquation::ADD };
        Rect clipRect;
        float opacity{ 1.f };
        PainterShaderProgram* shaderProgram{ nullptr };
        std::function<void()> action{ nullptr };
    };

private:

    static DrawPool* create(DrawPoolType type);
    static void addCoords(CoordsBuffer& buffer, const DrawMethod& method);

    enum STATE_TYPE : uint32_t
    {
        STATE_OPACITY = 1 << 0,
        STATE_CLIP_RECT = 1 << 1,
        STATE_SHADER_PROGRAM = 1 << 2,
        STATE_COMPOSITE_MODE = 1 << 3,
        STATE_BLEND_EQUATION = 1 << 4,
    };

    void add(const Color& color, const TexturePtr& texture, DrawMethod&& method, const CoordsBufferPtr& coordsBuffer = nullptr);

    void addAction(const std::function<void()>& action, size_t hash = 0);
    void addAction(const std::function<void()>& action, ActionIdiom idiom, size_t hash = 0);
    void addDeclaredAction(const std::function<void()>& action, ActionIdiom idiom,
                           PoolState&& state, std::shared_ptr<CoordsBuffer>&& coords, size_t hash = 0);
    void addLineStrip(const std::vector<Point>& points, uint16_t width, const Color& color,
                      const std::function<void()>& glAction);

    void compilePublishedObjects();
    void refreshCompiledComposition(PoolProgram& program) const;

    // Declares a dynamic texture upload for this frame. LightView is the only producer: it
    // computes an RGBA bitmap of one texel per visible tile on the CPU and re-uploads it when
    // the light hash changes. Declared only in the frames GL would actually upload in, so a
    // compiled frame does no more work than the GL one.
    void addTextureUpload(TextureHandle texture, const Size& size, const uint8_t* pixels, size_t byteCount);

    // The light overlay, declared. `src` is in map pixels and is divided by tileSize to reach
    // the light texture's normalised space - the same arithmetic LightView::updateCoords does.
    void addLightOverlay(const TexturePtr& texture, const Rect& dest, const Rect& src,
                         uint16_t tileSize, const std::function<void()>& glAction);

    // Declares the material this pool's target blit is composited with (the map shader).
    // `extraTex` is u_Tex1..3 for the composition material. It travels separately from the
    // packet-building path because the composition packet is the FRAME ASSEMBLER's, not the
    // compiler's - so PoolCompiler's multi-texture handling never sees it, and Fog and Snow are
    // map shaders, which is exactly the site that goes through here.
    void setCompositionMaterial(MaterialHandle material, const MaterialParams& params, float opacity,
                                const std::array<TextureHandle, 3>& extraTex = {});
    void bindFrameBuffer(const Size& size, const Color& color = Color::white);
    void releaseFrameBuffer(const Rect& dest);
    void releaseFrameBuffer(const Rect& dest, uint8_t flipDirection);

    void setFPS(const uint16_t fps) { m_refreshDelay = 1000 / fps; }

    bool canRefresh() const
    {
        uint16_t refreshDelay = m_refreshDelay;
        if (m_shaderRefreshDelay > 0 && (refreshDelay == 0 || m_shaderRefreshDelay < refreshDelay))
            refreshDelay = m_shaderRefreshDelay;

        return refreshDelay > 0 && m_refreshTimer.ticksElapsed() >= refreshDelay;
    }

    bool updateHash(const DrawMethod& method, const Texture* texture, const Color& color, bool hasCoord);
    PoolState getState(const TexturePtr& texture, const AtlasRegion* atlasRegion, const Color& color);

    PoolState& getCurrentState() { return m_states[m_lastStateIndex]; }
    const PoolState& getCurrentState() const { return m_states[m_lastStateIndex]; }

    float getOpacity() const { return getCurrentState().opacity; }
    Rect getClipRect() { return getCurrentState().clipRect; }
    auto getDrawOrder() const { return m_currentDrawOrder; }

    void setCompositionMode(CompositionMode mode, bool onlyOnce = false);
    void setBlendEquation(BlendEquation equation, bool onlyOnce = false);
    void setClipRect(const Rect& clipRect, bool onlyOnce = false);
    void setOpacity(float opacity, bool onlyOnce = false);
    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram, bool onlyOnce = false, const std::function<void()>& action = nullptr);
    void setDrawOrder(DrawOrder order) { m_currentDrawOrder = order; }

    void resetOpacity() { getCurrentState().opacity = 1.f; }
    void resetClipRect() { getCurrentState().clipRect = {}; }
    void resetShaderProgram() { getCurrentState().shaderProgram = nullptr; getCurrentState().action = nullptr; }
    void resetCompositionMode() { getCurrentState().compositionMode = CompositionMode::NORMAL; }
    void resetBlendEquation() { getCurrentState().blendEquation = BlendEquation::ADD; }
    void resetTransformMatrix() { getCurrentState().transformMatrix = DEFAULT_MATRIX3; }
    void resetDrawOrder() { m_currentDrawOrder = DrawOrder::FIRST; }

    void pushTransformMatrix();
    void popTransformMatrix();
    void translate(float x, float y);
    void translate(const Point& p) { translate(p.x, p.y); }
    void rotate(float angle);
    void rotate(float x, float y, float angle);
    void rotate(const Point& p, const float angle) { rotate(p.x, p.y, angle); }

    std::shared_ptr<CoordsBuffer> getCoordsBuffer();

    template<typename T>
    void setParameter(std::string_view name, T&& value) {
        m_parameters.emplace(name, value);
    }
    template<typename T>
    T getParameter(const std::string_view name) {
        const auto it = m_parameters.find(name);
        if (it != m_parameters.end()) {
            return std::any_cast<T>(it->second);
        }

        return T();
    }
    bool containsParameter(const std::string_view name) {
        return m_parameters.contains(name);
    }
    void removeParameter(const std::string_view name) {
        const auto& it = m_parameters.find(name);
        if (it != m_parameters.end())
            m_parameters.erase(it);
    }

    void flush();

    void resetOnlyOnceParameters() {
        if (m_onlyOnceStateFlag > 0) { // Only Once State
            // Restore previous values instead of resetting to defaults
            if (m_onlyOnceStateFlag & STATE_OPACITY)
                getCurrentState().opacity = m_previousOpacity;

            if (m_onlyOnceStateFlag & STATE_BLEND_EQUATION)
                getCurrentState().blendEquation = m_previousBlendEquation;

            if (m_onlyOnceStateFlag & STATE_CLIP_RECT)
                getCurrentState().clipRect = m_previousClipRect;

            if (m_onlyOnceStateFlag & STATE_COMPOSITE_MODE)
                getCurrentState().compositionMode = m_previousCompositionMode;

            if (m_onlyOnceStateFlag & STATE_SHADER_PROGRAM) {
                getCurrentState().shaderProgram = m_previousShaderProgram;
                getCurrentState().action = m_previousShaderAction;
            }

            m_onlyOnceStateFlag = 0;
        }
    }

    // The state stack is a fixed array and both ends of it were unguarded. m_lastStateIndex is
    // UNSIGNED, so a backState() with nothing pushed wrapped it to its maximum and the next
    // getCurrentState() indexed far outside m_states; nextStateAndReset() would likewise run
    // off the end past depth 9. Neither is reachable from the seven balanced bind/release call
    // sites, which is why it went unnoticed - but "not reachable today" is not a memory-safety
    // argument, and a Linux runner segfaulted on the first test that tried it while macOS had
    // been silently tolerating the same out-of-bounds read.
    static constexpr uint_fast8_t MAX_STATE_DEPTH = 10;

    bool nextStateAndReset() {
        if (m_lastStateIndex + 1 >= MAX_STATE_DEPTH)
            return false;

        m_states[++m_lastStateIndex] = {};
        return true;
    }

    bool backState() {
        if (m_lastStateIndex == 0)
            return false;

        --m_lastStateIndex;
        return true;
    }

    const FrameBufferPtr& getTemporaryFrameBuffer(uint8_t index);

    bool m_enabled{ true };
    bool m_alwaysGroupDrawings{ false };

    int_fast8_t m_bindedFramebuffers{ -1 };

    uint16_t m_refreshDelay{ 0 }, m_shaderRefreshDelay{ 0 };
    uint32_t m_onlyOnceStateFlag{ 0 };
    uint_fast64_t m_lastFramebufferId{ 0 };

    // Store previous values before onlyOnce override to restore them correctly
    float m_previousOpacity{ 1.f };
    BlendEquation m_previousBlendEquation{ BlendEquation::ADD };
    CompositionMode m_previousCompositionMode{ CompositionMode::NORMAL };
    Rect m_previousClipRect;
    PainterShaderProgram* m_previousShaderProgram{ nullptr };
    std::function<void()> m_previousShaderAction{ nullptr };

    PoolState m_states[MAX_STATE_DEPTH];
    uint_fast8_t m_lastStateIndex{ 0 };

    DrawPoolType m_type{ DrawPoolType::LAST };
    DrawOrder m_currentDrawOrder{ DrawOrder::FIRST };

    Timer m_refreshTimer;

    DrawHashController m_hashCtrl;

    std::vector<Matrix3> m_transformMatrixStack;
    std::vector<FrameBufferPtr> m_temporaryFramebuffers;

    std::vector<DrawObject> m_objects[static_cast<uint8_t>(LAST)];
    std::vector<DrawObject> m_objectsFlushed;
    std::array<std::vector<DrawObject>, 2> m_objectsDraw;
    std::vector<CoordsBuffer*> m_coordsCache;

    stdext::map<size_t, CoordsBuffer*> m_coords;
    stdext::map<std::string_view, std::any> m_parameters;

    float m_scaleFactor{ 1.f };
    float m_scale{ DEFAULT_DISPLAY_DENSITY };

    FrameBufferPtr m_framebuffer;

    std::function<void()> m_beforeDraw;
    std::function<void()> m_afterDraw;

    TextureAtlasPtr m_atlas;
    std::atomic_bool m_shouldRepaint{ false };

    SpinLock m_threadLock;

    // Double-buffered like the object list itself: release() compiles into one and swaps it
    // into place under the same lock, so a consumer never reads a half-built program.
    // unique_ptr rather than by value because PoolProgram is deliberately non-movable - every
    // pass in it points into its own arena.
    std::unique_ptr<PoolProgram> m_programBuild;
    std::unique_ptr<PoolProgram> m_programPublished;
    // The consumer's slot. Held across frames, so a pool that publishes nothing new keeps
    // contributing what it last drew - which is exactly what the GL path does by re-running
    // m_objectsDraw[1].
    std::unique_ptr<PoolProgram> m_programDraw;

    bool m_loggedUnsupported{ false };
    bool m_loggedUnbalancedRelease{ false };

    // Binds refused for want of state-stack depth. Their matching releases must be refused
    // too, or each one would pop a state its bind never pushed and unbalance everything after
    // it - turning a guard against corruption into a different corruption.
    uint_fast8_t m_refusedBinds{ 0 };

    static bool s_compileFrames;

    // Declared pool-framebuffer blit rects. A consumer that does not execute GL actions cannot
    // learn dest/src from m_framebuffer->prepare, so they travel to the drawing thread as data:
    // preDraw writes the pending pair (map thread only) and release() publishes it under
    // m_threadLock, together with the object list, so no consumer can ever pair rects from one
    // frame with objects from another.
    Rect m_pendingFbDest;
    Rect m_pendingFbSrc;
    Rect m_fbDest;
    Rect m_fbSrc;

    // Declared clear colour for this pool's own target. It travelled only inside the
    // PoolTargetPrepare callback (as FrameBuffer::m_colorClear), so a consumer that does not
    // run callbacks could not learn it and assumed transparent. The MAP pool passes
    // Color::black, so assuming transparent left the map target unpainted where nothing drew.
    Color m_pendingFbClearColor{ Color::alpha };
    Color m_fbClearColor{ Color::alpha };

    // Declared "map hole punch" rect: UIMap registers the rectangle of the alpha-0 window it cuts
    // over the game view, so a consumer only treats a shape MATCHING this rect as a hole.
    // This has to be declared rather than inferred, and the reason is empirical: guessing by
    // "untextured + alpha=0" alone cut holes through regular UI - any widget faded to zero
    // opacity - letting the world show through e.g. the prey window.
    Rect m_pendingMapHole;
    Rect m_mapHole;

    // Declared dynamic uploads, published under m_threadLock alongside the object list for
    // exactly the same reason the blit rects are: a consumer must never pair uploads from
    // one frame with objects from another.
    std::vector<TextureUpdate> m_pendingUploads;
    std::vector<TextureUpdate> m_uploads;

    // Declared composition material for this pool's target blit. The GL path expresses the
    // map shader as an onBeforeDraw callback that binds a program and sets uniforms right
    // before the blit; a consumer that does not run callbacks needs it as data.
    //
    // One behavioural note: MapView computes the shader-fade opacity inside that callback, on
    // the render thread, whereas this is declared one step earlier on the producer thread. A
    // compiled frame therefore samples the fade ramp one frame ahead of the GL one. That is a
    // sub-frame difference in a fade, and declaring it here also removes the callback's
    // existing habit of mutating MapView state from the render thread.
    MaterialHandle m_pendingCompositionMaterial;
    std::array<TextureHandle, 3> m_pendingCompositionExtraTex{};
    MaterialParams m_pendingCompositionParams;
    float m_pendingCompositionOpacity{ 1.f };

    MaterialHandle m_compositionMaterial;
    std::array<TextureHandle, 3> m_compositionExtraTex{};
    MaterialParams m_compositionParams;
    float m_compositionOpacity{ 1.f };

    friend class DrawPoolManager;
    friend class VkDrawFeeder;
    friend class PoolCompiler;

    // Test seam. tests/render/ drives a pool directly - it has no window, no GL context and no
    // initialised DrawPoolManager - and reaches the producer API through this.
    //
    // Declared rather than reached with `#define private public`, which is how the suite first
    // did it. That trick links on Itanium-ABI toolchains and CANNOT link on MSVC, which encodes
    // access specifiers into mangled names: a translation unit that redefines `private` emits
    // calls to `public:`-mangled symbols the library never defined. It cost a one-hour Windows
    // job to discover, so it is worth not reintroducing.
    friend struct DrawPoolTestAccess;
};

extern DrawPoolManager g_drawPool;
