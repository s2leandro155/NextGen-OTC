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

#include "framebuffer.h"
#include "glutil.h"

#include "graphics.h"
#include "image.h"
#include "painter.h"
#include "framework/core/asyncdispatcher.h"
#include "framework/core/eventdispatcher.h"
#include "framework/core/graphicalapplication.h"
#include <framework/platform/platformwindow.h>

uint32_t FrameBuffer::boundFbo = 0;

FrameBuffer::FrameBuffer()
{
    // Pure Vulkan mode: glGenFramebuffers is nullptr (GLEW without a context). The framebuffer
    // lives as an empty object - the GL drawing path that would touch it does not execute.
    if (!g_window.hasGLContext())
        return;

    glGenFramebuffers(1, &m_fbo);
    if (!m_fbo)
        g_logger.warning("Unable to create framebuffer object");
}

FrameBuffer::~FrameBuffer()
{
#ifndef NDEBUG
    assert(!g_app.isTerminated());
#endif
    if (g_graphics.ok() && m_fbo != 0) {
        g_mainDispatcher.addEvent([id = m_fbo] {
            glDeleteFramebuffers(1, &id);
        });
    }
}

bool FrameBuffer::resize(const Size& size, const float contentScale)
{
    assert(size.isValid());

    const float scale = contentScale > 0.f ? contentScale : 1.f;
    const Size logical = scale == 1.f
        ? size
        : Size(std::max<int>(1, static_cast<int>(size.width() / scale)),
               std::max<int>(1, static_cast<int>(size.height() / scale)));

    if (m_texture && m_texture->getSize() == size && m_contentScale == scale)
        return false;

    m_contentScale = scale;
    m_logicalSize = logical;

    m_texture = std::make_shared<Texture>(size);
    m_texture->setSmooth(m_smooth);
    m_texture->setUpsideDown(true);
    // The projection spans the LOGICAL extent while the viewport covers the whole device-pixel
    // texture, so geometry recorded in logical units rasterises across every physical pixel.
    m_textureMatrix = g_painter->getTransformMatrix(logical);

    m_screenCoordsBuffer.clear();
    m_screenCoordsBuffer.addRect(Rect{ 0, 0, logical });

    // Pure Vulkan mode: without a context we do not attach the texture to the FBO (m_fbo == 0).
    if (!g_window.hasGLContext())
        return true;

    internalBind();
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, m_texture->getId(), 0);

    const GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE)
        g_logger.warning("Unable to setup framebuffer object");
    else {
        // Texture::setupPixels allocates with a null data pointer, so a newly attached texture holds
        // whatever happened to be in that memory. Anything sampling it before the pool has drawn a
        // full frame into it - a resize still in flight, or a linear filter reaching a texel past
        // the drawn region - reads uninitialised bytes and paints them on screen as coloured
        // streaks. Start it defined; the worst a transient can then look is empty.
        // glClear obeys the scissor test, which Painter leaves enabled while clipping.
        const auto scissorWasEnabled = glIsEnabled(GL_SCISSOR_TEST);
        if (scissorWasEnabled)
            glDisable(GL_SCISSOR_TEST);

        glClearColor(0.f, 0.f, 0.f, 0.f);
        glClear(GL_COLOR_BUFFER_BIT);

        if (scissorWasEnabled)
            glEnable(GL_SCISSOR_TEST);
    }

    internalRelease();

    return true;
}

void FrameBuffer::bind()
{
    internalBind();

    if (m_isScene) {
        g_painter->resetState();
    }

    m_oldSize = g_painter->getResolution();
    m_oldTextureMatrix = g_painter->getProjectionMatrix();

    g_painter->setResolution(getSize(), m_textureMatrix);
    g_painter->setAlphaWriting(m_useAlphaWriting);

    if (m_autoClear) {
        if (m_colorClear != Color::alpha) {
            g_painter->resetTexture();
            g_painter->setColor(m_colorClear);
            g_painter->drawCoords(m_screenCoordsBuffer, DrawMode::TRIANGLE_STRIP);
        } else {
            g_painter->clear(Color::alpha);
        }
    }
}

bool FrameBuffer::canDraw() const {
    return m_texture && m_coordsBuffer.getVertexCount() > 0;
}

void FrameBuffer::release() const
{
    internalRelease();
    g_painter->setResolution(m_oldSize, m_oldTextureMatrix);
}

void FrameBuffer::draw()
{
    if (m_disableBlend) glDisable(GL_BLEND);
    g_painter->setCompositionMode(m_compositeMode);
    g_painter->setTexture(m_texture);
    g_painter->drawCoords(m_coordsBuffer, DrawMode::TRIANGLE_STRIP);
    g_painter->resetCompositionMode();
    if (m_disableBlend) glEnable(GL_BLEND);
}

void FrameBuffer::bindAsTarget()
{
    internalBind();

    m_oldSize = g_painter->getResolution();
    m_oldTextureMatrix = g_painter->getProjectionMatrix();

    g_painter->setResolution(getSize(), m_textureMatrix);
}

void FrameBuffer::releaseAsTarget() const
{
    internalRelease();
    g_painter->setResolution(m_oldSize, m_oldTextureMatrix);
}

void FrameBuffer::drawClearQuad(const Color& color)
{
    g_painter->resetTexture();
    g_painter->setColor(color);
    g_painter->drawCoords(m_screenCoordsBuffer, DrawMode::TRIANGLE_STRIP);
}

void FrameBuffer::internalBind()
{
    assert(boundFbo != m_fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, m_fbo);
    m_prevBoundFbo = boundFbo;
    boundFbo = m_fbo;
}

void FrameBuffer::internalRelease() const
{
    assert(boundFbo == m_fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, m_prevBoundFbo);
    boundFbo = m_prevBoundFbo;
}

void FrameBuffer::prepare(const Rect& dest, const Rect& src, const Color& colorClear, uint8_t flipDirection)
{
    const auto& _dest = dest.isValid() ? dest : Rect(0, 0, getSize());
    const auto& _src = src.isValid() ? src : Rect(0, 0, getSize());

    if (m_colorClear != colorClear)
        m_colorClear = colorClear;

    m_coordsBuffer.clear();
    // 0 = none, 1 = horizontal, 2 = vertical
    if (flipDirection == 1) {
        m_coordsBuffer.addHorizontallyFlippedQuad(_dest, _src);
    } else if (flipDirection == 2) {
        m_coordsBuffer.addVerticallyFlippedQuad(_dest, _src);
    } else {
        m_coordsBuffer.addQuad(_dest, _src);
    }
}

Size FrameBuffer::getSize()
{
    return m_texture->getSize();
}

TexturePtr FrameBuffer::extractTexture() {
    internalBind();
    const auto& size = getSize();
    const int width = size.width();
    const int height = size.height();
    const auto& pixels = std::make_shared<std::vector<uint8_t>>(width * height * 4 * sizeof(GLubyte), 0);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels->data());
    internalRelease();

    const auto& texture = std::make_shared<Texture>(std::make_shared<Image>(getSize(), 4, pixels->data()));
    texture->setUpsideDown(true);

    return texture;
}

void FrameBuffer::doScreenshot(std::string file, const uint16_t x, const uint16_t y)
{
    if (file.empty()) {
        return;
    }

    g_mainDispatcher.addEvent([this, file, x, y] {
        internalBind();

        Size size = getSize();
        size.setWidth(size.width() - x);
        size.setHeight(size.height() - y);

        const int width = size.width();
        const int height = size.height();
        const auto& pixels = std::make_shared<std::vector<uint8_t>>(width * height * 4 * sizeof(GLubyte), 0);

        glReadPixels(x / 3, y / 1.5, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels->data());

        internalRelease();

        g_asyncDispatcher.detach_task([size, pixels, file] {
            try {
                Image image(size, 4, pixels->data());
                image.flipVertically();
                image.setOpacity(255);
                image.savePNG(file);
            } catch (stdext::exception& e) {
                g_logger.error(std::string("Can't do map screenshot: ") + e.what());
            }
        });
    });
}
