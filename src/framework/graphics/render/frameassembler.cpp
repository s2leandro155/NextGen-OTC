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

#include "frameassembler.h"

#include "renderhandles.h"

#include <cassert>

namespace
{
    // Composition draws land on the backbuffer one after another, separated only by whichever
    // pools draw straight to it. Opening a fresh pass for each would multiply encoder churn
    // for no reason, so adjacent backbuffer work shares a pass.
    RenderPass& backbufferPass(RenderFrame& out, const Size& drawableSize, const VertexArena& arena)
    {
        if (!out.passes.empty()) {
            auto& last = out.passes.back();
            // The arena check is not optional. A pool with no target compiles its own root
            // segment to the BACKBUFFER, and that pass points at THAT POOL's arena. Reusing it
            // for a composition packet - whose vertex offsets index the assembler's arena -
            // would read another pool's geometry, or run off the end of it.
            if (last.target.isBackbuffer() && last.arena == &arena)
                return last;
        }

        auto& pass = out.passes.emplace_back();
        pass.target = RenderTargetHandle{ RenderTargetHandle::BACKBUFFER };
        pass.load = LoadAction::Keep;
        pass.viewport = Rect(0, 0, drawableSize);
        pass.arena = &arena;
        pass.label = "backbuffer";
        return pass;
    }
}

void FrameAssembler::invalidateRetainedTargets()
{
    m_targetValid.fill(false);
    m_targetContent.fill(0);
}

bool FrameAssembler::isComplete(const Programs& programs)
{
    for (const auto* program : programs) {
        if (program && !program->isComplete())
            return false;
    }
    return true;
}

void FrameAssembler::assemble(const Programs& programs, const AtlasPrograms& atlases,
                              const Size& drawableSize, const float frameTime, RenderFrame& out)
{
    out.clear();
    out.drawableSize = drawableSize;

    m_arena.clear();
    m_params.clear();

    // Uploads are applied before any pass, so a texture a pass samples already holds this
    // frame's pixels. LightView is the only producer today.
    for (const auto* program : programs) {
        if (!program)
            continue;
        for (const auto& upload : program->uploads)
            out.uploads.push_back(upload);
    }

    // Atlas maintenance goes ahead of every pool, which is where the GL path already does it -
    // it flushes each atlas from DrawPoolManager before any pass runs. Position is not actually
    // load-bearing: a region created during frame N is not consulted until the PRODUCER runs for
    // frame N+1, because it is DrawPool::add that translates a source rect into atlas
    // coordinates. So nothing this frame draws can see a region this frame created, and the
    // compositing writes land in shelf space no draw in this frame addresses.
    for (const auto* atlas : atlases) {
        if (!atlas)
            continue;
        for (const auto& pass : atlas->passes)
            out.passes.push_back(pass);
    }

    // Pools composite in enum order - the order DrawPoolManager::draw walks them in.
    for (const auto* program : programs) {
        if (!program)
            continue;

        // A pool that draws STRAIGHT to the backbuffer is never skipped: there is no retained
        // target holding its result, so not emitting its passes would simply not draw it. The
        // GL path makes the same distinction - drawObjects' early return is gated on the pool
        // having a framebuffer.
        const auto poolIndex = static_cast<size_t>(program->type);
        const bool canReuseTarget =
            program->hasComposition &&
            poolIndex < m_targetValid.size() &&
            m_targetValid[poolIndex] &&
            m_targetContent[poolIndex] == program->contentHash;

        if (!canReuseTarget) {
            // The pool's own passes: its retained target plus any nested transient targets.
            for (const auto& pass : program->passes)
                out.passes.push_back(pass);

            if (program->hasComposition && poolIndex < m_targetValid.size()) {
                m_targetContent[poolIndex] = program->contentHash;
                m_targetValid[poolIndex] = true;
            }
        }

        if (!program->hasComposition)
            continue;

        // The composition quad is the assembler's own geometry. GL builds the same quad with
        // CoordsBuffer::addQuad inside FrameBuffer::prepare.
        CoordsBuffer quad;
        quad.addQuad(program->compositionDest, program->compositionSrc);
        const auto slice = m_arena.append(quad);

        auto& params = m_params.emplace_back(program->compositionParams);
        params.time = frameTime;
        // MapView declares a resolution of its own, from the map's rect dimension. GL does not
        // use it: Painter uploads u_Resolution from its own resolution on every draw, and at
        // composition time the pool's framebuffer has been released, so that is the viewport.
        // Matching GL is the point, so the viewport wins.
        params.resolution = { static_cast<float>(drawableSize.width()),
                              static_cast<float>(drawableSize.height()) };

        auto& pass = backbufferPass(out, drawableSize, m_arena);
        auto& packet = pass.packets.emplace_back();
        packet.vertexOffset = slice.offset;
        packet.vertexCount = slice.count;
        packet.textured = true;
        packet.texture = RenderHandles::targetTexture(program->compositionSource);
        packet.material = program->compositionMaterial;
        for (size_t unit = 0; unit < program->compositionExtraTex.size(); ++unit)
            packet.extraTex[unit] = program->compositionExtraTex[unit];
        packet.params = program->compositionMaterial.isDefault() ? nullptr : &params;
        packet.opacity = program->compositionOpacity;
        packet.blend = BlendMode::Normal;
        packet.blendEnabled = program->compositionBlendEnabled;
        packet.alphaWrite = program->compositionAlphaWrite;
    }

    supplyMaterialParams(out, frameTime);

    // Passes hold a pointer to the ARENA OBJECT, not to its storage, so growth during the loop
    // is harmless - positions() is resolved when a backend reads it. The pool passes carry
    // their own program's arena pointer, set by PoolProgram::bindArena.
}

void FrameAssembler::supplyMaterialParams(RenderFrame& out, const float frameTime)
{
    // Every packet that names a material needs a parameter block, and until now only the
    // composition packet got one - which was invisible on OpenGL, because Painter uploads
    // u_Time and u_Resolution itself from inside drawArrays on every single draw. A backend
    // that does not share Painter has no such side channel, so an outfit shader reading u_Time
    // would have rendered at time zero forever.
    //
    // Both values are properties of the frame and the pass rather than of the material, which
    // is why the assembler supplies them and the compiler cannot: `time` is frame-global and
    // must honour the process-wide pin, and `resolution` is the size of the target being drawn
    // into - which is exactly what Painter reports, because FrameBuffer::bind sets the painter
    // resolution to the target's size and the backend does the same per pass.
    for (auto& pass : out.passes) {
        const MaterialParams* passParams = nullptr;

        for (auto& packet : pass.packets) {
            if (packet.material.isDefault() || packet.params)
                continue;

            if (!passParams) {
                auto& params = m_params.emplace_back();
                params.time = frameTime;
                params.resolution = { static_cast<float>(pass.viewport.width()),
                                      static_cast<float>(pass.viewport.height()) };
                passParams = &params;
            }

            packet.params = passParams;
        }
    }
}
