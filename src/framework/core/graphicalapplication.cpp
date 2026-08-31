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

#include "graphicalapplication.h"
#include <framework/graphics/glutil.h>

#include "asyncdispatcher.h"
#include "clock.h"
#include "eventdispatcher.h"
#include "garbagecollection.h"
#include "framework/graphics/drawpoolmanager.h"
#include "framework/graphics/graphics.h"
#include "framework/graphics/image.h"
#include "framework/graphics/particlemanager.h"
#include "framework/graphics/texture.h"
#include "framework/graphics/texturemanager.h"
#include "framework/input/mouse.h"
#include "framework/ui/uimanager.h"
#include <framework/util/stats.h>
#include <framework/util/profiler.h>
#include <framework/core/configmanager.h>

#ifdef FRAMEWORK_SOUND
#include <framework/sound/soundmanager.h>
#endif

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif
#include <framework/html/htmlmanager.h>
#include <framework/platform/platformwindow.h>

#ifdef WIN32
// The Vulkan surface exists only for Win32 for now, so the frame loop comes into
// play only there - the remaining platforms compile exactly as before.
#include <framework/graphics/vulkan/vkcontext.h>
#include <framework/graphics/vulkan/vkfeeder.h>
#endif

GraphicalApplication g_app;

void GraphicalApplication::init(std::vector<std::string>& args, ApplicationContext* context)
{
    Application::init(args, context);

    auto graphicalContext = static_cast<GraphicalApplicationContext*>(context);
    setDrawEvents(graphicalContext->getDrawEvents());

    // setup platform window
    g_window.init();
    g_window.hide();

    // set the window title color
    g_window.setTitleBarColor(Color::black);

    g_window.setOnResize([this](auto&& PH1) {
        if (!m_running) resize(PH1);
        else g_dispatcher.addEvent([&, PH1] { resize(PH1); });
    });

    g_window.setOnInputEvent([this](auto&& PH1) {
        if (!m_running) inputEvent(PH1);
        else g_dispatcher.addEvent([&, PH1] { inputEvent(PH1); });
    });

    g_window.setOnClose([this] { g_dispatcher.addEvent([this] { close(); }); });

    g_mouse.init();

    // initialize ui
    g_ui.init();

    // initialize graphics
    g_graphics.init();
    g_drawPool.init(graphicalContext->getSpriteSize());

    // fire first resize event
    resize(g_window.getSize());

#ifdef FRAMEWORK_SOUND
    // initialize sound
    g_sounds.init();
#endif

    m_mapProcessFrameCounter.init();
    m_graphicFrameCounter.init();

}

void GraphicalApplication::deinit()
{
    // hide the window because there is no render anymore
    g_window.hide();

    Application::deinit();
}

void GraphicalApplication::terminate()
{
    // destroy particles
    g_particles.terminate();

    // destroy any remaining widget
    g_html.terminate();
    g_ui.terminate();

    Application::terminate();
    m_terminated = false;

#ifdef FRAMEWORK_SOUND
    // terminate sound
    g_sounds.terminate();
#endif

    g_mouse.terminate();

    // terminate graphics
    g_drawPool.terminate();
    g_graphics.terminate();
    g_window.terminate();

    m_terminated = true;
}

#ifdef __EMSCRIPTEN__
void GraphicalApplication::mainLoop() {
    if (m_stopping) {
        emscripten_cancel_main_loop();
        MAIN_THREAD_EM_ASM({ window.location.reload(); });
        return;
    }
    mainPoll();

    if (!g_window.isVisible()) {
        stdext::millisleep(10);
        return;
    }

    const auto FPS = [this] {
        // The map thread emitted tiles up to 500 times per second (and without vsync/FPS limit - with
        // no ceiling at all), even though the screen shows 60-144 frames. With a static scene DrawPool::release
        // throws all that work away anyway because the hash didn't change - so idling burned a whole core.
        // A ceiling of 2x the render FPS leaves headroom for smoothness and cuts CPU usage severalfold.
        const uint16_t graphicsFps = m_graphicFrameCounter.getFps();
        m_mapProcessFrameCounter.setTargetFps(std::clamp<uint16_t>(graphicsFps * 2, 60u, 240u));
        return graphicsFps;
    };

    {
        AUTO_STAT(STATS_RENDER, "DrawPool");
        g_drawPool.draw();
    }

    if (m_graphicFrameCounter.update()) {
        g_dispatcher.addEvent([this, fps = FPS()] {
            g_lua.callGlobalField("g_app", "onFps", fps);
        });
    }
}
#endif

bool GraphicalApplication::canDrawMap() const {
    using enum DrawPoolType;

    if (!m_drawEvents->canDraw(MAP))
        return false;

    static constexpr std::array<DrawPoolType, 3> types{ MAP, LIGHT, FOREGROUND_MAP };

    for (DrawPoolType type : types) {
        if (g_drawPool.isDrawing(type))
            return false;
    }
    return true;
}

void GraphicalApplication::run()
{
    // run the first poll
    mainPoll();
    poll();

    // show window
    g_window.show();

    // run the second poll
    mainPoll();
    poll();

    g_lua.callGlobalField("g_app", "onRun");

#ifndef __EMSCRIPTEN__
    const auto FPS = [this] {
        // The map thread emitted tiles up to 500 times per second (and without vsync/FPS limit - with
        // no ceiling at all), even though the screen shows 60-144 frames. With a static scene DrawPool::release
        // throws all that work away anyway because the hash didn't change - so idling burned a whole core.
        // A ceiling of 2x the render FPS leaves headroom for smoothness and cuts CPU usage severalfold.
        const uint16_t graphicsFps = m_graphicFrameCounter.getFps();
        m_mapProcessFrameCounter.setTargetFps(std::clamp<uint16_t>(graphicsFps * 2, 60u, 240u));
        return graphicsFps;
    };
#endif
    // THREAD - POOL & MAP
    const auto& mapThread = g_asyncDispatcher.submit_task([this] {
        BS::multi_future<void> tasks;

        g_luaThreadId = g_eventThreadId = stdext::getThreadId();
        while (!m_stopping) {
            poll();

            if (!g_window.isVisible()) {
                stdext::millisleep(10);
                continue;
            }

            const bool canDrawForeground = !g_drawPool.isDrawing(DrawPoolType::FOREGROUND) && m_drawEvents->canDraw(DrawPoolType::FOREGROUND);

            if (canDrawMap()) {
                if (canDrawForeground) {
                    tasks.emplace_back(g_asyncDispatcher.submit_task([] {
                        AUTO_STAT(STATS_RENDER, "DrawForegroundUI");
                        g_ui.render(DrawPoolType::FOREGROUND);
                    }));
                }

                {
                    AUTO_STAT(STATS_RENDER, "DrawPreload");
                    m_drawEvents->preLoad();
                }
                static constexpr std::array<DrawPoolType, 2> types{ DrawPoolType::LIGHT, DrawPoolType::FOREGROUND_MAP };
                for (const auto type : types) {
                    if (m_drawEvents->canDraw(type)) {
                        tasks.emplace_back(g_asyncDispatcher.submit_task([this, type] {
                            AUTO_STAT(STATS_RENDER, type == DrawPoolType::LIGHT ? "DrawLight" : "DrawForegroundMap");
                            m_drawEvents->draw(type);
                        }));
                    }
                }

                {
                    AUTO_STAT(STATS_RENDER, "DrawMap");
                    m_drawEvents->draw(DrawPoolType::MAP);
                }

                tasks.wait();
                tasks.clear();
            } else if (canDrawForeground) {
                AUTO_STAT(STATS_RENDER, "DrawForegroundUI");
                g_ui.render(DrawPoolType::FOREGROUND);
            }

            m_mapProcessFrameCounter.update();
        }
    });

#ifdef __EMSCRIPTEN__
    m_running = true;
    emscripten_set_main_loop(([] { g_app.mainLoop(); }), 0, 1);
#else
    m_running = true;
    while (!m_stopping) {
        mainPoll();

        if (!g_window.isVisible()) {
            stdext::millisleep(10);
            continue;
        }

#ifdef WIN32
        // Stage 4: with a working Vulkan batch the draw queue is NOT executed by
        // OpenGL - the feeder translates it into batch triangles, and GL gets no work at all
        // this frame. When the batch doesn't work (missing .spv etc.), the old pair remains: GL draws,
        // Vulkan only clears the screen and shows the fallback scene - then at least it's visibly alive.
        auto& vkCtx = VkContext::instance();
        const bool vkGameFrame = vkCtx.isReady() && vkCtx.getBatch().isReady();
#endif
        {
            AUTO_STAT(STATS_RENDER, "DrawPool");
#ifdef WIN32
            if (vkGameFrame)
                VkDrawFeeder::instance().feedFrame(vkCtx.getBatch(), vkCtx.getExtent());
            else if (g_window.hasGLContext())
                g_drawPool.draw();
            else {
                // Vulkan died mid-session and a GL context was never created (pure VK
                // mode) - there is nothing to draw with. We consume the pool flags so the map thread
                // doesn't jam (canDrawMap waits for consumption), and leave a frozen image
                // instead of a crash on null-GL.
                VkDrawFeeder::instance().consumeAllPools();
            }
#else
            // Whether there is a GL context to draw with is DrawPoolManager::draw's business,
            // not this loop's: a window that deliberately creates none - the Cocoa/Metal one -
            // runs the frame path there, and a frame that path declines consumes the pool flags
            // rather than diving into null GLEW pointers. Deciding it here as well would mean
            // two places had to agree about which renderer is live.
            g_drawPool.draw();
#endif
        }

        // update screen pixels
        {
            PROFILE_ZONE(Present);
            AUTO_STAT(STATS_RENDER, "SwapBuffers");

            // When the Vulkan context doesn't exist or dies along the way (drawFrame returns false
            // and shuts itself down), we immediately fall back to swapBuffers - and since the feeder
            // also stops being called then, the next frame goes entirely down the GL path.
            // Clear color: black under a game frame, navy under the fallback scene
            // (we can tell them apart with the naked eye).
#ifdef WIN32
            if (!vkCtx.isReady() || !vkCtx.drawFrame(vkGameFrame ? 0.0f : 0.05f,
                                                     vkGameFrame ? 0.0f : 0.10f,
                                                     vkGameFrame ? 0.0f : 0.25f)) {
                if (vkGameFrame) {
                    // The feeder consumed the pool flags and GL drew nothing this frame. Without
                    // forcing a repaint, the GL fallback would show framebuffers that nobody
                    // ever filled in Vulkan mode (black map until the hash changes).
                    for (int8_t i = -1; ++i < static_cast<int8_t>(DrawPoolType::LAST);)
                        g_drawPool.get(static_cast<DrawPoolType>(i))->repaint();
                }
                g_window.swapBuffers();
            }
#else
            g_window.swapBuffers();
#endif
        }

        // Counted here rather than in the frame counter, which is a pacing device and skips
        // ticks; the profiler needs the number of frames its samples were actually spread over.
        g_profiler.countFrame();
        g_profiler.poll();

        if (m_graphicFrameCounter.update()) {
            g_dispatcher.addEvent([this, fps = FPS()] {
                g_lua.callGlobalField("g_app", "onFps", fps);
            });
        }
    }
#endif
    mapThread.wait();

    m_running = false;
    m_stopping = false;

    g_luaThreadId = g_eventThreadId = -1;
}

void GraphicalApplication::poll()
{
    GarbageCollection::poll();

    Application::poll();

#ifdef FRAMEWORK_SOUND
    g_sounds.poll();
#endif

    g_particles.poll();

    if (!g_window.isVisible()) {
        g_textDispatcher.poll();
    }
}
void GraphicalApplication::mainPoll()
{
    PROFILE_ZONE(MainPoll);
    AUTO_STAT(STATS_MAIN, "MainPoll");
    {
        AUTO_STAT(STATS_MAIN, "ClockUpdate");
        g_clock.update();
    }
    {
        AUTO_STAT(STATS_MAIN, "DispatcherPoll");
        g_mainDispatcher.poll();
    }
    {
        // Batched deletion of GL textures collected by destructors from other threads.
        // Must be here: this is the only thread with an active OpenGL context, and the spot in the
        // frame is the same one where the individual deletion events used to execute.
        AUTO_STAT(STATS_MAIN, "TextureDeletion");
        Texture::flushDeletedTextures();
    }
    {
        AUTO_STAT(STATS_MAIN, "WindowPoll");
        g_window.poll();
    }
    {
        AUTO_STAT(STATS_MAIN, "TexturePoll");
        g_textures.poll();
    }
}

void GraphicalApplication::close()
{
    m_onInputEvent = true;
    Application::close();
    m_onInputEvent = false;
}

static constexpr bool USE_FRAMEBUFFER = false;
void GraphicalApplication::resize(const Size& size)
{
    const float scale = g_window.getDisplayDensity();
    g_graphics.resize(size);

    m_onInputEvent = true;
    g_ui.resize(size / scale);
    m_onInputEvent = false;

    // The UI lays out in logical units (above), but the target it composites into is sized in
    // DEVICE pixels and given the scale as its coordinate space. Sizing it logically and letting
    // UIManager::render blit it to the full physical viewport is what made the whole UI render at
    // 1x and get bilinearly upscaled on every Retina display.
    g_mainDispatcher.addEvent([size, scale] {
        g_drawPool.get(DrawPoolType::FOREGROUND)->setFramebuffer(size, scale);
    });
}

void GraphicalApplication::inputEvent(const InputEvent& event)
{
    m_onInputEvent = true;
    g_ui.inputEvent(event);
    m_onInputEvent = false;
}

bool GraphicalApplication::isLoadingAsyncTexture() { return m_loadingAsyncTexture || (m_drawEvents && m_drawEvents->isLoadingAsyncTexture()); }
bool GraphicalApplication::isScaled() { return g_window.getDisplayDensity() != 1.f; }
void GraphicalApplication::setLoadingAsyncTexture(bool v) {
    if (m_drawEvents && m_drawEvents->isUsingProtobuf())
        v = true;
    else if (isEncrypted())
        v = false;

    m_loadingAsyncTexture = v;

    if (m_drawEvents)
        m_drawEvents->onLoadingAsyncTextureChanged(v);
}

void GraphicalApplication::saveReadbackAsPng(ReadbackResult&& readback, std::string file)
{
    g_asyncDispatcher.detach_task([readback = std::move(readback), file = std::move(file)] {
        try {
            Image image(readback.size, 4, readback.pixels.data());
            // No flipVertically here, deliberately: IRenderBackend::readPixels delivers
            // top-left origin. The legacy sites flip because they call glReadPixels themselves.
            image.setOpacity(255);
            image.savePNG(file);
        } catch (stdext::exception& e) {
            g_logger.error(std::string("Can't save screenshot: ") + e.what());
        }
    });
}

void GraphicalApplication::doScreenshot(std::string file)
{
    if (file.empty()) {
        file = "screenshot.png";
    }

    g_mainDispatcher.addEvent([file] {
        // On the compiled path the readback is a request against the frame's backbuffer target,
        // with the crop stated in top-left pixels. Same GL call underneath; the difference is
        // that the coordinate convention is now the boundary's rather than each call site's.
        if (auto* backend = g_drawPool.getBackend()) {
            ReadbackResult readback;
            if (backend->readPixels(ReadbackRequest{ {}, Rect(0, 0, g_graphics.getViewportSize()) }, readback)
                && readback.ok) {
                saveReadbackAsPng(std::move(readback), file);
                return;
            }
        }

        auto resolution = g_graphics.getViewportSize();
        const int width = resolution.width();
        const int height = resolution.height();
        auto pixels = std::make_shared<std::vector<uint8_t>>(width * height * 4 * sizeof(GLubyte), 0);
        glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels->data());

        g_asyncDispatcher.detach_task([resolution, pixels, file] {
            try {
                Image image(resolution, 4, pixels->data());
                image.flipVertically();
                image.setOpacity(255);
                image.savePNG(file);
            } catch (stdext::exception& e) {
                g_logger.error(std::string("Can't do screenshot: ") + e.what());
            }
        });
    });
}

void GraphicalApplication::doMapScreenshot(std::string fileName)
{
    if (m_drawEvents) m_drawEvents->doMapScreenshot(fileName);
}

float GraphicalApplication::getHUDScale() const { return m_hudScale; }
void GraphicalApplication::setHUDScale(const float v) {
    m_hudScale = v;
    resize(g_graphics.getViewportSize());
}

float GraphicalApplication::getDevicePixelRatio() const { return m_devicePixelRatio; }
void GraphicalApplication::setDevicePixelRatio(const float v) {
    m_devicePixelRatio = v;
    resize(g_graphics.getViewportSize());
}
