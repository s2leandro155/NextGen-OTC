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

#include <cstdint>
#include <vector>

/*
 * IRenderBackend - the consumer side of the renderer boundary.
 *
 * A backend receives a RenderFrame and produces pixels. It is told WHAT to draw and decides
 * HOW; it knows nothing about pools, widgets, map floors or Lua, and nothing above it knows
 * about GL, Vulkan or Metal.
 *
 * WHAT THIS INTERFACE DELIBERATELY OMITS. The design document sketched a resource plane here
 * too - createTexture / updateTexture / destroyTexture / createRenderTarget / createMaterial -
 * modelled on a backend that owns its native objects. That is the right shape for Metal and
 * the wrong shape for the first backend to exist, because during the migration `Texture`,
 * `FrameBuffer` and `PainterShaderProgram` still own theirs. Declaring six virtuals whose only
 * implementation would forward to objects the backend does not own is how you get an interface
 * specified against an imagined renderer - the exact failure Phase 2 refused for
 * `ResourceRegistry`. Handle resolution lives in `ResourceRegistry` instead, which is real and
 * used; ownership and deferred destruction arrive with the backend that needs them.
 *
 * `readPixels` is here rather than in the frame because a readback has a result, and a frame
 * is a one-way description. `RenderFrame::readbacks` states the request; this delivers it.
 */

// A completed readback. Always top-left origin and RGBA8, whatever the backend's own storage
// convention is - the backend flips, never the caller.
struct ReadbackResult
{
    Size size;
    std::vector<uint8_t> pixels; // RGBA8, size.area() * 4 bytes
    bool ok{ false };
};

class IRenderBackend
{
public:
    virtual ~IRenderBackend() = default;

    // Called once the platform surface exists. False means this backend cannot run here and
    // the caller must choose another; it must leave nothing half-initialised behind.
    virtual bool initialize() = 0;
    virtual void shutdown() = 0;

    // Drawable size in PIXELS, not points. The platform layer already reports backing pixels.
    virtual void resize(const Size& drawableSize) = 0;

    // Encode and submit one frame. Presentation is NOT part of this on the GL path: the window
    // still owns swapBuffers. Phase 4 has to settle that for Metal, where CocoaWindow presents
    // its own frames today.
    virtual bool render(const RenderFrame& frame) = 0;

    virtual bool readPixels(const ReadbackRequest& request, ReadbackResult& out) = 0;

    [[nodiscard]] virtual const char* name() const = 0;
};
