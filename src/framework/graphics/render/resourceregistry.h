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

#include "renderdeclarations.h"

#include <framework/graphics/declarations.h>

#include <shared_mutex>
#include <unordered_map>

class Texture;
class FrameBuffer;

/*
 * ResourceRegistry - the handle -> native-object mapping.
 *
 * A DrawPacket names its texture and its target by logical handle, because native ids may not
 * cross the renderer boundary. Something below the boundary has to turn those numbers back
 * into objects, and this is it.
 *
 * Phase 2 minted handles WITHOUT allocating them - a texture's handle is its process-wide
 * unique id, a target's is a pure function of (pool type, nesting depth) - and that
 * determinism is what makes compiled output byte-identical across runs, threads and
 * platforms. So this registry deliberately does NOT allocate: it only resolves. The design
 * document's `ResourceRegistry` had both jobs; allocation turned out to be the wrong half.
 *
 * The two planes have different threading rules, on purpose:
 *
 *  - TEXTURES are registered by `Texture` itself, from whichever thread constructed it, and
 *    resolved on the render thread. Guarded by a shared_mutex: registration is rare relative
 *    to lookup, and lookups are read-only and uncontended.
 *
 *  - TARGETS are refreshed by the frame runner each frame and resolved in the same frame, both
 *    on the render thread. No lock, because nothing else may touch them - asserted by
 *    convention rather than by a mutex we would pay for on every packet.
 *
 * What the registry does NOT do is own anything. `Texture` and `FrameBuffer` still own their
 * GL objects during the migration, and a Phase 4 Metal backend is expected to grow the
 * ownership and deferred-destruction half here rather than in the frame vocabulary.
 */
class ResourceRegistry
{
public:
    static ResourceRegistry& instance();

    // --- texture plane (any thread) ------------------------------------------------------
    void registerTexture(Texture* texture);
    void unregisterTexture(uint32_t uniqueId);

    // Null when the handle names no live texture: a render-target texture (which lives in the
    // target plane instead), or one destroyed between compilation and rendering.
    [[nodiscard]] Texture* resolveTexture(TextureHandle handle) const;

    // --- target plane (render thread only) -----------------------------------------------
    void bindTarget(RenderTargetHandle handle, FrameBuffer* target);
    void clearTargets();
    [[nodiscard]] FrameBuffer* resolveTarget(RenderTargetHandle handle) const;

    [[nodiscard]] size_t textureCount() const;

private:
    mutable std::shared_mutex m_textureMutex;
    std::unordered_map<uint32_t, Texture*> m_textures;

    std::unordered_map<uint32_t, FrameBuffer*> m_targets;
};
