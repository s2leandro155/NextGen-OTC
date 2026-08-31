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

#include "framework/graphics/coordsbuffer.h"
#include "framework/luaengine/luaobject.h"
#include "staticdata.h"
#include <framework/graphics/declarations.h>

class LightView final : public LuaObject
{
public:
    LightView(const Size& size);
    ~LightView() override { m_texture = nullptr; }

    void resize(const Size& size, uint16_t tileSize);
    void draw(const Rect& dest, const Rect& src);

    void addLightSource(const Point& pos, const Light& light, float brightness = 1.f);
    void resetShade(const Point& pos);
    void markIndoor(const Point& pos, bool indoor);

    // The open-air light. Like setIndoorLight below, MapView hands over a finished colour
    // rather than a Light: the world light is cross-faded between two server values, and a
    // palette index cannot represent a colour part-way between two entries.
    void setGlobalLight(const Color& color, const uint8_t intensity)
    {
        m_globalLightIntensity = intensity;
        m_globalLightColor = color;
        updateDarkness();
    }

    // The light a roofed tile gets instead of the open-air one - the "Clouds & Indoor Effect".
    // MapView hands over a finished colour rather than a Light so the policy stays in one place;
    // `intensity` comes along only so the darkness test can read it. With the option off MapView
    // produces exactly m_globalLightColor, so the branch in updatePixels is then a no-op.
    // Note this is the open-air colour scaled, ambience included: the official client shades a
    // roofed tile after mixing the ambience in, so the option is not floored by Ambient Light.
    void setIndoorLight(const Color& color, const uint8_t intensity)
    {
        m_indoorLightIntensity = intensity;
        m_indoorLightColor = color;
        updateDarkness();
    }

    // How deep a cloud shadow may cut, 0..1, and where the light grid sits in world tile
    // coordinates. Depth 0 is the option switched off, and then none of this costs anything:
    // no time is mixed into the pixel cache's key, so the texture is reused exactly as before.
    void setCloudShading(const float depth)
    {
        m_cloudDepth = depth;
        updateDarkness();
    }

    void setCloudOrigin(const Point& origin) { m_cloudOrigin = origin; }

    bool isDark() const { return m_isDark; }
    bool isEnabled() const;
    void setEnabled(const bool v);
    void clear() {
        m_lightData.lights.clear();
        m_lightData.tiles.assign(m_mapSize.area(), {});
        m_lightData.indoor.assign(m_mapSize.area(), 0);
        m_indoorHash = 0;
    }

private:
    struct TileLight : Light
    {
        Point pos;
        float brightness{ 1.f };

        TileLight(const Point& pos, const uint8_t intensity, const uint8_t color, const float brightness) : Light(intensity, color), pos(pos), brightness(brightness) {}
    };

    struct LightData
    {
        std::vector<size_t> tiles;
        std::vector<TileLight> lights;

        // One flag per tile of the light grid: is this tile under a roof. Parallel to `tiles`
        // rather than part of it because the two are written by different passes.
        std::vector<uint8_t> indoor;
    };

    void updateCoords(const Rect& dest, const Rect& src);
    void updatePixels();

    // Dark when ANY of the three has something to draw. The two intensities are the brightest
    // channel of the colours above, not the server's light level: what decides whether this
    // pass is worth running is what the light map would multiply by, and the ambient tint means
    // those two stopped being the same number. A shaded interior has to be drawn even while the
    // open air outside sits at full daylight, which is exactly the case that would otherwise
    // keep the whole pass off. Cloud shadows join the test for the same reason and are the
    // stronger case for it: broad daylight is precisely when they are worth seeing.
    void updateDarkness() { m_isDark = m_globalLightIntensity < 250 || m_indoorLightIntensity < 250 || m_cloudDepth > 0.f; }

    bool m_isDark{ false };

    Size m_mapSize;
    uint16_t m_tileSize{ 32 };
    Color m_globalLightColor{ Color::white };
    Color m_indoorLightColor{ Color::white };
    uint8_t m_globalLightIntensity{ UINT8_MAX };
    uint8_t m_indoorLightIntensity{ UINT8_MAX };
    size_t m_indoorHash{ 0 };

    float m_cloudDepth{ 0.f };
    ticks_t m_cloudTime{ 0 };
    Point m_cloudOrigin;

    DrawPool* m_pool{ nullptr };

    Rect m_dest, m_src;
    CoordsBuffer m_coords;
    TexturePtr m_texture;
    LightData m_lightData;
    std::array<std::vector<uint8_t>, 2> m_pixels;
};
