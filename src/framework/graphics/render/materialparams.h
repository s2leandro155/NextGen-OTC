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

#include <cstddef>
#include <cstdint>

/*
 * MaterialParams - the FROZEN shader parameter ABI.
 *
 * This replaces the legacy scheme of per-location uniform uploads addressed by integer
 * index. That scheme had a real defect baked into it: the framework reserved index 10 for
 * the transform matrix while the client extension reserved the same index 10 for u_ItemId,
 * so a shader binding an item id would have had its uniform aliased by a matrix written on
 * every single draw. The collision dies here by construction, because this ABI has no
 * shared index space at all - only named fields at fixed offsets.
 *
 * Freezing it now is what unblocks the Phase 6 toolchain: the GLSL -> SPIR-V -> MSL step
 * needs a stable block layout to generate a matching header for, and the GL backend needs
 * a stable mapping onto the legacy uniform locations so that existing .frag sources keep
 * compiling unmodified.
 *
 * LAYOUT IS std140 AND IS PART OF THE CONTRACT. The static_asserts at the bottom are the
 * enforcement: scalars first, then 8-byte-aligned pairs, block stride a multiple of 16.
 * Reordering or inserting a field without updating them is a compile error, deliberately.
 *
 * The offsets are the ones a NATURALLY WRITTEN GLSL block produces - six floats followed by
 * six vec2 - so the Phase 6 toolchain does not have to emit a padding member to match.
 * One rule for whoever writes that block: the tail padding must never be spelled as a float
 * array on the GLSL side, because a std140 float array has a 16-byte element stride.
 *
 * A note on the design document's sketch: it wrote these fields as `Size`, `Point` and
 * `PointF`. Size and Point are INTEGER types in this codebase (TSize<int>, TPoint<int>), and
 * an integer cannot sit in a std140 float block, so the fields are plain floats here. The
 * intent is unchanged; only the spelling is implementable.
 *
 * WHICH FIELDS ARE ACTUALLY DRIVEN TODAY (measured, not assumed):
 *   - `time` and the two texture samplers are the workhorses: 19 of the 24 shipped .frag
 *     files read u_Time.
 *   - `walkOffset` (4 files) and `resolution` (3 files) are read by shipped shaders.
 *   - `mapZoom`, `mapCenterCoord` and `mapGlobalCoord` are WRITTEN by MapView every frame a
 *     map shader is bound, but no shipped .frag reads them.
 *   - `itemId`, `outfitId`, `mountId`, `shaderId`, `textOffset` and `textCenter` are dead on
 *     both sides: every bind site in the client is commented out, and no shipped shader
 *     references them.
 * They are all kept because the ABI is a published contract for out-of-repo module authors,
 * and because the whole block costs 80 bytes per material per frame.
 */

 // std140 gives a two-float vector 8-byte alignment. Spelling that out in the type keeps the
 // layout correct by construction rather than by comment.
struct alignas(8) ParamVec2
{
    float x{ 0.f };
    float y{ 0.f };

    constexpr bool operator==(const ParamVec2&) const = default;
};

struct MaterialParams
{
    // --- scalars ---------------------------------------------------------------------
    // Frame-global, NOT per-material: the frame assembler supplies one value to every
    // material at once. It must keep honouring the process-wide pin (g_shaders.setFixedTime),
    // because pinning the phase is the only reason an animated shader frame is reproducible -
    // every renderer baseline depends on it, and so does any GL-versus-Metal comparison.
    float time{ 0.f };

    float mapZoom{ 0.f };
    float itemId{ 0.f };
    float outfitId{ 0.f };
    float mountId{ 0.f };
    float shaderId{ 0.f };

    // --- two-component pairs ---------------------------------------------------------
    // No padding is needed here: six floats end at offset 24, which is already the 8-byte
    // alignment a std140 vec2 requires. An earlier version inserted two floats of padding on
    // the theory that it was needed; it was not, and it pushed every pair 8 bytes past where
    // a naturally-written GLSL block puts them.
    ParamVec2 resolution{};
    ParamVec2 walkOffset{};
    ParamVec2 mapCenterCoord{};
    ParamVec2 mapGlobalCoord{};
    ParamVec2 textOffset{};
    ParamVec2 textCenter{};

    // Trailing pad to the std140 BLOCK STRIDE. The members occupy 72 bytes; std140 rounds a
    // block up to a multiple of 16, so the C++ type is padded to match and an array of them
    // has the same stride the GPU expects.
    float _tailPadding[2]{};

    constexpr bool operator==(const MaterialParams&) const = default;
};

static_assert(sizeof(ParamVec2) == 8);
static_assert(alignof(ParamVec2) == 8);

static_assert(offsetof(MaterialParams, time) == 0);
static_assert(offsetof(MaterialParams, mapZoom) == 4);
static_assert(offsetof(MaterialParams, itemId) == 8);
static_assert(offsetof(MaterialParams, outfitId) == 12);
static_assert(offsetof(MaterialParams, mountId) == 16);
static_assert(offsetof(MaterialParams, shaderId) == 20);
static_assert(offsetof(MaterialParams, resolution) == 24);
static_assert(offsetof(MaterialParams, walkOffset) == 32);
static_assert(offsetof(MaterialParams, mapCenterCoord) == 40);
static_assert(offsetof(MaterialParams, mapGlobalCoord) == 48);
static_assert(offsetof(MaterialParams, textOffset) == 56);
static_assert(offsetof(MaterialParams, textCenter) == 64);
static_assert(sizeof(MaterialParams) == 80, "std140 block size is part of the frozen ABI");
static_assert(sizeof(MaterialParams) % 16 == 0, "std140 requires a 16-byte multiple");
