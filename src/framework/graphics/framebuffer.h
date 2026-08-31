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

#include "coordsbuffer.h"
#include "declarations.h"
#include "texture.h"

class FrameBuffer
{
public:
    FrameBuffer();
    ~FrameBuffer();

    void release() const;
    void bind();
    void draw();
    void draw(const Rect& dest) { prepare(dest, Rect(0, 0, getSize())); draw(); }
    void draw(const Rect& dest, uint8_t flipDirection) { prepare(dest, Rect(0, 0, getSize()), Color::alpha, flipDirection); draw(); }

    void reset() { m_texture = nullptr; }
    void setSmooth(const bool enabled) { m_smooth = enabled; m_texture = nullptr; }

    // `size` is the target's size in DEVICE pixels. `contentScale` is how many device pixels
    // one unit of the target's coordinate space is worth: the texture is allocated at `size`,
    // while geometry, the projection and clip rects stay in `size / contentScale` units. That
    // is what lets the UI keep laying out in logical units while rasterising at native
    // resolution, instead of compositing at 1x into a half-size target and upscaling it.
    bool resize(const Size& size, float contentScale = 1.f);
    bool isValid() const { return m_texture != nullptr; }
    bool canDraw() const;
    bool isAutoClear() const { return m_autoClear; }
    void setAutoClear(bool v) { m_autoClear = v; }
    void setAlphaWriting(bool v) { m_useAlphaWriting = v; }
    void setAutoResetState(bool v) { m_isScene = v; }

    TexturePtr getTexture() const { return m_texture; }
    TexturePtr extractTexture();

    Size getSize() const { return m_texture->getSize(); }

    // The coordinate space geometry and clip rects are expressed in. Equal to getSize() unless
    // this target rasterises at a higher resolution than it is addressed in.
    Size getLogicalSize() const { return m_logicalSize.isValid() ? m_logicalSize : getSize(); }
    float getContentScale() const { return m_contentScale; }

    void setCompositionMode(const CompositionMode mode) { m_compositeMode = mode; }
    void disableBlend() { m_disableBlend = true; }

    // Read-only view of the composition state a frame compiler needs to describe this
    // target's blit. Previously only reachable through friendship with DrawPool.
    CompositionMode getCompositionMode() const { return m_compositeMode; }
    bool isBlendDisabled() const { return m_disableBlend; }
    bool hasAlphaWriting() const { return m_useAlphaWriting; }

    void doScreenshot(std::string file, uint16_t x = 0, uint16_t y = 0);
    Size getSize();

    // --- explicit render-pass access -----------------------------------------------------
    // bind() folds five decisions into one call: bind the FBO, maybe reset painter state,
    // repoint the painter at this target, set alpha writing from this object, and maybe clear
    // using a colour this object is carrying. A compiled render pass states all of those
    // itself, per pass and per packet, so it needs the pieces separately rather than the
    // policy. These three are verbatim slices of bind()/release(); no new behaviour.
    void bindAsTarget();
    void releaseAsTarget() const;

    // The non-transparent half of bind()'s clear: a full-target quad in the current blend
    // state, rather than a glClear. Kept as a draw because that is what it is - it blends,
    // and it honours the colour mask.
    void drawClearQuad(const Color& color);

protected:
    Color m_colorClear{ Color::alpha };

    friend class FrameBufferManager;
    friend class DrawPoolManager;
    friend class DrawPool;

private:
    static uint32_t boundFbo;

    void internalBind();
    void internalRelease() const;
    void prepare(const Rect& dest, const Rect& src, const Color& colorClear = Color::alpha, uint8_t flipDirection = 0);

    Size m_oldSize;

    Matrix3 m_textureMatrix, m_oldTextureMatrix;
    Size m_logicalSize;
    float m_contentScale{ 1.f };
    TexturePtr m_texture;

    uint32_t m_fbo{ 0 };
    uint32_t m_prevBoundFbo{ 0 };

    CompositionMode m_compositeMode{ CompositionMode::NORMAL };

    bool m_smooth{ true };
    bool m_useAlphaWriting{ true };
    bool m_disableBlend{ false };
    bool m_isScene{ false };
    bool m_autoClear{ true };

    Rect m_dest;
    Rect m_src;

    CoordsBuffer m_coordsBuffer;
    CoordsBuffer m_screenCoordsBuffer;
};
