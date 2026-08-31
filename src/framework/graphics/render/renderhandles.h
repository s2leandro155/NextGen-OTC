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

#include "renderframe.h"

#include <framework/graphics/texture.h>

/*
 * Handle spaces.
 *
 * Every handle the compiler mints is a pure function of (pool type, nesting depth) or of a
 * Texture's process-wide unique id. Nothing is allocated from a shared counter, which is what
 * makes compiled output DETERMINISTIC: the same object list compiles to byte-identical passes
 * on any thread, on any platform, in any run. The golden-frame tests depend on that, and so
 * does using a recorded frame to decide whether a GL-versus-Metal difference lives above or
 * below the boundary.
 *
 * The texture-handle layout exploits an existing invariant rather than inventing one.
 * Texture's unique-id counter starts at UINT16_MAX - originally offset "just to avoid
 * conflicts with GL generated ID" - which leaves 1..UINT16_MAX-1 permanently free.
 * Render-target textures live there, and a static_assert below ties the two constants
 * together so that lowering the seed is a compile error rather than a silent aliasing bug.
 */
namespace RenderHandles
{
    // --- render targets ---------------------------------------------------------------
    // 0 is the backbuffer (RenderTargetHandle::BACKBUFFER).
    inline constexpr uint32_t POOL_TARGET_BASE = 1;
    inline constexpr uint32_t TRANSIENT_TARGET_BASE = 64;
    inline constexpr uint32_t TRANSIENT_TARGETS_PER_POOL = 16;

    // Atlas layer targets. A CPU atlas is a stack of layer framebuffers per filter group, and
    // new sprites are composited into them by GPU draw - so a layer is a render target like any
    // other, and the only reason it was not one before is that the compiler never described the
    // maintenance work. It is a THIRD kind of target rather than a variant of the other two
    // because it is keyed on (atlas, filter group, layer) and outlives every pool.
    inline constexpr uint32_t ATLAS_TARGET_BASE = 256;
    inline constexpr uint32_t ATLAS_FILTER_GROUPS = 2;  // nearest, linear - AtlasFilter's two
    inline constexpr uint32_t ATLAS_LAYERS_PER_GROUP = 32;

    // A pool's own retained target (MAP and FOREGROUND are the only pools that have one).
    [[nodiscard]] constexpr RenderTargetHandle poolTarget(const DrawPoolType type)
    {
        return RenderTargetHandle{ POOL_TARGET_BASE + static_cast<uint32_t>(type) };
    }

    // A temporary target, pooled BY NESTING DEPTH exactly as the GL path pools its temporary
    // framebuffers - getTemporaryFrameBuffer indexes on the bind counter, not on the call site.
    [[nodiscard]] constexpr RenderTargetHandle transientTarget(const DrawPoolType type, const uint32_t depth)
    {
        return RenderTargetHandle{ TRANSIENT_TARGET_BASE
                                   + static_cast<uint32_t>(type) * TRANSIENT_TARGETS_PER_POOL
                                   + depth };
    }

    // One layer of one filter group of one atlas. `smooth` selects the linear-filtered group,
    // which is the one that carries SMOOTH_PADDING; the two groups are separate layer stacks
    // and their indices are independent, hence the group in the key rather than a flat layer id.
    [[nodiscard]] constexpr RenderTargetHandle atlasTarget(const Fw::TextureAtlasType atlas,
                                                           const bool smooth, const uint32_t layer)
    {
        return RenderTargetHandle{ ATLAS_TARGET_BASE
                                   + ((static_cast<uint32_t>(atlas) * ATLAS_FILTER_GROUPS)
                                      + (smooth ? 1u : 0u)) * ATLAS_LAYERS_PER_GROUP
                                   + layer };
    }

    // --- textures ---------------------------------------------------------------------
    // The texture a render target resolves to when a later packet samples it. Same numbering
    // as the target itself, which keeps a recorded frame readable.
    inline constexpr uint32_t RENDER_TARGET_TEXTURE_LIMIT = 0xFFFF;

    // The invariant, actually enforced rather than merely described: every real Texture's
    // unique id starts at or above the limit, so no render-target handle can ever name one.
    static_assert(TEXTURE_UNIQUE_ID_SEED >= RENDER_TARGET_TEXTURE_LIMIT,
                  "Texture unique ids would alias render-target texture handles");

    [[nodiscard]] constexpr TextureHandle targetTexture(const RenderTargetHandle target)
    {
        return TextureHandle{ target.id };
    }

    [[nodiscard]] constexpr bool isRenderTargetTexture(const TextureHandle h)
    {
        return h.id != 0 && h.id < RENDER_TARGET_TEXTURE_LIMIT;
    }

    // --- decoding ---------------------------------------------------------------------
    // The inverse of the minting functions above. A backend gets a handle and has to find the
    // object it names, and since the encoding is arithmetic rather than a lookup, so is the
    // decoding. Kept here beside the encoders so the two can never drift apart.

    [[nodiscard]] constexpr bool isPoolTarget(const RenderTargetHandle h)
    {
        return h.id >= POOL_TARGET_BASE && h.id < TRANSIENT_TARGET_BASE;
    }

    [[nodiscard]] constexpr bool isTransientTarget(const RenderTargetHandle h)
    {
        return h.id >= TRANSIENT_TARGET_BASE
            && h.id < TRANSIENT_TARGET_BASE
                          + static_cast<uint32_t>(DrawPoolType::LAST) * TRANSIENT_TARGETS_PER_POOL;
    }

    inline constexpr uint32_t ATLAS_TARGET_LIMIT =
        ATLAS_TARGET_BASE
        + static_cast<uint32_t>(Fw::TextureAtlasType::LAST) * ATLAS_FILTER_GROUPS * ATLAS_LAYERS_PER_GROUP;

    [[nodiscard]] constexpr bool isAtlasTarget(const RenderTargetHandle h)
    {
        return h.id >= ATLAS_TARGET_BASE && h.id < ATLAS_TARGET_LIMIT;
    }

    // Valid only when isPoolTarget(h) or isTransientTarget(h).
    [[nodiscard]] constexpr DrawPoolType poolOf(const RenderTargetHandle h)
    {
        if (isTransientTarget(h))
            return static_cast<DrawPoolType>((h.id - TRANSIENT_TARGET_BASE) / TRANSIENT_TARGETS_PER_POOL);

        return static_cast<DrawPoolType>(h.id - POOL_TARGET_BASE);
    }

    // Valid only when isTransientTarget(h). This is the nesting depth the GL path indexes its
    // temporary framebuffer vector with, which is why the two stay interchangeable.
    [[nodiscard]] constexpr uint32_t transientDepthOf(const RenderTargetHandle h)
    {
        return (h.id - TRANSIENT_TARGET_BASE) % TRANSIENT_TARGETS_PER_POOL;
    }

    static_assert(isPoolTarget(poolTarget(DrawPoolType::MAP)));
    static_assert(!isTransientTarget(poolTarget(DrawPoolType::MAP)));
    static_assert(poolOf(poolTarget(DrawPoolType::FOREGROUND)) == DrawPoolType::FOREGROUND);
    static_assert(isTransientTarget(transientTarget(DrawPoolType::FOREGROUND, 3)));
    static_assert(poolOf(transientTarget(DrawPoolType::FOREGROUND, 3)) == DrawPoolType::FOREGROUND);
    static_assert(transientDepthOf(transientTarget(DrawPoolType::FOREGROUND, 3)) == 3);

    // The three target ranges must not overlap, and none of them may reach the texture-handle
    // space - a target's texture handle IS its target id, so an atlas layer aliasing a sprite's
    // unique id would silently sample the wrong thing.
    static_assert(ATLAS_TARGET_BASE >= TRANSIENT_TARGET_BASE
                      + static_cast<uint32_t>(DrawPoolType::LAST) * TRANSIENT_TARGETS_PER_POOL,
                  "atlas target handles overlap the transient target range");
    static_assert(ATLAS_TARGET_LIMIT <= RENDER_TARGET_TEXTURE_LIMIT,
                  "atlas target handles reach into the Texture unique-id space");

    static_assert(isAtlasTarget(atlasTarget(Fw::TextureAtlasType::MAP, false, 0)));
    static_assert(isAtlasTarget(atlasTarget(Fw::TextureAtlasType::FOREGROUND, true, 31)));
    static_assert(!isAtlasTarget(poolTarget(DrawPoolType::MAP)));
    static_assert(!isAtlasTarget(transientTarget(DrawPoolType::FOREGROUND, 3)));
    static_assert(!isPoolTarget(atlasTarget(Fw::TextureAtlasType::MAP, false, 0)));
    static_assert(!isTransientTarget(atlasTarget(Fw::TextureAtlasType::MAP, false, 0)));
    // The four (atlas, filter) groups are genuinely distinct, which the arithmetic above makes
    // easy to get wrong by one multiplication.
    static_assert(atlasTarget(Fw::TextureAtlasType::MAP, false, 0)
                  != atlasTarget(Fw::TextureAtlasType::MAP, true, 0));
    static_assert(atlasTarget(Fw::TextureAtlasType::MAP, true, 0)
                  != atlasTarget(Fw::TextureAtlasType::FOREGROUND, false, 0));
}
