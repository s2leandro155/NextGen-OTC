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

#include "materialparams.h"
#include "renderdeclarations.h"
#include "vertexarena.h"

#include <framework/graphics/declarations.h>
#include <vector>

/*
 * The RenderFrame - the renderer boundary itself.
 *
 * Above it, no graphics API exists. Below it, no game semantics exist. Everything a backend
 * needs to draw one frame is in here, stated explicitly, with no callback it has to execute
 * and no mutable state machine it has to track.
 *
 * The command vocabulary is deliberately PACKETS ONLY - no SetBlend/SetScissor/Bind command
 * stream. Each packet carries its complete state. That is affordable because the surveyed
 * live pipeline-state space is roughly 25-30 combinations, and it buys the properties that
 * matter for a migration: packets can be sorted, batched, recorded, diffed and asserted on
 * without correctness depending on the order state commands happened to arrive in.
 */

 // One batched draw. The fields are the surveyed PoolState minus every API type, plus the
 // geometry slice that state applies to.
struct DrawPacket
{
    // Geometry, as an (offset, count) slice of the owning pass's arena. Always triangles:
    // strips and lines are compiled away before they get here.
    uint32_t vertexOffset{ 0 };
    uint32_t vertexCount{ 0 };
    bool textured{ false };

    TextureHandle texture;        // invalid => untextured (solid colour)
    TextureHandle extraTex[3];    // multi-texture materials (only Fog and Snow use these)

    MaterialHandle material;      // 0 => the default built-in for `textured`
    const MaterialParams* params{ nullptr }; // null for built-ins; owned by the frame

    // Copy-initialised, not brace-initialised: Matrix3 has an initializer-list-of-floats
    // constructor that brace syntax selects instead of the copy constructor. PoolState spells
    // it the same way for the same reason.
    Matrix3 transform = DEFAULT_MATRIX3;

    // The per-texture pixel->uv matrix, carried as the registry ID rather than as a resolved
    // Matrix3. This deviates from the design sketch on purpose: the matrix registry
    // (TextureManager::m_matrixCache) is unsynchronised, and packets are built on producer
    // threads, so resolving the pointer at compile time would be a data race. The backend
    // resolves it on the render thread, where the GL path already does.
    uint16_t textureMatrixId{ 0 };

    // Top-left origin, and PRE-CLAMPED to the target by the compiler. Metal validates scissor
    // rects and kills the encoder on an out-of-bounds one; GL silently forgave them. Clamping
    // at compile time means neither backend needs to know the difference.
    //
    // `scissorEnabled` is a separate flag rather than "an invalid rect means off", because the
    // two states are genuinely different and this Rect type cannot express one of them: a clip
    // rect that misses the target entirely must clip EVERYTHING, but TRect(x, y, 0, 0) sets
    // x2 = x - 1 and so reports isValid() == false - indistinguishable from "no clipping", i.e.
    // exactly backwards. An enabled, empty scissor is how "draws nothing" is stated.
    Rect scissor;
    bool scissorEnabled{ false };

    Color color{ Color::white };
    float opacity{ 1.f };

    BlendMode blend{ BlendMode::Normal };

    // Blending switched off entirely - not a blend mode, a separate piece of state. Three
    // things need it: the MAP framebuffer's screen blit, atlas layer compositing, and the UI
    // map-hole punch.
    bool blendEnabled{ true };

    // Alpha channel writes. Off only for the MAP target, whose pixels replace rather than
    // blend when composited.
    bool alphaWrite{ true };
};

// A dynamic texture upload. LightView is the motivating case: it computes an RGBA bitmap of
// one texel per visible tile on the CPU and re-uploads it whenever the light hash changes.
struct TextureUpdate
{
    TextureHandle texture;
    Size size;
    std::vector<uint8_t> pixels; // RGBA8, size.area() * 4 bytes
};

// A pixel readback. Delivered top-left origin regardless of how the backend stores the
// target - the backend flips, never the caller.
struct ReadbackRequest
{
    RenderTargetHandle source;
    Rect region; // top-left origin
};

struct RenderPass
{
    RenderTargetHandle target;              // 0 = backbuffer
    LoadAction load{ LoadAction::Clear };
    Color clearColor{ Color::alpha };
    Rect viewport;                          // device pixels, top-left origin
    const VertexArena* arena{ nullptr };    // geometry source for this pass's packets
    std::vector<DrawPacket> packets;

    // The extent the projection spans, in the coordinate space this pass's geometry and scissors
    // are expressed in. Equal to viewport.size() everywhere except a target that rasterises at a
    // higher resolution than it is addressed in - the FOREGROUND target on a Retina display,
    // which lays out in logical units and must still rasterise across every physical pixel.
    // Invalid means "same as the viewport", which is what keeps this free for every other pass.
    Size projectionExtent;

    [[nodiscard]] Size projectionSize() const
    {
        return projectionExtent.isValid() ? projectionExtent : viewport.size();
    }

    // Debug label. Costs a string per pass and pays for itself the first time a GPU capture
    // or a golden-frame diff has to be read by a human.
    std::string label;
};

struct RenderFrame
{
    Size drawableSize;
    std::vector<RenderPass> passes;         // in execution order
    std::vector<TextureUpdate> uploads;     // applied before the passes
    std::vector<ReadbackRequest> readbacks; // serviced after the passes

    void clear()
    {
        passes.clear();
        uploads.clear();
        readbacks.clear();
    }

    [[nodiscard]] size_t packetCount() const
    {
        size_t n = 0;
        for (const auto& pass : passes)
            n += pass.packets.size();
        return n;
    }
};
