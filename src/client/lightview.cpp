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

#include "lightview.h"

#include "cloudfield.h"
#include "gameconfig.h"
#include "framework/core/clock.h"
#include "framework/core/eventdispatcher.h"
#include "framework/graphics/drawpoolmanager.h"
#include "framework/graphics/painter.h"

// How coarsely the cloud field is stepped through time. The pixel cache exists so updatePixels
// runs only when something changed, and a clock that ticks every frame would defeat it; at
// roughly half a tile of drift per second, 50 ms moves a shadow edge by under two pixels, which
// the light texture's own smoothing absorbs.
static constexpr ticks_t CLOUD_STEP_MS = 50;

LightView::LightView(const Size& size) : m_pool(g_drawPool.get(DrawPoolType::LIGHT)) {
    g_mainDispatcher.addEvent([this, size] {
        m_texture = std::make_shared<Texture>(size);
        m_texture->setSmooth(true);
    });
}

bool LightView::isEnabled() const { return m_pool->isEnabled(); }
void LightView::setEnabled(const bool v) { m_pool->setEnable(v); }

void LightView::resize(const Size& size, const uint16_t tileSize) {
    if (!m_texture || (m_mapSize == size && m_tileSize == tileSize))
        return;

    m_mapSize = size;
    m_tileSize = tileSize;
    m_pool->setScaleFactor(tileSize / g_gameConfig.getSpriteSize());

    m_lightData.tiles.resize(size.area());
    m_lightData.indoor.assign(size.area(), 0);
    m_lightData.lights.clear();

    for (auto& pixels : m_pixels)
        pixels.resize(size.area() * 4);

    if (m_texture)
        m_texture->setupSize(m_mapSize);
}

void LightView::addLightSource(const Point& pos, const Light& light, const float brightness)
{
    if (!isDark() || light.intensity == 0) return;

    if (!m_lightData.lights.empty()) {
        auto& prevLight = m_lightData.lights.back();
        if (prevLight.pos == pos && prevLight.color == light.color) {
            prevLight.intensity = std::max<uint8_t>(prevLight.intensity, light.intensity);
            return;
        }
    }

    size_t hash = pos.hash();
    stdext::hash_combine(hash, light.intensity);
    stdext::hash_combine(hash, light.color);

    if (g_drawPool.getOpacity() < 1.f)
        stdext::hash_combine(hash, g_drawPool.getOpacity());

    if (m_pool->getHashController().put(hash)) {
        const float effectiveBrightness = std::min<float>(brightness, g_drawPool.getOpacity());
        m_lightData.lights.emplace_back(pos, light.intensity, light.color, effectiveBrightness);
    }
}

void LightView::resetShade(const Point& pos)
{
    const size_t index = (pos.y / m_tileSize) * m_mapSize.width() + (pos.x / m_tileSize);
    if (index >= m_lightData.tiles.size()) return;
    m_lightData.tiles[index] = m_lightData.lights.size();
}

void LightView::markIndoor(const Point& pos, const bool indoor)
{
    const size_t index = (pos.y / m_tileSize) * m_mapSize.width() + (pos.x / m_tileSize);
    if (index >= m_lightData.indoor.size()) return;

    m_lightData.indoor[index] = indoor ? 1 : 0;

    // The pixel cache is keyed on what draw() feeds the hash controller, and stepping through a
    // doorway moves neither a light nor the global colour. Without the shaded set in that key
    // the texture keeps whatever shading the frame you walked in on had.
    if (indoor)
        stdext::hash_combine(m_indoorHash, index);
}

void LightView::draw(const Rect& dest, const Rect& src)
{
    static std::atomic_bool updatePixel;

    m_pool->getHashController().put(src.hash());
    m_pool->getHashController().put(m_globalLightColor.hash());
    m_pool->getHashController().put(m_indoorLightColor.hash());
    m_pool->getHashController().put(m_indoorHash);

    // Clouds move, so unlike everything else above they have to put time into the cache key.
    // Quantised, because the field drifts about half a tile a second and a step this coarse is
    // invisible while it keeps updatePixels off the every-frame path. The origin rides along:
    // it changes as the player walks between tiles, which src alone does not capture.
    if (m_cloudDepth > 0.f) {
        m_cloudTime = g_clock.millis() / CLOUD_STEP_MS * CLOUD_STEP_MS;
        m_pool->getHashController().put(static_cast<size_t>(m_cloudTime));
        m_pool->getHashController().put(m_cloudOrigin.hash());
    }

    if (m_pool->getHashController().wasModified()) {
        updatePixels();

        SpinLock::Guard guard(m_pool->getThreadLock());
        m_pixels[0].swap(m_pixels[1]);
        updatePixel.store(true, std::memory_order_relaxed);

        // The same upload, stated as data. Declared inside this branch so the compiled frame
        // uploads exactly in the frames GL uploads in - not every frame.
        if (m_texture) {
            g_drawPool.addTextureUpload(TextureHandle{ m_texture->getUniqueId() },
                                        m_texture->getSize(),
                                        m_pixels[1].data(), m_pixels[1].size());
        }
    }
    m_pool->getHashController().reset();

    // The lambda below is declared as data by addLightOverlay: one multiply-blended quad
    // sampling the light texture. It has to be declared rather than inferred, because the
    // lambda's real geometry comes from updateCoords() on the render thread, and a compiler
    // never runs the lambda.
    g_drawPool.addLightOverlay(m_texture, dest, src, m_tileSize, [=, this] {
        if (updatePixel.load(std::memory_order_relaxed)) {
            SpinLock::Guard guard(m_pool->getThreadLock());
            m_texture->updatePixels(m_pixels[1].data());
            updatePixel.store(false, std::memory_order_relaxed);
        }

        updateCoords(dest, src);

        g_painter->setCompositionMode(CompositionMode::MULTIPLY);
        g_painter->resetTransformMatrix();
        g_painter->resetColor();
        g_painter->setTexture(m_texture);
        g_painter->drawCoords(m_coords);
    });
}

void LightView::updateCoords(const Rect& dest, const Rect& src) {
    if (m_dest == dest && m_src == src)
        return;

    const auto& offset = src.topLeft();
    const auto& size = src.size();

    m_dest = dest;
    m_src = src;

    m_coords.clear();
    m_coords.addRect(RectF(m_dest.left(), m_dest.top(), m_dest.width(), m_dest.height()),
               RectF(static_cast<float>(offset.x) / m_tileSize, static_cast<float>(offset.y) / m_tileSize,
                     static_cast<float>(size.width()) / m_tileSize, static_cast<float>(size.height()) / m_tileSize));
}

void LightView::updatePixels()
{
    const auto lightSize = m_lightData.lights.size();
    const auto mapWidth = m_mapSize.width();
    const auto mapHeight = m_mapSize.height();
    const auto tileCenterOffset = m_tileSize / 2;
    const auto invTileSize = 1.0f / m_tileSize;

    auto* pixelData = m_pixels[0].data();

    for (int y = 0; y < mapHeight; ++y) {
        for (int x = 0; x < mapWidth; ++x) {
            const auto centerX = x * m_tileSize + tileCenterOffset;
            const auto centerY = y * m_tileSize + tileCenterOffset;
            const auto index = y * mapWidth + x;

            // A roofed tile starts from the shaded light instead of the open-air one. Light
            // sources are max()'d over this below, so a torch indoors still lights the room -
            // which is the reason this shades the base colour rather than painting over the
            // finished scene, where a multiply could only ever darken it further.
            const bool indoor = m_lightData.indoor[index] != 0;
            const auto& baseColor = indoor ? m_indoorLightColor : m_globalLightColor;

            auto r = baseColor.r();
            auto g = baseColor.g();
            auto b = baseColor.b();

            // Only open air passes under the clouds. A roofed tile has no sky left to lose and
            // keeps the flat indoor shading it already has, which is what the official client
            // does too: one branch per tile, cloud field or indoor factor, never both.
            if (!indoor && m_cloudDepth > 0.f) {
                const float sunlight = CloudField::coverage(m_cloudTime,
                                                            static_cast<float>(m_cloudOrigin.x + x),
                                                            static_cast<float>(m_cloudOrigin.y + y));
                const float shade = 1.f - m_cloudDepth * (1.f - sunlight);

                r = static_cast<uint8_t>(r * shade);
                g = static_cast<uint8_t>(g * shade);
                b = static_cast<uint8_t>(b * shade);
            }

            for (auto i = m_lightData.tiles[index]; i < lightSize; ++i) {
                const auto& light = m_lightData.lights[i];

                const auto dx = centerX - light.pos.x;
                const auto dy = centerY - light.pos.y;
                const auto distanceSq = dx * dx + dy * dy;

                const auto lightRadiusSq = (light.intensity * m_tileSize) * (light.intensity * m_tileSize);
                if (distanceSq > lightRadiusSq) continue;

                const auto distanceNorm = std::sqrt(distanceSq) * invTileSize;
                float intensity = (-distanceNorm + light.intensity) * 0.2f;
                if (intensity < 0.01f) continue;

                intensity = std::min<float>(intensity, 1.0f);

                const auto& lightColor = Color::from8bit(light.color) * intensity;

                r = std::max<int>(r, lightColor.r());
                g = std::max<int>(g, lightColor.g());
                b = std::max<int>(b, lightColor.b());
            }

            const auto colorIndex = index * 4;

            pixelData[colorIndex] = r;
            pixelData[colorIndex + 1] = g;
            pixelData[colorIndex + 2] = b;
            pixelData[colorIndex + 3] = 255;
        }
    }
}
