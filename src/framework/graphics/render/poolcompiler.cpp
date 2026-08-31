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

#include "poolcompiler.h"

#include <framework/graphics/drawpool.h>
#include <framework/graphics/painter.h>
#include <framework/graphics/paintershaderprogram.h>

#include <cstring>

namespace
{
    // A target being built up. Passes are emitted in EXECUTION order, so a nested target has
    // to be flushed to the pass list before the packet that samples it exists - which means
    // an outer target is split into segments: everything before the nested pass, then the
    // nested pass, then a continuation that loads what the first segment left behind.
    struct OpenSegment
    {
        RenderTargetHandle target;
        Rect viewport;
        Size projectionExtent;
        float contentScale{ 1.f };
        Color clearColor{ Color::alpha };
        LoadAction firstLoad{ LoadAction::Clear };
        bool flushedOnce{ false };

        // Whether draws into this target write the alpha channel. GL keeps this as one global
        // (glColorMask) that FrameBuffer::bind sets and release does NOT restore, so the live
        // value leaks out of nested targets and out of atlas maintenance into whatever draws
        // next. That leak cannot be modelled here even in principle: it crosses pool
        // boundaries, and a pool is compiled alone, on a producer thread, before the frame is
        // ordered. So this states the value each target is ENTERED with, which is the part
        // that is well defined - and the part that matters, because the only place alpha is
        // read back is a pool target sampled by its own composition draw.
        bool alphaWrite{ true };
        std::string label;
        std::vector<DrawPacket> packets;
    };

    struct ClampedScissor
    {
        Rect rect;
        bool enabled{ false };
    };

    // Folds a packet into the program's content identity. Everything that could change what
    // the target ends up looking like has to go in - including the geometry, via the slice,
    // since two packets can share state and draw different things.
    void foldPacket(size_t& hash, const DrawPacket& p, const VertexArena& arena)
    {
        stdext::hash_combine(hash, p.vertexOffset);
        stdext::hash_combine(hash, p.vertexCount);
        stdext::hash_combine(hash, p.texture.id);
        stdext::hash_combine(hash, p.textureMatrixId);
        stdext::hash_combine(hash, p.material.id);
        stdext::hash_combine(hash, static_cast<uint32_t>(p.blend));
        stdext::hash_combine(hash, static_cast<uint32_t>(p.blendEnabled));
        stdext::hash_combine(hash, static_cast<uint32_t>(p.alphaWrite));
        stdext::hash_combine(hash, static_cast<uint32_t>(p.textured));
        stdext::hash_combine(hash, p.opacity);
        stdext::hash_union(hash, p.color.hash());
        if (p.scissorEnabled)
            stdext::hash_union(hash, p.scissor.isValid() ? p.scissor.hash() : size_t{ 1 });
        if (p.transform != DEFAULT_MATRIX3)
            stdext::hash_union(hash, p.transform.hash());

        // The geometry, mixed eight bytes at a time rather than one float at a time.
        //
        // The obvious spelling of this is a stdext::hash_combine per float, and that is what it
        // was. It measured at 85% of the whole compile step and 43% of one producer frame - a
        // dependent chain of std::hash<float> calls over every vertex the pool draws, which for a
        // 2,600-quad scene is 31,200 of them per pool per frame. Mixing wider is the same idea for
        // about a third of the cost, and the saving grows with the scene rather than being a fixed
        // overhead, so it helps most in the frames that are already expensive.
        //
        // What it must NOT become is a cheaper identity that ignores the vertices. The geometry of
        // most draws is folded into DrawHashController on the producer side as well, via the
        // DrawMethod's dest/src rects, so for those this is the second of two checks - but UI text
        // and cached images reach DrawPool::add through the CoordsBuffer overload, where the
        // DrawMethod is default-constructed and carries no rects at all for the producer to fold.
        // For those draws this loop is the ONLY thing that notices a changed string, and
        // FrameAssembler skips re-rendering a retained target whose contentHash is unchanged. Drop
        // it and a label that keeps its glyph count, font, colour and vertex range - "10" becoming
        // "11" - freezes on screen.
        //
        // memcpy rather than a cast through uint64_t*: vertexOffset may be odd, which leaves the
        // read 4-byte aligned, and the compiler folds the copy away anyway. Byte equality is
        // strictly finer than std::hash<float>, which maps +0.0 and -0.0 together; the worst that
        // costs is calling an unchanged target changed and re-rendering it once.
        if (const uint32_t floats = p.vertexCount * 2) {
            const float* pos = arena.positions() + static_cast<size_t>(p.vertexOffset) * 2;

            uint64_t acc = 0xcbf29ce484222325ull; // FNV-1a offset basis
            uint32_t i = 0;
            for (; i + 2 <= floats; i += 2) {
                uint64_t chunk;
                std::memcpy(&chunk, pos + i, sizeof(chunk));
                acc = (acc ^ chunk) * 0x100000001b3ull;
            }

            // Unreachable: a vertex is two floats, so the count is even whatever the primitive is
            // (not every one is a triangle - addUpsideDownQuad emits four vertices). Kept anyway,
            // because a loop that silently dropped the last float would be a hash that quietly
            // stops noticing changes rather than an obvious bug.
            if (i < floats) {
                uint32_t tail;
                std::memcpy(&tail, pos + i, sizeof(tail));
                acc = (acc ^ tail) * 0x100000001b3ull;
            }

            // Folded to 32 bits before it meets hash_union, so the Android and WASM builds - where
            // size_t is 32 bits - keep the high half's entropy instead of truncating it away.
            stdext::hash_union(hash, static_cast<size_t>(acc ^ (acc >> 32)));
        }
    }

    // Scissor rects arrive from the producer unclamped. GL forgave out-of-bounds ones; Metal
    // validates and kills the encoder. Clamping here means neither backend has to care.
    // A clip rect is recorded in the pool's logical space while the scissor test runs in device
    // pixels, so it is clamped against the logical extent and scaled on the way out.
    Rect logicalViewport(const OpenSegment& seg)
    {
        return seg.projectionExtent.isValid() ? Rect(0, 0, seg.projectionExtent) : seg.viewport;
    }

    ClampedScissor clampScissor(const Rect& scissor, const Rect& viewport, const float scale = 1.f)
    {
        if (!scissor.isValid())
            return { {}, false }; // no clipping was requested

        const Rect clamped = scissor.intersection(viewport);
        if (!clamped.isValid())
            return { Rect(viewport.left(), viewport.top(), 0, 0), true }; // misses the target: clips everything

        return { DrawPool::scaleToDevice(clamped, scale), true };
    }
}

MaterialHandle PoolCompiler::materialOf(const PainterShaderProgram* program)
{
    if (!program)
        return {};

    // Painter's own built-in programs never go through ShaderManager::putShader, so they carry
    // id 0 and are NOT module materials. One of them genuinely reaches pool state: the
    // replace-colour program, which every marked or highlighted thing binds
    // (creature.cpp, item.cpp). Mapping it through the module range produced a material handle
    // no backend could resolve - and, before m_id was initialised, a different one per run.
    if (program->getId() == 0) {
        if (g_painter && g_painter->isReplaceColorShader(program))
            return materialHandleOf(BuiltinMaterial::ReplaceColor);

        // Any other unregistered program is one this compiler has no name for. The default
        // material draws it as ordinary textured/solid geometry, which is a visible
        // approximation rather than an unresolvable handle.
        return {};
    }

    // ShaderManager numbers registered programs from 1; offsetting by FirstModule keeps them
    // clear of the built-ins forever.
    return MaterialHandle{ static_cast<uint16_t>(
        static_cast<uint16_t>(BuiltinMaterial::FirstModule) + program->getId()) };
}

void PoolCompiler::compile(const DrawPool& pool, const Size& viewportSize, PoolProgram& out)
{
    out.clear();
    out.type = pool.m_type;
    out.uploads = pool.m_uploads;
    out.requiresAtlasMaintenance = pool.m_atlas != nullptr;

    const bool hasTarget = pool.m_framebuffer != nullptr && pool.m_framebuffer->isValid();

    // Root segment: the pool's own retained target, or the backbuffer when it has none.
    OpenSegment root;
    if (hasTarget) {
        root.target = RenderHandles::poolTarget(pool.m_type);
        // The viewport is the target in DEVICE pixels; the projection spans its logical extent.
        // The two differ only for a target that rasterises above the space it is addressed in.
        root.viewport = Rect(0, 0, pool.m_framebuffer->getSize());
        root.projectionExtent = pool.m_framebuffer->getLogicalSize();
        root.contentScale = pool.m_framebuffer->getContentScale();
        root.clearColor = pool.m_fbClearColor;
        root.firstLoad = LoadAction::Clear;
        root.alphaWrite = pool.m_framebuffer->hasAlphaWriting();
        root.label = "pool-target";
    } else {
        root.target = RenderTargetHandle{ RenderTargetHandle::BACKBUFFER };
        root.viewport = Rect(0, 0, viewportSize);
        // A pool with no target draws ON TOP of whatever is already on the backbuffer.
        root.firstLoad = LoadAction::Keep;
        // DrawPoolManager::drawPool resets painter state before every target blit, and reset
        // means alpha writing off - which is the state a pool without a target inherits.
        root.alphaWrite = false;
        root.label = "pool-direct";
    }

    std::vector<OpenSegment> stack;
    stack.push_back(std::move(root));

    // Native texture identity, folded into the content hash at the end.
    //
    // A packet names its texture by LOGICAL handle, and for an AnimatedTexture that handle is
    // deliberately stable across the animation's frames - it is one Texture object whose m_id is
    // re-aimed at the current frame's GL name on every tick. Which is exactly the problem: the
    // frame the target should now show is not the frame it shows, and nothing in the compiled
    // output says so, so `FrameAssembler` finds the hash unchanged and re-composites a stale
    // retained target instead of re-rendering it. The animation stops.
    //
    // Found by capturing map-screenshot down both paths: 24 pixels of a blue floor sparkle,
    // identical across repeated runs of each path and different between them - a deterministic
    // phase difference, not noise. map-core showed the same thing from the other side, its
    // frame-path variance collapsing to 3 pixels where the legacy path varies by 2,719.
    //
    // The native id is the thing that actually changes when an animation advances, and the
    // producer already resolved it (DrawPool::getState). It is used here ONLY as hash input -
    // it does not enter a packet, and no backend sees it - so this is not a native id crossing
    // the boundary.
    //
    // It is not the WHOLE signal, though, and Phase 4 is where that became load-bearing. A
    // backend that creates no GL textures leaves every native id at zero, so under one of those
    // this term is constant and the animation freezes again - the same defect, reached from the
    // other side. `Texture::getContentRevision()` is the backend-independent form of the same
    // question, and it additionally covers pixels overwritten in place, which no native id ever
    // did. Both are folded: the id because it is free and already resolved, the revision because
    // it is the one that is always true.
    size_t nativeTextureHash = 0;

    const auto foldTextureIdentity = [&nativeTextureHash](const DrawPool::PoolState& state) {
        stdext::hash_combine(nativeTextureHash, state.textureId);
        // The revision the producer read when it recorded the draw. It is the only one of the
        // three terms that says anything at all about an ATLAS-backed draw: such a state carries
        // no TexturePtr, and its `textureId` is the layer's, which does not change when the
        // layer's contents do.
        stdext::hash_combine(nativeTextureHash, state.textureRevision);
        if (state.texture)
            stdext::hash_combine(nativeTextureHash, state.texture->getContentRevision());
    };

    // Set by a BlendOff action and cleared by BlendOn - the exact scope the GL bracket has.
    bool blendDisabled = false;

    const auto flush = [&out](OpenSegment& seg, const bool force) {
        if (seg.packets.empty() && (seg.flushedOnce || !force))
            return;

        auto& pass = out.passes.emplace_back();
        pass.target = seg.target;
        pass.load = seg.flushedOnce ? LoadAction::Keep : seg.firstLoad;
        pass.clearColor = seg.clearColor;
        pass.viewport = seg.viewport;
        pass.projectionExtent = seg.projectionExtent;
        pass.label = seg.label;
        pass.packets.swap(seg.packets);

        seg.flushedOnce = true;
    };

    // A state that still carries a TexturePtr is one GL would resolve at draw time:
    // PoolState::execute calls Texture::create() (a lazy upload) and then offers the texture to
    // the pool's atlas. Neither can happen here - both are render-thread work - so the
    // requirement travels as data. See PoolProgram::residency.
    const auto noteResidency = [&out](const DrawPool::PoolState& state) {
        if (!state.texture)
            return;
        // Run-length dedup only. Batching means repeats come in runs, and a duplicate costs
        // nothing anyway: both create() and the atlas offer are idempotent.
        if (out.residency.empty() || out.residency.back() != state.texture)
            out.residency.push_back(state.texture);
    };

    // u_Tex1..3. GL binds these from inside Painter::drawArrays, off the bound program, so the
    // compiled GL path inherits them for free and the frame model never had to carry them. A
    // backend that does not share Painter has no such route, and Fog and Snow - the only two
    // shaders that use them - render as an unlit game screen without them.
    const auto emitMultiTextures = [&out](DrawPacket& packet, const PainterShaderProgram* program) {
        if (!program)
            return;

        size_t unit = 0;
        for (const auto& texture : program->getMultiTextures()) {
            if (unit >= std::size(packet.extraTex))
                break;
            if (!texture)
                continue;
            packet.extraTex[unit++] = TextureHandle{ texture->getUniqueId() };
            // These never pass through PoolState, so noteResidency above cannot see them; a
            // backend still has to be able to upload them before the packet samples one.
            if (out.residency.empty() || out.residency.back() != texture)
                out.residency.push_back(texture);
        }
    };

    const auto emitGeometry = [&](OpenSegment& seg, const DrawPool::DrawObject& obj) {
        if (!obj.coords)
            return;

        const auto slice = out.arena.append(*obj.coords);
        if (slice.isEmpty())
            return;

        auto& packet = seg.packets.emplace_back();
        packet.vertexOffset = slice.offset;
        packet.vertexCount = slice.count;
        packet.textured = slice.textured && obj.state.textureHandle.isValid();
        packet.texture = packet.textured ? obj.state.textureHandle : TextureHandle{};
        packet.textureMatrixId = obj.state.textureMatrixId;
        packet.material = materialOf(obj.state.shaderProgram);
        emitMultiTextures(packet, obj.state.shaderProgram);
        packet.transform = obj.state.transformMatrix;
        const auto scissor = clampScissor(obj.state.clipRect, logicalViewport(seg), seg.contentScale);
        packet.scissor = scissor.rect;
        packet.scissorEnabled = scissor.enabled;
        packet.color = obj.state.color;
        packet.opacity = obj.state.opacity;
        packet.blend = blendModeOf(obj.state.compositionMode);
        packet.blendEnabled = !blendDisabled;
        packet.alphaWrite = seg.alphaWrite;

        noteResidency(obj.state);
        foldTextureIdentity(obj.state);
    };

    for (const auto& obj : pool.m_objectsDraw[0]) {
        // Framebuffer markers first: they are declared independently of the idiom tag,
        // because the shipped Vulkan feeder consumes them as raw 1/2 and this migration does
        // not change code it cannot compile and run.
        if (obj.fbMarker == 1) {
            flush(stack.back(), /*force*/ true);

            const auto depth = static_cast<uint32_t>(stack.size() - 1);
            if (depth >= RenderHandles::TRANSIENT_TARGETS_PER_POOL) {
                // Past this depth the handle would land in the NEXT pool's reserved slice and
                // two pools' transient targets would alias. The surveyed sites nest one or two
                // deep, so this is a guard rather than a limit anyone should meet.
                out.unsupported.emplace_back("temporary framebuffer nesting deeper than the handle space allows");
                continue;
            }

            OpenSegment nested;
            nested.target = RenderHandles::transientTarget(pool.m_type, depth);
            nested.viewport = Rect(0, 0, obj.fbSize);
            nested.clearColor = Color::alpha;
            nested.firstLoad = LoadAction::Clear;
            // Temporary framebuffers keep FrameBuffer's default, m_useAlphaWriting = true.
            nested.alphaWrite = true;
            nested.label = "transient";
            stack.push_back(std::move(nested));
            continue;
        }

        if (obj.fbMarker == 2) {
            if (stack.size() < 2) {
                out.unsupported.emplace_back("releaseFrameBuffer without a matching bind");
                continue;
            }

            auto nested = std::move(stack.back());
            stack.pop_back();
            flush(nested, /*force*/ true);

            // The blit back out. GL builds this with CoordsBuffer::addQuad and draws it as a
            // TRIANGLE_STRIP - but addQuad already emits six vertices in triangle-list order,
            // so drawing them as a strip yields the same two triangles plus two degenerate
            // ones. Emitting triangles here is therefore pixel-identical, not merely close.
            CoordsBuffer blit;
            const Rect src(0, 0, nested.viewport.size());
            if (obj.fbFlip == 1)
                blit.addHorizontallyFlippedQuad(obj.fbDest, src);
            else if (obj.fbFlip == 2)
                blit.addVerticallyFlippedQuad(obj.fbDest, src);
            else
                blit.addQuad(obj.fbDest, src);

            const auto slice = out.arena.append(blit);
            auto& seg = stack.back();
            auto& packet = seg.packets.emplace_back();
            packet.vertexOffset = slice.offset;
            packet.vertexCount = slice.count;
            packet.textured = true;
            packet.texture = RenderHandles::targetTexture(nested.target);
            packet.opacity = obj.fbOpacity;
            packet.blend = BlendMode::Normal;
            packet.blendEnabled = !blendDisabled;
            packet.alphaWrite = seg.alphaWrite;

            // The blit runs under the OUTER state, which releaseFrameBuffer captures onto the
            // object: GL applies it with drawState.execute() and only then does
            // FrameBuffer::draw override the texture. Carrying only the opacity was a real
            // omission - the `useFramebuffer` route exists precisely so that a shader applies
            // AT the blit, so dropping the material silently un-shaded every Outline outfit.
            packet.material = materialOf(obj.state.shaderProgram);
            emitMultiTextures(packet, obj.state.shaderProgram);
            packet.color = obj.state.color;
            packet.transform = obj.state.transformMatrix;
            noteResidency(obj.state);

            const auto blitScissor = clampScissor(obj.state.clipRect, logicalViewport(seg), seg.contentScale);
            packet.scissor = blitScissor.rect;
            packet.scissorEnabled = blitScissor.enabled;
            continue;
        }

        if (obj.action) {
            switch (obj.idiom) {
                case ActionIdiom::BlendOff:
                    blendDisabled = true;
                    break;

                case ActionIdiom::BlendOn:
                    blendDisabled = false;
                    break;

                case ActionIdiom::PoolTargetPrepare:
                    // Pure metadata. The rects it would have set are already declared on the
                    // pool (m_fbDest / m_fbSrc) and are read below as composition parameters.
                    break;

                case ActionIdiom::LineStrip:
                case ActionIdiom::LightOverlay:
                    // Declared: the object carries the geometry and state the callback would
                    // have produced, so it compiles exactly like ordinary geometry.
                    emitGeometry(stack.back(), obj);
                    break;

                case ActionIdiom::MapShaderBind:
                    // Installs the composition hooks; the material it selects is declared on
                    // the pool and read below. Nothing to emit into a pass.
                    break;

                case ActionIdiom::Opaque:
                default:
                    out.unsupported.emplace_back("untagged action callback");
                    break;
            }
            continue;
        }

        emitGeometry(stack.back(), obj);
    }

    if (stack.size() != 1)
        out.unsupported.emplace_back("unbalanced framebuffer bind/release");

    while (!stack.empty()) {
        flush(stack.back(), /*force*/ true);
        stack.pop_back();
    }

    if (hasTarget) {
        out.hasComposition = true;
        out.compositionSource = RenderHandles::poolTarget(pool.m_type);
        out.compositionDest = pool.m_fbDest.isValid() ? pool.m_fbDest : Rect(0, 0, pool.m_framebuffer->getSize());
        out.compositionSrc = pool.m_fbSrc.isValid() ? pool.m_fbSrc : Rect(0, 0, pool.m_framebuffer->getSize());

        // The MAP target composites with blending OFF: its pixels replace rather than blend.
        // Every other pool target composites normally.
        out.compositionBlendEnabled = !pool.m_framebuffer->isBlendDisabled();

        // No composition draw writes alpha, whichever pool it belongs to: drawPool resets
        // painter state immediately before the blit and FrameBuffer::draw never sets it back.
        // This used to read hasAlphaWriting(), which is right for MAP by coincidence and wrong
        // for FOREGROUND.
        out.compositionAlphaWrite = false;
        out.compositionMaterial = pool.m_compositionMaterial;
        out.compositionExtraTex = pool.m_compositionExtraTex;
    out.compositionParams = pool.m_compositionParams;
        out.compositionOpacity = pool.m_compositionOpacity;
    }

    // Content identity, computed once the passes are final.
    size_t hash = nativeTextureHash;
    for (const auto& pass : out.passes) {
        stdext::hash_combine(hash, pass.target.id);
        stdext::hash_combine(hash, static_cast<uint32_t>(pass.load));
        for (const auto& packet : pass.packets)
            foldPacket(hash, packet, out.arena);
    }
    out.contentHash = hash;

    out.bindArena();
}
