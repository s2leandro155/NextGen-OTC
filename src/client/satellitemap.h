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

#include "declarations.h"
#include "position.h"
#include <framework/graphics/declarations.h>
#include <framework/util/color.h>
#include <framework/util/rect.h>
#include <array>
#include <cstdint>
#include <vector>
#include <unordered_map>

// Cyclopedia "Surface View" (pretty satellite map). Data is baked offline from
// the official Tibia assets (satellite-16 + subarea tiles referenced by map.dat)
// into <assetsDir>/satellite/{index.dat, <pngId>.png}. Placements are world-tile
// rectangles; a placement's texture is scaled to its world extent at draw time,
// so tile pixel resolution is irrelevant (the GPU handles it).
struct SatellitePlacement
{
    int x{ 0 };        // world top-left (NW) corner
    int y{ 0 };
    int w{ 0 };        // world-tile extent
    int h{ 0 };
    uint16_t pngId{ 0 };
    uint8_t layer{ 0 }; // 0 = satellite base, 1 = subarea detail (drawn on top)
};

class SatelliteMap
{
public:
    void init() {}
    void terminate() { clear(); }

    void clear();
    bool loadFloors(const std::string& assetsDir, int minFloor, int maxFloor);
    bool hasChunksForView(int floor);

    // Called from UIMinimap::drawSelf when satellite mode is active.
    void draw(const Rect& screenRect, const Position& mapCenter, float scale, float opacity);

    // Discovery-zone highlight: the map module fills these with a region's world rects.
    void clearHighlight() { m_highlightMasks.clear(); }
    void addHighlightMask(int x, int y, int w, int h, int maskId) { m_highlightMasks.push_back({ Rect(x, y, w, h), maskId }); }
    void setHighlightColor(const std::string& hex) { m_highlightColor = Color(hex); }

    // City name labels drawn over the map at world anchor positions.
    void clearCityLabels() { m_cityLabels.clear(); }
    void addCityLabel(int x, int y, const std::string& name) { m_cityLabels.push_back({ Point(x, y), name }); }

    // Hit-test a subarea's SHAPE (not its bounding rect): true if the mask alpha at the world
    // point (wx,wy) is set. The mask (satellite/zones/<sid>.png) is 1px/tile anchored at (rx,ry).
    bool maskContains(int sid, int rx, int ry, int wx, int wy);

    // POI discovery markers drawn at world anchors (fixed pixel size). done=true -> checkmark.
    void clearPoiMarkers() { m_poiMarkers.clear(); }
    void addPoiMarker(int x, int y, bool done) { m_poiMarkers.push_back({ Point(x, y), done }); }

private:
    bool ensureIndex(const std::string& assetsDir);
    const TexturePtr& getTile(uint16_t pngId);
    void pruneTextureCache();

    std::string m_dir;                                             // e.g. "/data/things/1530"
    bool m_indexLoaded{ false };
    Color m_ocean{ Color::black };
    std::array<std::vector<SatellitePlacement>, 16> m_placements;  // indexed by floor (z)
    struct CachedTexture {
        TexturePtr texture;
        uint64_t lastUsedFrame{ 0 };
    };
    std::unordered_map<uint16_t, CachedTexture> m_textures;       // bounded, demand-loaded chunk cache
    uint64_t m_drawFrame{ 0 };
    struct HighlightMask { Rect rect; int maskId; };
    const TexturePtr& getMask(int maskId);
    const ImagePtr& getMaskImage(int maskId);                     // CPU-side mask (for hit-testing)
    std::vector<HighlightMask> m_highlightMasks;                   // selected zone shapes (world coords)
    std::unordered_map<int, TexturePtr> m_maskTextures;           // cached zone masks by id
    std::unordered_map<int, ImagePtr> m_maskImages;               // cached mask alpha (hit-test)
    Color m_highlightColor{ Color(255, 220, 0, 90) };             // translucent yellow tint

    struct CityLabel { Point pos; std::string name; };
    std::vector<CityLabel> m_cityLabels;                          // city names (world anchor)

    struct PoiMarker { Point pos; bool done; };
    std::vector<PoiMarker> m_poiMarkers;                          // discovery POI markers (world anchor)
    TexturePtr m_poiDoneTex;                                      // checkmark icon (lazy)
    TexturePtr m_poiTodoTex;                                      // "to visit" icon (lazy)
    const TexturePtr& loadNamed(TexturePtr& slot, const std::string& name);
};

extern SatelliteMap g_satelliteMap;
