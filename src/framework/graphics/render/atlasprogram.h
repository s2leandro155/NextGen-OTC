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

#include <framework/graphics/declarations.h>
#include <vector>

/*
 * AtlasProgram - one CPU texture atlas's pending maintenance, compiled.
 *
 * The atlas packs new sprites into shelf space on a producer thread, but getting their pixels
 * INTO the layer is a GPU draw: bind the layer, blend off, clear the shelf rect, draw the
 * source into it (with an oversized padding draw first for the linear-filtered group). The GL
 * path did that inline in `TextureAtlas::flush`, through `g_painter` and two raw
 * `glDisable(GL_BLEND)` calls, which is the last piece of frame work that was not describable.
 *
 * This is that work as ordinary passes and packets. It is a separate program rather than part
 * of a `PoolProgram` for the reason Phase 2 discovered and Phase 3 recorded: an atlas's pending
 * list is filled on the RENDER thread while the frame is drawn, so at `DrawPool::release()`
 * time - the producer thread, where a pool is compiled - there is nothing yet to compile. An
 * atlas is also shared by several pools (all three foreground pools share one), so it does not
 * belong to any single pool's program even in principle.
 *
 * Lifetime: the program is owned by its atlas and rebuilt once per frame, so its passes stay
 * valid for exactly as long as the frame that references them.
 */
struct AtlasProgram
{
    AtlasProgram() = default;
    AtlasProgram(const AtlasProgram&) = delete;
    AtlasProgram& operator=(const AtlasProgram&) = delete;
    AtlasProgram(AtlasProgram&&) = delete;
    AtlasProgram& operator=(AtlasProgram&&) = delete;

    VertexArena arena;

    // One pass per dirty layer, each `Keep`-loaded: atlas layers ACCUMULATE across frames
    // (their framebuffers are created with autoClear=false), so a clear here would erase every
    // sprite packed in every previous frame.
    std::vector<RenderPass> passes;

    // The source textures these passes sample, pinned until the frame has been submitted.
    //
    // This is the one thing the GL path got for free and a compiled frame does not. `flush()`
    // ran the draw immediately, so the caller's reference was still on the stack; here the
    // packets are handed to a backend later, and an `AtlasRegion` deliberately holds no
    // reference of its own - regions outlive the textures that occupy them and are recycled.
    std::vector<TexturePtr> sources;

    [[nodiscard]] bool isEmpty() const { return passes.empty(); }

    void clear()
    {
        arena.clear();
        passes.clear();
        sources.clear();
    }

    // Same reason as PoolProgram::bindArena: the arena grows while the passes are being built,
    // so the pointers are fixed up once at the end rather than cached through a reallocation.
    void bindArena()
    {
        for (auto& pass : passes)
            pass.arena = &arena;
    }
};
