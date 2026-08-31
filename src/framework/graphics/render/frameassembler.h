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

#include "atlasprogram.h"
#include "poolprogram.h"

#include <deque>

#include <array>

/*
 * FrameAssembler - turns the per-pool programs into one frame.
 *
 * The pools render independently; only the assembler knows the order they composite in and
 * what goes between them. It runs on the render thread and owns two things the compiler
 * cannot: the frame-global shader time, and the interleaving of composition draws with the
 * pools that draw straight to the backbuffer.
 *
 * It is an object rather than a free function because it owns an arena: the composition
 * quads are its own geometry, belonging to no pool, and they have to outlive the call so the
 * frame's passes can point at them.
 *
 * It also inherits an obligation that has nothing to do with drawing: a frame that is
 * DECLINED must still consume the pools' repaint flags, or the map thread blocks forever in
 * canDrawMap waiting for them. DrawPoolManager::consumeAll is that operation.
 */
class FrameAssembler
{
public:
    using Programs = std::array<const PoolProgram*, static_cast<size_t>(DrawPoolType::LAST)>;
    using AtlasPrograms = std::array<const AtlasProgram*, static_cast<size_t>(Fw::TextureAtlasType::LAST)>;

    // `programs` is indexed by DrawPoolType and may hold nulls for pools that produced
    // nothing. `atlases` is indexed by Fw::TextureAtlasType and holds whatever CPU atlas
    // maintenance this frame owes; its passes go FIRST, ahead of every pool, which is exactly
    // where the GL path performs the equivalent work. `frameTime` is the value every material's
    // `time` field receives - it must honour the process-wide pin (g_shaders.setFixedTime),
    // because pinning the phase is the only reason an animated shader frame is reproducible at
    // all.
    void assemble(const Programs& programs, const AtlasPrograms& atlases, const Size& drawableSize,
                  float frameTime, RenderFrame& out);

    // For callers with no atlases to maintain - the unit tests, and any backend running with the
    // CPU atlases switched off.
    void assemble(const Programs& programs, const Size& drawableSize, const float frameTime, RenderFrame& out)
    {
        assemble(programs, AtlasPrograms{}, drawableSize, frameTime, out);
    }

    // True when every contributing program compiled completely. A frame built from an
    // incomplete program describes less than the client asked for and must not be rendered.
    [[nodiscard]] static bool isComplete(const Programs& programs);

    // Forgets what every pool last drew, so the next frame re-renders every retained target
    // instead of trusting a stale content hash. Call after anything that can invalidate a
    // target's contents without changing the objects that drew into it - a resize, a scale
    // change, or a device loss.
    void invalidateRetainedTargets();

private:
    // Fills in the two fields no compiler can know: the frame-global shader time, and the
    // resolution of the target each pass draws into. Runs after the passes are assembled,
    // because until then there is no pass to take a resolution from.
    void supplyMaterialParams(RenderFrame& out, float frameTime);

    // What each pool's retained target currently holds. A pool whose program compiles to the
    // same content is re-composited without re-rendering, which is the compiled equivalent of
    // the GL path skipping drawObjects when a framebuffer pool has nothing new to publish.
    std::array<size_t, static_cast<size_t>(DrawPoolType::LAST)> m_targetContent{};
    std::array<bool, static_cast<size_t>(DrawPoolType::LAST)> m_targetValid{};

    // Geometry for the composition quads. Persists across frames so the passes handed out by
    // the last assemble() stay valid until the next one.
    VertexArena m_arena;

    // Somewhere stable for a packet's MaterialParams pointer to aim at. A deque rather than a
    // vector because entries are appended while packets already point into it - one per
    // composition draw and one per pass - and a deque never invalidates a reference on growth,
    // where a vector would need the count reasoned about in advance and asserted afterwards.
    std::deque<MaterialParams> m_params;
};
