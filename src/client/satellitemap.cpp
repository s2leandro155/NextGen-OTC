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

#include "satellitemap.h"

#include <framework/core/filestream.h>
#include <framework/core/resourcemanager.h>
#include <framework/core/logger.h>
#include <framework/graphics/drawpoolmanager.h>
#include <framework/graphics/image.h>
#include <framework/graphics/texture.h>
#include <framework/graphics/fontmanager.h>
#include <framework/graphics/bitmapfont.h>
#include <framework/const.h>
#include <framework/core/clock.h>
#include <algorithm>
#include <cmath>

SatelliteMap g_satelliteMap;

void SatelliteMap::clear()
{
    for (auto& v : m_placements)
        v.clear();
    m_textures.clear();
    m_maskTextures.clear();
    m_maskImages.clear();
    m_poiDoneTex.reset();
    m_poiTodoTex.reset();
    m_indexLoaded = false;
    m_drawFrame = 0;
    m_dir.clear();
}

const TexturePtr& SatelliteMap::loadNamed(TexturePtr& slot, const std::string& name)
{
    if (slot)
        return slot;

    ImagePtr img;
    try {
        img = Image::load(m_dir + "/satellite/" + name);
    } catch (const std::exception&) {
        img = nullptr;
    }
    if (img) {
        slot = std::make_shared<Texture>(img, false, false);
        slot->setSmooth(true); // small icon, smooth scaling looks better
    }
    return slot;
}

const ImagePtr& SatelliteMap::getMaskImage(const int maskId)
{
    const auto it = m_maskImages.find(maskId);
    if (it != m_maskImages.end())
        return it->second;

    ImagePtr img;
    const std::string file = m_dir + "/satellite/zones/" + std::to_string(maskId);
    try {
        img = Image::load(file);
    } catch (const std::exception&) {
        img = nullptr;
    }
    return m_maskImages.emplace(maskId, img).first->second;
}

bool SatelliteMap::maskContains(const int sid, const int rx, const int ry, const int wx, const int wy)
{
    const ImagePtr& img = getMaskImage(sid);
    if (!img)
        return false;

    const int px = wx - rx;
    const int py = wy - ry;
    if (px < 0 || py < 0 || px >= img->getWidth() || py >= img->getHeight())
        return false;

    // Mask is 1px per world tile, RGBA; alpha marks the shape's interior.
    return img->getPixel(px, py)[3] > 40;
}

bool SatelliteMap::ensureIndex(const std::string& assetsDir)
{
    if (m_indexLoaded && m_dir == assetsDir)
        return true;

    // Different data set: drop everything and reload.
    for (auto& v : m_placements)
        v.clear();
    m_textures.clear();
    m_indexLoaded = false;
    m_dir = assetsDir;

    const std::string path = assetsDir + "/satellite/index.dat";

    FileStreamPtr fin;
    try {
        fin = g_resources.openFile(path);
    } catch (const std::exception&) {
        return false; // satellite data not shipped for this data set
    }
    if (!fin)
        return false;

    try {
        fin->cache();
        if (fin->getU8() != 'S' || fin->getU8() != 'A' || fin->getU8() != 'T' || fin->getU8() != 'L') {
            fin->close();
            return false;
        }
        fin->getU8(); // version
        const uint8_t r = fin->getU8();
        const uint8_t g = fin->getU8();
        const uint8_t b = fin->getU8();
        m_ocean = Color(static_cast<int>(r), static_cast<int>(g), static_cast<int>(b), 255);
        fin->getU32(); fin->getU32(); fin->getU32(); fin->getU32(); // world bounds (reserved)

        const uint32_t count = fin->getU32();
        for (uint32_t i = 0; i < count; ++i) {
            const uint8_t floor = fin->getU8();
            SatellitePlacement p;
            // NOTE: use getU32 (readULE32), not get32 — stdext::readSLE32 sign-extends the low
            // 16 bits and corrupts any coord >= 0x8000 (e.g. Venore/Edron at x >= 32768).
            p.x = static_cast<int32_t>(fin->getU32());
            p.y = static_cast<int32_t>(fin->getU32());
            p.w = fin->getU16();
            p.h = fin->getU16();
            p.layer = fin->getU8();
            p.pngId = fin->getU16();
            if (floor < m_placements.size())
                m_placements[floor].push_back(p);
        }
        fin->close();
    } catch (const std::exception& e) {
        g_logger.error("SatelliteMap: failed to parse {}: {}", path, e.what());
        for (auto& v : m_placements)
            v.clear();
        return false;
    }

    m_indexLoaded = true;
    return true;
}

bool SatelliteMap::loadFloors(const std::string& assetsDir, int /*minFloor*/, int /*maxFloor*/)
{
    // The whole index is small; textures load lazily (only visible tiles) in draw().
    return ensureIndex(assetsDir);
}

bool SatelliteMap::hasChunksForView(const int floor)
{
    if (!m_indexLoaded || floor < 0 || floor >= static_cast<int>(m_placements.size()))
        return false;

    if (floor > 7)
        return !m_placements[floor].empty();

    // Surface view stacks the current floor over everything down to ground (7).
    return std::any_of(m_placements.begin() + floor, m_placements.begin() + 8,
                       [](const auto& placements) { return !placements.empty(); });
}

const TexturePtr& SatelliteMap::getTile(const uint16_t pngId)
{
    auto it = m_textures.find(pngId);
    if (it != m_textures.end()) {
        it->second.lastUsedFrame = m_drawFrame;
        return it->second.texture;
    }

    TexturePtr tex;
    const std::string file = m_dir + "/satellite/" + std::to_string(pngId); // guessFilePath appends .png
    ImagePtr img;
    try {
        img = Image::load(file);
    } catch (const std::exception&) {
        img = nullptr;
    }
    if (img) {
        tex = std::make_shared<Texture>(img, false, false);
        tex->enableMipmaps(); // clean minification when zoomed out (no downscale aliasing/blur)
        tex->setSmooth(false); // keep nearest for crisp magnification -> GL_NEAREST_MIPMAP_NEAREST
    } else {
        g_logger.warning("SatelliteMap: failed to load tile {} ({})", pngId, file);
    }
    return m_textures.emplace(pngId, CachedTexture{ tex, m_drawFrame }).first->second.texture;
}

void SatelliteMap::pruneTextureCache()
{
    // A small minimap normally needs only a handful of chunks. Keep a short grace
    // period for panning, then cap the cache so travelling never retains the world.
    constexpr uint64_t maxIdleFrames = 180;
    constexpr size_t maxCachedChunks = 48;

    for (auto it = m_textures.begin(); it != m_textures.end();) {
        if (m_drawFrame > it->second.lastUsedFrame + maxIdleFrames)
            it = m_textures.erase(it);
        else
            ++it;
    }

    while (m_textures.size() > maxCachedChunks) {
        const auto oldest = std::min_element(m_textures.begin(), m_textures.end(),
            [](const auto& lhs, const auto& rhs) {
                return lhs.second.lastUsedFrame < rhs.second.lastUsedFrame;
            });
        if (oldest == m_textures.end())
            break;
        m_textures.erase(oldest);
    }
}

const TexturePtr& SatelliteMap::getMask(const int maskId)
{
    const auto it = m_maskTextures.find(maskId);
    if (it != m_maskTextures.end())
        return it->second;

    TexturePtr tex;
    const std::string file = m_dir + "/satellite/zones/" + std::to_string(maskId);
    ImagePtr img;
    try {
        img = Image::load(file);
    } catch (const std::exception&) {
        img = nullptr;
    }
    if (img) {
        tex = std::make_shared<Texture>(img, false, false);
        tex->setSmooth(false);
    }
    return m_maskTextures.emplace(maskId, tex).first->second;
}

void SatelliteMap::draw(const Rect& screenRect, const Position& mapCenter, const float scale, const float opacity)
{
    if (screenRect.isEmpty() || scale <= 0.f)
        return;

    const int curZ = mapCenter.z;
    if (curZ < 0 || curZ >= static_cast<int>(m_placements.size()))
        return;

    ++m_drawFrame;

    const auto& oldClip = g_drawPool.getClipRect();
    g_drawPool.setClipRect(screenRect);

    // Ocean/background fill (satellite tiles are cut around land, water is transparent).
    g_drawPool.addFilledRect(screenRect, m_ocean);

    // World -> screen transform, mirrored from Minimap::draw / getTilePoint so that
    // satellite tiles line up 1:1 with the classic minimap. 1 world tile = scale px.
    Rect mapRect(0, 0, static_cast<int>(screenRect.width() / scale),
                 static_cast<int>(std::ceil(screenRect.height() / scale)));
    mapRect.moveCenter(Point(mapCenter.x, mapCenter.y));
    const Point off = Point((mapRect.size() * scale).toPoint() - screenRect.size().toPoint()) / 2;
    const Point base = screenRect.topLeft() - off - (mapRect.topLeft() * scale);

    const Color tint = (opacity >= 1.f) ? Color::white : Color(Color::white, std::clamp(opacity, 0.f, 1.f));

    // LOD: choose tile resolution by zoom (scale = screen px per world tile) so we never
    // heavily downscale (which blurs). level 2 = satellite-16 (2px/tile), 1 = satellite-32
    // (1px/tile), 0 = satellite-64 (0.5px/tile). Pick the highest detail that isn't downscaled.
    // Prefer the highest detail (sat-16) for all normal zooms; mipmaps keep it clean when
    // downscaled. Fall back to coarser tiles only when extremely zoomed out.
    const int targetLevel = (scale >= 0.4f) ? 2 : (scale >= 0.15f) ? 1 : 0;

    // Stack floors from the ground (7) up to the current floor, so lower floors show
    // through the transparent gaps of the floors above (surface "0+1" view). Ground is
    // drawn first (bottom), the current floor last (on top).
    const int firstFloor = curZ <= 7 ? 7 : curZ;
    for (int f = firstFloor; f >= curZ; --f) {
        // Draw only the LOD level matching the zoom, so detail is uniform (no low-detail base
        // showing through). Each level is a full grid, so coverage stays complete.
        for (const auto& p : m_placements[f]) {
            if (p.layer != targetLevel)
                continue;
            const Point tl = base + Point(p.x, p.y) * scale;
            const int dw = std::max(1, static_cast<int>(std::ceil(p.w * scale)));
            const int dh = std::max(1, static_cast<int>(std::ceil(p.h * scale)));
            const Rect dest(tl, Size(dw, dh));

            // Cull tiles outside the visible area (also avoids decoding their PNGs).
            if (dest.right() < screenRect.left() || dest.left() > screenRect.right() ||
                dest.bottom() < screenRect.top() || dest.top() > screenRect.bottom())
                continue;

            const TexturePtr& tex = getTile(p.pngId);
            if (!tex)
                continue;

            const auto& ts = tex->getSize();
            g_drawPool.addTexturedRect(dest, tex, Rect(0, 0, ts.width(), ts.height()), tint);
        }
    }


    // Pruning once per second is enough and keeps it out of the hot draw path.
    if ((m_drawFrame % 60) == 0)
        pruneTextureCache();

    // Discovery-zone highlight: draw each subarea mask tinted so the highlight follows the
    // coastline (the mask is a white land shape with transparent water). The alpha breathes
    // (~1.4s period) so the selected zone pulses like the official Cyclopedia's area highlight.
    if (!m_highlightMasks.empty()) {
        const float pulseT = static_cast<float>(g_clock.millis() % 1400) / 1400.f;
        const float pulse = 0.5f - 0.5f * std::cos(pulseT * 6.2831853f);
        const Color pulseColor(m_highlightColor, 0.20f + 0.45f * pulse);
        for (const auto& hm : m_highlightMasks) {
            const Point tl = base + Point(hm.rect.x(), hm.rect.y()) * scale;
            const Rect dest(tl, Size(std::max(1, static_cast<int>(std::ceil(hm.rect.width() * scale))),
                                     std::max(1, static_cast<int>(std::ceil(hm.rect.height() * scale)))));
            if (dest.right() < screenRect.left() || dest.left() > screenRect.right() ||
                dest.bottom() < screenRect.top() || dest.top() > screenRect.bottom())
                continue;
            const TexturePtr& mask = getMask(hm.maskId);
            if (!mask)
                continue;
            const auto& ts = mask->getSize();
            g_drawPool.addTexturedRect(dest, mask, Rect(0, 0, ts.width(), ts.height()), pulseColor);
        }
    }

    // City name labels at their world anchors (hidden when zoomed far out to avoid clutter).
    if (scale >= 0.4f && !m_cityLabels.empty()) {
        const auto& font = g_fonts.getDefaultFont();
        if (font) {
            for (const auto& c : m_cityLabels) {
                const Point sp = base + c.pos * scale;
                if (sp.x < screenRect.left() || sp.x > screenRect.right() ||
                    sp.y < screenRect.top() || sp.y > screenRect.bottom())
                    continue;
                const Rect box(sp.x - 80, sp.y - 8, 160, 16);
                font->drawText(c.name, Rect(box.x() + 1, box.y() + 1, 160, 16), Color::black, Fw::AlignCenter);
                font->drawText(c.name, box, Color::white, Fw::AlignCenter);
            }
        }
    }

    // Discovery POI markers: fixed pixel size at world anchors (checkmark = discovered,
    // ring = still to visit). Hidden when zoomed far out to avoid clutter.
    if (!m_poiMarkers.empty() && scale >= 0.3f) {
        const TexturePtr& doneTex = loadNamed(m_poiDoneTex, "poi_done");
        const TexturePtr& todoTex = loadNamed(m_poiTodoTex, "poi_todo");
        const int sz = 18;
        for (const auto& m : m_poiMarkers) {
            const Point sp = base + m.pos * scale;
            if (sp.x < screenRect.left() - sz || sp.x > screenRect.right() + sz ||
                sp.y < screenRect.top() - sz || sp.y > screenRect.bottom() + sz)
                continue;
            const TexturePtr& tex = m.done ? doneTex : todoTex;
            if (!tex)
                continue;
            const Rect dest(sp.x - sz / 2, sp.y - sz / 2, sz, sz);
            const auto& ts = tex->getSize();
            g_drawPool.addTexturedRect(dest, tex, Rect(0, 0, ts.width(), ts.height()), Color::white);
        }
    }

    g_drawPool.setClipRect(oldClip);
}
