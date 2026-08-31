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

#include "mapview.h"
#include <framework/util/profiler.h>

#include <framework/graphics/render/poolcompiler.h>

#include <framework/graphics/drawpoolmanager.h>
#include <framework/sound/soundmanager.h>

#include "ambientlight.h"
#include "animatedtext.h"
#include "creature.h"
#include "game.h"
#include "gameconfig.h"
#include "lightview.h"
#include "map.h"
#include "missile.h"
#include "tile.h"
#include "item.h"
#include <framework/input/mouse.h>
#include "framework/core/asyncdispatcher.h"
#include "framework/core/clock.h"
#include "framework/core/eventdispatcher.h"
#include <framework/core/graphicalapplication.h>
#include "framework/graphics/graphics.h"
#include "framework/graphics/painter.h"
#include "framework/graphics/shadermanager.h"
#include "framework/graphics/texturemanager.h"
#include <framework/platform/platformwindow.h>

MapView::MapView() : m_lightView(std::make_unique<LightView>(Size())), m_pool(g_drawPool.get(DrawPoolType::MAP))
{
    // A map view opened mid-session inherits the world light that is already in effect, so it
    // does not have to spend a fade catching up to a sky everyone else can already see. Having
    // inherited one, it also has something to fade *from*, so it need not snap the next value.
    const auto& worldLight = g_map.getLight();
    m_ambientFrom = m_ambientTo = AmbientFade::resolve(worldLight.color, worldLight.intensity);
    m_ambientSeeded = worldLight.intensity != 0;

    m_floors.resize(g_gameConfig.getMapMaxZ() + 1);
    m_floorThreads.resize(g_asyncDispatcher.get_thread_count());
    for (auto& thread : m_floorThreads)
        thread.resize(m_floors.size());

    setVisibleDimension(Size(15, 11));
}

MapView::~MapView()
{
#ifndef NDEBUG
    assert(!g_app.isTerminated());
#endif
}

void MapView::declareCompositionMaterial() const
{
    MaterialParams params;
    params.resolution = { static_cast<float>(m_rectDimension.width()),
                          static_cast<float>(m_rectDimension.height()) };

    MaterialHandle material;
    std::array<TextureHandle, 3> extraTex{};
    float opacity = 1.f;

    if (m_shader) {
        const auto& camera = m_posInfo.camera;
        const auto& center = m_posInfo.srcRect.center();
        const auto& globalCoord = Point(camera.x - m_drawDimension.width() / 2,
                                        -(camera.y - m_drawDimension.height() / 2)) * m_tileSize;

        params.mapCenterCoord = { center.x / static_cast<float>(m_rectDimension.width()),
                                  1.f - center.y / static_cast<float>(m_rectDimension.height()) };
        params.mapGlobalCoord = { globalCoord.x / static_cast<float>(m_rectDimension.height()),
                                  globalCoord.y / static_cast<float>(m_rectDimension.height()) };
        params.mapZoom = m_pool->getScaleFactor();

        Point last = transformPositionTo2D(camera, m_shaderPosition);
        last.y = -last.y; // reverse vertical axis, as the callback does
        params.walkOffset = { last.x / static_cast<float>(m_rectDimension.width()),
                              last.y / static_cast<float>(m_rectDimension.height()) };

        material = PoolCompiler::materialOf(m_shader.get());

        // u_Tex1..3. GL binds these from inside Painter::drawArrays off the bound program, so
        // the composition blit gets them for free there; a backend that does not share Painter
        // has to be told, and this is the only site that can tell it - the composition packet is
        // built by the frame assembler, which never sees a PainterShaderProgram. Fog and Snow
        // are the two shaders that use them, and both are map shaders, so this is exactly the
        // site that matters.
        size_t unit = 0;
        for (const auto& texture : m_shader->getMultiTextures()) {
            if (unit >= extraTex.size())
                break;
            if (texture)
                extraTex[unit++] = TextureHandle{ texture->getUniqueId() };
        }

        // A read-only sample of the same fade ramp the callback computes. It deliberately does
        // NOT advance the switch: m_shader/m_nextShader/m_shaderSwitchDone stay the callback's
        // to mutate, so declaring changes nothing about what GL draws.
        if (!m_shaderSwitchDone && m_fadeOutTime > 0)
            opacity = std::max(0.f, 1.f - (m_fadeTimer.timeElapsed() / m_fadeOutTime));
        else if (m_shaderSwitchDone && m_fadeInTime > 0)
            opacity = std::min<float>(m_fadeTimer.timeElapsed() / m_fadeInTime, 1.f);
    }

    g_drawPool.setCompositionMaterial(material, params, opacity, extraTex);
}

void MapView::registerEvents() {
    declareCompositionMaterial();

    g_drawPool.addAction([this, camera = m_posInfo.camera, srcRect = m_posInfo.srcRect] {
        m_pool->onBeforeDraw([=, this] {
            float fadeOpacity = 1.f;
            if (!m_shaderSwitchDone && m_fadeOutTime > 0) {
                fadeOpacity = 1.f - (m_fadeTimer.timeElapsed() / m_fadeOutTime);
                if (fadeOpacity < 0.f) {
                    m_shader = m_nextShader;
                    m_nextShader = nullptr;
                    m_shaderSwitchDone = true;
                    m_fadeTimer.restart();
                }
            }

            if (m_shaderSwitchDone && m_shader && m_fadeInTime > 0)
                fadeOpacity = std::min<float>(m_fadeTimer.timeElapsed() / m_fadeInTime, 1.f);

            if (m_shader) {
                const auto& center = srcRect.center();
                const auto& globalCoord = Point(camera.x - m_drawDimension.width() / 2, -(camera.y - m_drawDimension.height() / 2)) * m_tileSize;

                m_shader->bind();
                m_shader->setUniformValue(ShaderManager::MAP_CENTER_COORD, center.x / static_cast<float>(m_rectDimension.width()), 1.f - center.y / static_cast<float>(m_rectDimension.height()));
                m_shader->setUniformValue(ShaderManager::MAP_GLOBAL_COORD, globalCoord.x / static_cast<float>(m_rectDimension.height()), globalCoord.y / static_cast<float>(m_rectDimension.height()));
                m_shader->setUniformValue(ShaderManager::MAP_ZOOM, m_pool->getScaleFactor());

                Point last = transformPositionTo2D(camera, m_shaderPosition);
                //Reverse vertical axis.
                last.y = -last.y;

                m_shader->setUniformValue(ShaderManager::MAP_WALKOFFSET, last.x / static_cast<float>(m_rectDimension.width()), last.y / static_cast<float>(m_rectDimension.height()));

                g_painter->setShaderProgram(m_shader);
            }

            g_painter->setOpacity(fadeOpacity);
        });

        m_pool->onAfterDraw([] {
            g_painter->resetShaderProgram();
            g_painter->resetOpacity();
        });
    }, ActionIdiom::MapShaderBind);
}

void MapView::preLoad() {
    PROFILE_ZONE(MapPreLoad);
    // update visible tiles cache when needed
    if (m_updateVisibleTiles)
        updateVisibleTiles();

    if (canFloorFade()) {
        const float fadeLevel = getFadeLevel(m_cachedFirstVisibleFloor);
        if (!m_fadeFinish && fadeLevel == 1.f) {
            onFadeInFinished();
            m_fadeFinish = true;
        }
    }

    g_map.updateAttachedWidgets(static_self_cast<MapView>());

    updateItemAmbientSounds();
}

// A waterfall or a campfire loops while enough of its items are near enough.
// The soundbank says which item ids count, how many are needed and how close
// they have to be; only the map can answer how many there are, so the count
// happens here.
//
// Deliberately NOT counted off the renderer's visible-tile cache. That cache is
// a drawing concept: it is resized by zoom and by the window, and it drops
// floors the moment they are covered - so walking TOWARDS a source could
// silence it, and zooming out could make it audible. Distance from the player
// is the only thing that should decide, so the map itself is walked instead.
void MapView::updateItemAmbientSounds()
{
    const auto& queries = g_sounds.getItemAmbientQueries();
    if (queries.empty())
        return;

    // The answer only moves when items or the player do, and either way a
    // fraction of a second late is inaudible - so this is throttled rather than
    // hung off every tile update.
    if (m_itemAmbientTimer.ticksElapsed() < 250)
        return;

    m_itemAmbientTimer.restart();

    if (m_itemAmbientGeneration != g_sounds.getItemAmbientGeneration()) {
        m_itemAmbientGeneration = g_sounds.getItemAmbientGeneration();
        m_itemAmbientIndex.clear();
        for (size_t i = 0; i < queries.size(); ++i) {
            for (const uint16_t clientId : queries[i].clientIds)
                m_itemAmbientIndex[clientId].push_back(static_cast<uint8_t>(i));
        }

        m_itemAmbientReach = 0;
        for (const auto& query : queries)
            m_itemAmbientReach = std::max<uint32_t>(m_itemAmbientReach, query.maxDistance);
        m_itemAmbientReach += SoundManager::ITEM_AMBIENT_NEAR_MARGIN;
    }

    m_itemAmbientCounts.assign(queries.size(), 0);
    m_itemAmbientNearby.assign(queries.size(), 0);

    const auto& cameraPosition = m_posInfo.camera;
    if (!cameraPosition.isValid())
        return;

    // [snd-trace] disabled - uncomment with the two blocks below to restore the scan trace
    // // While tracing, record WHICH items answered each query and how far off they
    // // were - including the ones that matched but were out of reach, which is the
    // // only way to tell "nothing here" from "just too far" from outside.
    // const bool trace = g_sounds.isSoundDebug();
    // std::vector<std::string> counted, tooFar;
    // if (trace) {
        // counted.assign(queries.size(), std::string());
        // tooFar.assign(queries.size(), std::string());
    // }

    const int reach = static_cast<int>(m_itemAmbientReach);
    const int floorCost = static_cast<int>(SoundManager::ITEM_AMBIENT_FLOOR_COST);
    const int floorSpan = reach / std::max(floorCost, 1);
    const int maxZ = g_gameConfig.getMapMaxZ();

    for (int dz = -floorSpan; dz <= floorSpan; ++dz) {
        const int z = static_cast<int>(cameraPosition.z) + dz;
        if (z < 0 || z > maxZ)
            continue;

        // Every floor of separation spends part of the budget, so the higher
        // ones are walked over a smaller square rather than the full one.
        const int spent = std::abs(dz) * floorCost;
        const int span = reach - spent;
        if (span < 0)
            continue;

        for (int dy = -span; dy <= span; ++dy) {
            for (int dx = -span; dx <= span; ++dx) {
                const Position tilePosition(static_cast<uint16_t>(cameraPosition.x + dx),
                                            static_cast<uint16_t>(cameraPosition.y + dy),
                                            static_cast<uint8_t>(z));

                const auto& tile = g_map.getTile(tilePosition);
                if (!tile)
                    continue;

                // Chebyshev on the ground plus what the floors cost. A source
                // one floor down is genuinely further away than one beside you,
                // and no camera decision can change that.
                const int distance = std::max(std::abs(dx), std::abs(dy)) + spent;

                for (const auto& thing : tile->getThings()) {
                    // creatures share this vector and override getId(), so ask
                    // for the client id directly and skip anything not an item
                    if (!thing->isItem())
                        continue;

                    const auto entry = m_itemAmbientIndex.find(thing->getClientId());
                    if (entry == m_itemAmbientIndex.end())
                        continue;

                    for (const uint8_t query : entry->second) {
                        // The near band is measured from THIS query's radius,
                        // not from how far the walk happens to reach: the walk
                        // is sized for the widest query, and reusing it here
                        // would call an item twelve tiles from a three-tile
                        // entry "just out of reach", which is most of a city.
                        const int radius = static_cast<int>(queries[query].maxDistance);
                        const int nearLimit = radius + static_cast<int>(SoundManager::ITEM_AMBIENT_NEAR_MARGIN);

                        if (distance > nearLimit)
                            continue; // too far to count and too far to matter

                        const bool inRange = distance <= radius;
                        if (inRange)
                            ++m_itemAmbientCounts[query];
                        else
                            ++m_itemAmbientNearby[query];

                        // if (trace) {
                            // auto& into = inRange ? counted[query] : tooFar[query];
                            // if (into.size() < 220)
                                // into += fmt::format(" {}@d{}{}", thing->getClientId(), distance,
                                                    // dz == 0 ? std::string() : fmt::format(",z{:+d}", dz));
                        // }
                    }
                }
            }
        }
    }

    // if (trace) {
        // if (m_itemAmbientDebugLast.size() != m_itemAmbientCounts.size())
            // m_itemAmbientDebugLast.assign(m_itemAmbientCounts.size(), 0xFFFF);

        // // one line per query whose answer moved, not one per scan
        // for (size_t i = 0; i < m_itemAmbientCounts.size(); ++i) {
            // if (m_itemAmbientDebugLast[i] == m_itemAmbientCounts[i])
                // continue;

            // m_itemAmbientDebugLast[i] = m_itemAmbientCounts[i];
            // g_logger.info("[snd] scan entry {} radius={} count={} nearby={}{}{}",
                          // queries[i].effectId, queries[i].maxDistance,
                          // m_itemAmbientCounts[i], m_itemAmbientNearby[i],
                          // counted[i].empty() ? std::string() : "  counted:" + counted[i],
                          // tooFar[i].empty() ? std::string() : "  toofar:" + tooFar[i]);
        // }
    // }

    g_sounds.setItemAmbientCounts(m_itemAmbientCounts, m_itemAmbientNearby);
}

void MapView::drawFloor()
{
    PROFILE_ZONE(DrawFloor);
    updateAmbientFade();

    const auto& cameraPosition = m_posInfo.camera;

    const uint32_t flags = Otc::DrawThings;

    // Scratch space for one diagonal run, hoisted out of the floor loop: it was allocating and
    // freeing once per floor, which is up to eight heap round-trips a frame for a buffer whose
    // contents never outlive the run. Raw Tile* rather than TilePtr because EVERY visible tile
    // passes through here - it is the staging list, not a list of walkers - so a shared_ptr
    // element cost an atomic increment and decrement per tile per frame to own something that is
    // already owned for the whole draw by m_floors[z].cachedVisibleTiles. That cache is rebuilt
    // only by updateVisibleTiles, which runs in preLoad on this same thread, before this.
    std::vector<Tile*> walkingTiles;

    for (int_fast8_t z = m_floorMax; z >= m_floorMin; --z) {
        const float fadeLevel = getFadeLevel(z);
        if (fadeLevel == 0.f) break;
        if (fadeLevel < .99f)
            g_drawPool.setOpacity(fadeLevel);

        Position _camera = cameraPosition;
        const bool alwaysTransparent = m_floorViewMode == Otc::ALWAYS_WITH_TRANSPARENCY && z < m_cachedFirstVisibleFloor && _camera.coveredUp(cameraPosition.z - z);

        const auto& map = m_floors[z].cachedVisibleTiles;
        walkingTiles.clear();

        for (size_t i = 0, tileCount = map.tiles.size(); i < tileCount; ++i) {
            const auto& tile = map.tiles[i];
            uint32_t tileFlags = flags;

            if (!m_drawViewportEdge && !tile->canRender(tileFlags, cameraPosition, m_viewport))
                continue;

            walkingTiles.emplace_back(tile.get());

            // Delay this diagonal run until its upper-right dependency has no walking
            // creature, then render the run in reverse to preserve creature occlusion.
            //
            // The neighbour is usually just the next entry in the cache, so a position
            // comparison answers this instead of a hash lookup: updateVisibleTiles walks each
            // diagonal by stepping (x+1, y-1), which IS the upper-right neighbour. Only usually,
            // though - the cache omits tiles that are not drawable or are fully covered, and
            // then the next entry is a different tile and the map has to be asked after all.
            const Position upperRight = tile->getPosition().translated(1, -1, 0);
            Tile* upperRightTile = (i + 1 < tileCount && map.tiles[i + 1]->getPosition() == upperRight)
                ? map.tiles[i + 1].get()
                : g_map.getTile(upperRight).get();

            if (!upperRightTile || upperRightTile->getWalkingCreatures().empty()) {
                for (const auto& walkingTile : std::ranges::reverse_view(walkingTiles)) {
                    if (alwaysTransparent) {
                        const bool inRange = walkingTile->getPosition().isInRange(_camera, g_gameConfig.getTileTransparentFloorViewRange(), g_gameConfig.getTileTransparentFloorViewRange(), true);
                        g_drawPool.setOpacity(inRange ? .16 : .7);
                    }

                    walkingTile->draw(transformPositionTo2D(walkingTile->getPosition()), tileFlags);

                    if (alwaysTransparent)
                        g_drawPool.resetOpacity();
                }
                walkingTiles.clear();
            }
        }

        for (const auto& missile : g_map.getFloorMissiles(z))
            missile->draw(transformPositionTo2D(missile->getPosition()), true);

        if (m_shadowFloorIntensity > 0 && z == cameraPosition.z + 1) {
            g_drawPool.setOpacity(m_shadowFloorIntensity, true);
            g_drawPool.setDrawOrder(DrawOrder::FIFTH);
            g_drawPool.addFilledRect(m_rectDimension, Color::black);
            g_drawPool.resetDrawOrder();
        }

        if (canFloorFade())
            g_drawPool.resetOpacity();

        g_drawPool.flush();
    }

    if (m_posInfo.rect.contains(g_window.getMousePosition() * g_window.getDisplayDensity())) {
        if (m_crosshairTexture && m_mousePosition.isValid()) {
            const auto& point = transformPositionTo2D(m_mousePosition);
            const auto& crosshairRect = Rect(point, m_tileSize, m_tileSize);

            // Frame strip (width = n * height, e.g. highlight-baseplate 256x32 = 8 frames
            // from the ported client): without cropping the whole strip landed in one tile and the
            // outline looked like vertical dashes. We draw one frame, selected by time (pulse).
            const int frameSide = m_crosshairTexture->getHeight();
            const int textureWidth = m_crosshairTexture->getWidth();
            if (frameSide > 0 && textureWidth >= frameSide * 2 && textureWidth % frameSide == 0) {
                const int frameCount = textureWidth / frameSide;
                const int frame = static_cast<int>((g_clock.millis() / 100) % frameCount);
                g_drawPool.addTexturedRect(crosshairRect, m_crosshairTexture,
                                           Rect(frame * frameSide, 0, frameSide, frameSide));
            } else {
                g_drawPool.addTexturedRect(crosshairRect, m_crosshairTexture);
            }
        }
    } else if (m_lastHighlightTile) {
        m_mousePosition = {}; // Invalidate mousePosition
        destroyHighlightTile();
    }
}

void MapView::drawLights() {
    PROFILE_ZONE(DrawLights);
    const auto& cameraPosition = m_posInfo.camera;

    // Where light-grid cell (0,0) sits in the world. Inverting transformPositionTo2D leaves
    // exactly this, floor offset and all, so a tile keeps the same cloud sample whichever floor
    // it is seen from - and the shadows slide past the player as they walk instead of riding
    // along with the camera.
    m_lightView->setCloudOrigin({ cameraPosition.x - m_virtualCenterOffset.x,
                                  cameraPosition.y - m_virtualCenterOffset.y });

    // onTileUpdate flips this when an opaque thing comes or goes. The stock reset path runs
    // inside isCompletelyCovered(), which this pass never calls, so without it a roof answer
    // would stay cached long after the roof itself was gone.
    const bool resetIndoorCache = m_resetIndoorCache;
    m_resetIndoorCache = false;

    for (int_fast8_t z = m_floorMax; z >= m_floorMin; --z) {
        const float fadeLevel = getFadeLevel(z);
        if (fadeLevel == 0.f) break;

        Position _camera = cameraPosition;
        const bool alwaysTransparent = m_floorViewMode == Otc::ALWAYS_WITH_TRANSPARENCY && z < m_cachedFirstVisibleFloor && _camera.coveredUp(cameraPosition.z - z);

        const auto& map = m_floors[z].cachedVisibleTiles;

        if (m_fadeType != FadeType::FADE_OUT || fadeLevel == 1.f) {
            for (const auto& tile : map.shades) {
                if (alwaysTransparent && tile->getPosition().isInRange(_camera, g_gameConfig.getTileTransparentFloorViewRange(), g_gameConfig.getTileTransparentFloorViewRange(), true))
                    continue;

                m_lightView->resetShade(transformPositionTo2D(tile->getPosition()));
            }
        }

        for (const auto& tile : map.tiles) {
            const auto& point = transformPositionTo2D(tile->getPosition());

            // Floors run deepest first, so the tile the player actually sees at this screen
            // position is the last to write its mark and wins the slot. firstFloor 0 asks "is
            // anything at all drawn above me", i.e. am I under a roof - a different question
            // from the m_cachedFirstVisibleFloor queries elsewhere, cached in its own bits.
            if (resetIndoorCache)
                tile->resetCoveredCache(0);

            m_lightView->markIndoor(point, tile->isCovered(0));

            tile->drawLight(point, m_lightView.get());
        }

        for (const auto& missile : g_map.getFloorMissiles(z))
            missile->draw(transformPositionTo2D(missile->getPosition()), false, m_lightView.get());
    }
}

void MapView::drawCreatureInformation() {
    PROFILE_ZONE(DrawCreatureInfo);
    // This pool is drawn after the map framebuffer has already been blitted, so nothing in it
    // inherits the map's magnification. Track it explicitly, otherwise names and bars keep their
    // native size while the sprites under them grow, and shrink away to nothing on a large panel.
    if (m_scaleCreatureInformation) {
        const float density = g_window.getDisplayDensity();
        g_app.setCreatureInformationScale(density > 0.f ? getMapMagnification() / density : getMapMagnification());
    }

    g_drawPool.scale(g_app.getCreatureInformationScale());

    uint32_t ownFlags = Otc::DrawThings;
    if (m_drawNames && m_drawOwnName) { ownFlags |= Otc::DrawNames; }
    if (m_drawHealthBars && m_drawOwnHealthBars) { ownFlags |= Otc::DrawBars; }
    if (m_drawManaBar && m_drawOwnManaBar) { ownFlags |= Otc::DrawManaBar; }
    if (m_drawHarmony && m_drawOwnHarmonyBar) { ownFlags |= Otc::DrawHarmony; }
    if (m_drawOwnMarks) { ownFlags |= Otc::DrawMarks | Otc::DrawNpcIcons; }

    uint32_t otherFlags = Otc::DrawThings;
    if (m_drawNames && m_drawOtherNames) { otherFlags |= Otc::DrawNames; }
    if (m_drawHealthBars && m_drawOtherHealthBars) { otherFlags |= Otc::DrawBars; }
    if (m_drawManaBar) { otherFlags |= Otc::DrawManaBar; }
    if (m_drawHarmony) { otherFlags |= Otc::DrawHarmony; }
    if (m_drawOtherMarks) { otherFlags |= Otc::DrawMarks; }
    if (m_drawOtherNpcIcons) { otherFlags |= Otc::DrawNpcIcons; }

    Position _camera = m_posInfo.camera;
    const bool alwaysTransparent = m_floorViewMode == Otc::ALWAYS_WITH_TRANSPARENCY && _camera.coveredUp(m_posInfo.camera.z - m_floorMin);
    for (const auto& [uid, creature] : g_map.getCreatures()) {
        const auto& tile = creature->getTile();
        if (!tile || !m_posInfo.isInRange(creature->getPosition()))
            continue;

        bool isCovered = tile->isCovered(alwaysTransparent ? m_floorMin : m_cachedFirstVisibleFloor);
        if (alwaysTransparent && isCovered) {
            const bool inRange = creature->getPosition().isInRange(m_posInfo.camera, g_gameConfig.getTileTransparentFloorViewRange(), g_gameConfig.getTileTransparentFloorViewRange(), true);
            isCovered = !inRange;
        }

        creature->setCovered(isCovered);

        creature->drawInformation(m_posInfo, transformPositionTo2D(creature->getPosition()), creature->isLocalPlayer() ? ownFlags : otherFlags);
    }
}

void MapView::drawForeground(const Rect& rect)
{
    g_drawPool.scale(g_app.getStaticTextScale());
    for (const auto& staticText : g_map.getStaticTexts()) {
        if (staticText->getMessageMode() == Otc::MessageNone)
            continue;

        const auto& pos = staticText->getPosition();
        if (pos.z != m_posInfo.camera.z && staticText->getMessageMode() == Otc::MessageNone)
            continue;

        Point p = transformPositionTo2D(pos) - m_posInfo.drawOffset;
        p.x *= m_posInfo.horizontalStretchFactor;
        p.y *= m_posInfo.verticalStretchFactor;
        p += rect.topLeft();
        staticText->drawText(p.scale(g_app.getStaticTextScale()), rect);
    }

    g_drawPool.scale(g_app.getAnimatedTextScale());
    for (const auto& animatedText : g_map.getAnimatedTexts()) {
        const auto& pos = animatedText->getPosition();

        if (pos.z != m_posInfo.camera.z)
            continue;

        auto p = transformPositionTo2D(pos) - m_posInfo.drawOffset;
        p.x *= m_posInfo.horizontalStretchFactor;
        p.y *= m_posInfo.verticalStretchFactor;
        p += rect.topLeft();
        animatedText->drawText(p, rect);
    }

    g_drawPool.scale(1.f);
    for (const auto& tile : m_foregroundTiles) {
        const auto& dest = transformPositionTo2D(tile->getPosition());

        Point p = dest - m_posInfo.drawOffset;
        p.x *= m_posInfo.horizontalStretchFactor;
        p.y *= m_posInfo.verticalStretchFactor;
        p += rect.topLeft();
        p.y += 5;

        tile->drawTexts(p);
    }
}

void MapView::updateVisibleTiles()
{
    PROFILE_ZONE(UpdateVisibleTiles);
    // there is no tile to render on invalid positions
    if (!m_posInfo.camera.isValid())
        return;

    // clear current visible tiles cache
    do {
        m_floors[m_floorMin].cachedVisibleTiles.clear();
    } while (++m_floorMin <= m_floorMax);

    m_lockedFirstVisibleFloor = m_floorViewMode == Otc::LOCKED ? m_posInfo.camera.z : -1;

    const auto prevFirstVisibleFloor = m_cachedFirstVisibleFloor;

    if (m_lastCameraPosition != m_posInfo.camera) {
        if (m_lastCameraPosition.z != m_posInfo.camera.z) {
            onFloorChange(m_posInfo.camera.z, m_lastCameraPosition.z);
        }

        const auto cachedFirstVisibleFloor = calcFirstVisibleFloor(m_floorViewMode != Otc::ALWAYS);
        m_cachedFirstVisibleFloor = cachedFirstVisibleFloor;
        m_cachedLastVisibleFloor = std::max<uint8_t>(cachedFirstVisibleFloor, calcLastVisibleFloor());

        m_floorMin = m_floorMax = m_posInfo.camera.z;
    }

    auto cachedFirstVisibleFloor = m_cachedFirstVisibleFloor;
    if (m_floorViewMode == Otc::ALWAYS_WITH_TRANSPARENCY || canFloorFade()) {
        cachedFirstVisibleFloor = calcFirstVisibleFloor(false);
    }

    // Fading System by Kondra https://github.com/OTCv8/otclientv8
    if (!m_lastCameraPosition.isValid() || m_lastCameraPosition.z != m_posInfo.camera.z || m_lastCameraPosition.distance(m_posInfo.camera) >= 3) {
        m_fadeType = FadeType::NONE;
        for (int iz = m_cachedLastVisibleFloor; iz >= cachedFirstVisibleFloor; --iz) {
            m_floors[iz].fadingTimers.restart(m_floorFading);
        }
    } else if (prevFirstVisibleFloor < m_cachedFirstVisibleFloor) { // hiding new floor
        m_fadeType = FadeType::FADE_OUT;
        for (int iz = prevFirstVisibleFloor; iz < m_cachedFirstVisibleFloor; ++iz) {
            const int shift = std::max<int>(0, m_floorFading - m_floors[iz].fadingTimers.ticksElapsed());
            m_floors[iz].fadingTimers.restart(shift);
        }
    } else if (prevFirstVisibleFloor > m_cachedFirstVisibleFloor) { // showing floor
        m_fadeType = FadeType::FADE_IN;
        m_fadeFinish = false;
        for (int iz = m_cachedFirstVisibleFloor; iz < prevFirstVisibleFloor; ++iz) {
            const int shift = std::max<int>(0, m_floorFading - m_floors[iz].fadingTimers.ticksElapsed());
            m_floors[iz].fadingTimers.restart(shift);
        }
    }

    m_lastCameraPosition = m_posInfo.camera;
    destroyHighlightTile();

    const bool checkIsCovered = !m_drawCoveredThings && getFadeLevel(m_cachedFirstVisibleFloor) == 1.f;

    // cache visible tiles in draw order
    // draw from last floor (the lower) to first floor (the higher)
    const uint32_t numDiagonals = m_drawDimension.width() + m_drawDimension.height() - 1;

    auto processDiagonalRange = [&](std::vector<FloorData>& floors, uint32_t start, uint32_t end) {
        for (int_fast32_t iz = m_cachedLastVisibleFloor; iz >= cachedFirstVisibleFloor; --iz) {
            auto& floor = floors[iz].cachedVisibleTiles;

            for (uint_fast32_t diagonal = start; diagonal < end; ++diagonal) {
                const auto advance = (static_cast<size_t>(diagonal) >= static_cast<size_t>(m_drawDimension.height())) ? diagonal - static_cast<size_t>(m_drawDimension.height()) : 0;
                for (int iy = diagonal - advance, ix = advance; iy >= 0 && ix < m_drawDimension.width(); --iy, ++ix) {
                    auto tilePos = m_posInfo.camera.translated(ix - m_virtualCenterOffset.x, iy - m_virtualCenterOffset.y);
                    tilePos.coveredUp(m_posInfo.camera.z - iz);

                    if (const auto& tile = g_map.getTile(tilePos)) {
                        if (!tile->isDrawable()) continue;

                        bool addTile = true;

                        if (checkIsCovered && tile->isCompletelyCovered(m_cachedFirstVisibleFloor, m_resetCoveredCache)) {
                            if (m_floorViewMode != Otc::ALWAYS_WITH_TRANSPARENCY || (tilePos.z < m_posInfo.camera.z && tile->isCovered(m_cachedFirstVisibleFloor))) {
                                addTile = false;
                            }
                        }

                        if (addTile) {
                            floor.tiles.emplace_back(tile);
                            tile->onAddInMapView();
                        }

                        if (isDrawingLights() && tile->canShade()) {
                            floor.shades.emplace_back(tile);
                        }

                        if (addTile || !floor.shades.empty()) {
                            if (iz < m_floorMin)
                                m_floorMin = iz;
                            else if (iz > m_floorMax)
                                m_floorMax = iz;
                        }
                    }
                }
            }
        }
    };

    if (m_multithreading) {
        static const int numThreads = g_asyncDispatcher.get_thread_count();
        static BS::multi_future<void> tasks(numThreads);
        tasks.clear();

        const auto chunkSize = (numDiagonals + numThreads - 1) / numThreads;

        for (auto i = 0; i < numThreads; ++i) {
            const auto start = i * chunkSize;
            const auto end = start + chunkSize;

            for (auto& floor : m_floorThreads[i])
                floor.cachedVisibleTiles.clear();

            tasks.emplace_back(g_asyncDispatcher.submit_task([=, this] {
                processDiagonalRange(m_floorThreads[i], start, end);
            }));
        }

        tasks.wait();

        for (int fi = 0, s = m_floors.size(); fi < s; ++fi) {
            auto& floor = m_floors[fi];
            floor.cachedVisibleTiles.clear();

            for (auto i = 0; i < numThreads; ++i) {
                auto& floorThread = m_floorThreads[i][fi];
                floor.cachedVisibleTiles.tiles.insert(floor.cachedVisibleTiles.tiles.end(), std::make_move_iterator(floorThread.cachedVisibleTiles.tiles.begin()), std::make_move_iterator(floorThread.cachedVisibleTiles.tiles.end()));
                floor.cachedVisibleTiles.shades.insert(floor.cachedVisibleTiles.shades.end(), std::make_move_iterator(floorThread.cachedVisibleTiles.shades.begin()), std::make_move_iterator(floorThread.cachedVisibleTiles.shades.end()));
            }
        }
    } else {
        processDiagonalRange(m_floors, 0, numDiagonals);
    }

    m_updateVisibleTiles = false;
    m_resetCoveredCache = false;
    updateHighlightTile(m_mousePosition);
}

void MapView::updateRect(const Rect& rect) {
    if (m_posInfo.camera != getCameraPosition()) {
        m_posInfo.camera = getCameraPosition();
        requestUpdateVisibleTiles();
        requestUpdateMapPosInfo();
    }

    // updateGeometry changes the geometry at once but can only queue the framebuffer resize, and
    // g_mainDispatcher runs a callback inline only on the main thread - setAntiAliasingMode reaches
    // it from Lua on the map thread, so the resize lands a frame or two later. Notice when the
    // buffer finally catches up and force a repaint: on a static scene the content hash never
    // changes, so the pool would otherwise keep blitting whatever the buffer happened to hold.
    if (const auto& fb = m_pool->getFrameBuffer(); fb && fb->isValid()) {
        const auto& fbSize = fb->getSize();
        const bool bufferChanged = fbSize != m_lastFrameBufferSize;
        if (bufferChanged) {
            m_lastFrameBufferSize = fbSize;
            requestUpdateMapPosInfo();
        }

        // Repaint on the frame the buffer changes - it is a brand new, blank texture - and then for
        // as long as it is still not the one the geometry describes. The flag is set from one thread
        // and consumed on another, so a single request can be lost; if it is, a static scene has no
        // other reason to redraw and keeps blitting the stale frame.
        if (bufferChanged || fbSize != m_rectDimension.size())
            m_pool->repaint();
    }

    if (m_posInfo.rect != rect || m_updateMapPosInfo) {
        m_updateMapPosInfo = false;

        m_posInfo.rect = rect;

        // updateGeometry is otherwise only reached from setVisibleDimension/setAntiAliasingMode,
        // so without this the buffer resolution would never follow a resize. It only fires when the
        // ideal multiple actually changes - a handful of times across a whole splitter drag, not
        // once per pixel - because rebuilding the framebuffer is not cheap.
        if (getIdealRenderScale(m_visibleDimension) != m_posInfo.scaleFactor)
            updateGeometry(m_visibleDimension);

        m_posInfo.srcRect = calcFramebufferSource(rect.size());

        // Never sample past the texture that exists right now. While the resize is still in flight
        // the source rect describes the buffer we asked for, not the one bound, and reading beyond
        // it is what tore streaks down the right and bottom edges.
        if (m_lastFrameBufferSize.isValid())
            m_posInfo.srcRect &= Rect(0, 0, m_lastFrameBufferSize);

        m_posInfo.drawOffset = m_posInfo.srcRect.topLeft();
        m_posInfo.horizontalStretchFactor = rect.width() / static_cast<float>(m_posInfo.srcRect.width());
        m_posInfo.verticalStretchFactor = rect.height() / static_cast<float>(m_posInfo.srcRect.height());

        auto mousePoint = g_window.getMousePosition();
        if (g_app.getHUDScale() != DEFAULT_DISPLAY_DENSITY) {
            mousePoint.scale(g_app.getHUDScale());
        }

        const auto& mousePos = getPosition(mousePoint * g_window.getDisplayDensity());
        if (mousePos != m_mousePosition)
            onMouseMove(m_mousePosition = mousePos, true);
    }
}

void MapView::updateGeometry(const Size& visibleDimension)
{
    float scaleFactor = getIdealRenderScale(visibleDimension);

    auto maxAwareRange = std::max<size_t>(visibleDimension.width(), visibleDimension.height());

    const auto optimize = maxAwareRange > 115;

    m_pool->agroup(optimize);
    m_drawCoveredThings = !optimize;
    m_multithreading = optimize;
    while (maxAwareRange > 100) {
        maxAwareRange /= 2;
        scaleFactor /= 2;
    }

    const auto& drawDimension = visibleDimension + 3;
    const int maxTextureSize = g_graphics.getMaxTextureSize();

    const auto bufferSizeFor = [&](const float scale) {
        return drawDimension * static_cast<uint16_t>(g_gameConfig.getSpriteSize() * scale);
    };

    // Step the multiple down rather than bailing out: a view too large for the ideal scale is
    // still perfectly drawable at a smaller one, just not as close to a pixel-exact blit.
    auto bufferSize = bufferSizeFor(scaleFactor);
    while (scaleFactor > 1.f && (bufferSize.width() > maxTextureSize || bufferSize.height() > maxTextureSize)) {
        scaleFactor -= 1.f;
        bufferSize = bufferSizeFor(scaleFactor);
    }

    if (bufferSize.width() > maxTextureSize || bufferSize.height() > maxTextureSize) {
        g_logger.traceError("reached max zoom out");
        return;
    }

    m_pool->setScaleFactor(scaleFactor);

    m_posInfo.scaleFactor = scaleFactor;

    const uint16_t tileSize = g_gameConfig.getSpriteSize() * scaleFactor;

    m_visibleDimension = visibleDimension;
    m_drawDimension = drawDimension;
    m_tileSize = tileSize;
    m_virtualCenterOffset = (drawDimension / 2 - Size(1)).toPoint();
    m_rectDimension = { 0, 0, bufferSize };

    if (m_lightView->isEnabled()) {
        Size lightSize = g_map.getAwareRange().dimension();
        if (drawDimension > lightSize)
            lightSize = drawDimension;

        m_lightView->resize(lightSize, tileSize);
    }

    g_mainDispatcher.addEvent([this, bufferSize] {
        // A resized framebuffer is a brand new, blank texture, but the pool keeps reusing its
        // buffer for as long as its content hash says nothing changed. Without forcing a repaint
        // the grown area is never drawn into and the blit samples uninitialised memory - which
        // showed up as streaks down the right and bottom edges until the camera happened to move.
        if (m_pool->getFrameBuffer()->resize(bufferSize))
            m_pool->repaint();
    });

    const uint8_t left = std::min<uint8_t>(g_map.getAwareRange().left, (m_drawDimension.width() / 2) - 1);
    const uint8_t top = std::min<uint8_t>(g_map.getAwareRange().top, (m_drawDimension.height() / 2) - 1);
    const auto right = static_cast<uint8_t>(left + 1);
    const auto bottom = static_cast<uint8_t>(top + 1);

    m_posInfo.awareRange = { .left = left, .top = top, .right = right, .bottom = bottom };

    updateViewportDirectionCache();
    updateViewport();

    requestUpdateVisibleTiles();
    requestUpdateMapPosInfo();
}

void MapView::onCameraMove(const Point& /*offset*/)
{
    requestUpdateMapPosInfo();
    if (isFollowingCreature()) {
        updateViewport(m_followingCreature->isWalking() ? m_followingCreature->getDirection() : Otc::InvalidDirection);
    }
}

void MapView::onFloorChange(const uint8_t /*floor*/, const uint8_t /*previousFloor*/)
{
    updateLight();
}

void MapView::onGlobalLightChange(const Light& light)
{
    const auto& target = AmbientFade::resolve(light.color, light.intensity);

    if (!m_ambientSeeded) {
        // Nothing to fade from on the first value of the session - the map has never been lit,
        // and ramping up out of black over ten seconds would look like a bug at login.
        m_ambientSeeded = true;
        m_ambientFrom = m_ambientTo = target;
        m_ambientFading = false;
    } else {
        // Start from where the light is right now, not from the last value the server sent.
        // Updates land every 10 s while a fade runs for 10.2, so a new one nearly always
        // interrupts one in flight, and continuing from the interrupted midpoint is exactly
        // what makes consecutive fades read as a single ramp instead of a series of them.
        m_ambientFrom = blendedAmbient();
        m_ambientTo = target;
        m_ambientFading = true;
        m_ambientFadeTimer.restart();
    }

    updateLight();
}

AmbientFade::Value MapView::blendedAmbient() const
{
    if (!m_ambientFading)
        return m_ambientTo;

    return AmbientFade::blend(m_ambientFrom, m_ambientTo,
                              AmbientFade::progress(m_ambientFadeTimer.ticksElapsed()));
}

// Driven from drawFloor(), which is the always-drawn pane: the light pass switches itself off
// in broad daylight, so ticking there would leave the first fade out of day with nothing to
// start it. LightView's pixel cache is keyed on the colour's 8-bit form, so running this every
// frame only rebuilds the light grid on the frames a channel actually moves.
void MapView::updateAmbientFade()
{
    if (!m_ambientFading)
        return;

    if (m_ambientFadeTimer.ticksElapsed() >= AmbientFade::DURATION_MS) {
        m_ambientFading = false;
        m_ambientFrom = m_ambientTo;
    }

    updateLight();
}

void MapView::updateLight()
{
    // Underground is not "indoors": there is no sky being blocked, and the dark ambience down
    // there is the point rather than something to attenuate further. The official client draws
    // the same line at the sea floor - below it the whole light grid starts from black, and
    // neither the cloud field nor the roof factor runs at all.
    const bool underground = getCameraPosition().z > g_gameConfig.getMapSeaFloor();
    const float attenuation = underground ? 0.f : m_cloudsIndoorIntensity;

    // Underground the world light is gone outright rather than faded away: a floor change is
    // not a time of day, and a ten-second ramp down a ladder would read as a bug. Everywhere
    // else this is the cross-faded world light with its level folded into the colour, which is
    // the form the ambient lift below expects - it works on a finished 8-bit colour, exactly
    // as the official client's does.
    const AmbientFade::Value world = blendedAmbient();
    const Color worldColor = underground ? Color::black
                                         : world.base * (world.intensity / static_cast<float>(UINT8_MAX));

    const Color ambientColor = AmbientLight::lift(worldColor, AmbientLight::level(m_minimumAmbientLight),
                                                  underground ? AmbientLight::TINT_UNDERGROUND
                                                              : AmbientLight::TINT_SURFACE);

    // A roofed tile is shaded after the ambience is mixed in, not before, and by the square of
    // what an open tile keeps. Both are the official client's ordering, and together they mean
    // Ambient Light is not a floor an interior bottoms out at - an interior loses its share of
    // the ambience along with everything else. Torches still work indoors because this shades
    // the light a tile receives rather than painting over the finished scene, where a multiply
    // could only ever darken what it covers.
    const Color indoorColor = ambientColor * AmbientLight::indoorFactor(attenuation);

    m_lightView->setGlobalLight(ambientColor, AmbientLight::brightestChannel(ambientColor));
    m_lightView->setIndoorLight(indoorColor, AmbientLight::brightestChannel(indoorColor));
    m_lightView->setCloudShading(1.f - AmbientLight::keptUnderAttenuation(attenuation));
    m_lightView->setEnabled(isDrawingLights());
}

void MapView::onTileUpdate(const Position& pos, const ThingPtr& thing, const Otc::Operation op)
{
    if (thing && thing->isOpaque()) {
        if (op == Otc::OPERATION_REMOVE)
            m_resetCoveredCache = true;

        // A roof going up changes the indoor shading exactly as much as one coming down, and
        // nothing else invalidates the firstFloor-0 answers that pass caches.
        m_resetIndoorCache = true;
    }

    if (op == Otc::OPERATION_CLEAN) {
        if (m_lastHighlightTile && m_lastHighlightTile->getPosition() == pos)
            m_lastHighlightTile = nullptr;

        requestUpdateVisibleTiles();
    }
}

void MapView::onFadeInFinished()
{
    requestUpdateVisibleTiles();
}

// isVirtualMove is when the mouse is stopped, but the camera moves,
// so the onMouseMove event is triggered by sending the new tile position that the mouse is in.
void MapView::onMouseMove(const Position& mousePos, const bool /*isVirtualMove*/)
{
    { // Highlight Target System
        destroyHighlightTile();
        updateHighlightTile(mousePos);
    }

    if (!g_mouse.isCursorChanged()) {
        bool cursorSet = false;
        if (m_cursorAnimations) {
            if (const auto& tile = getTopTile(mousePos)) {
                if (const auto& creature = tile->getTopCreature()) {
                    if (creature->isMonster()) {
                        int id = g_mouse.getCursorId("attack");
                        if (id != -1) {
                            g_window.setMouseCursor(id);
                            cursorSet = true;
                        }
                    } else if (creature->isNpc()) {
                        int id = g_mouse.getCursorId("talk");
                        if (id != -1) {
                            g_window.setMouseCursor(id);
                            cursorSet = true;
                        }
                    }
                }
                
                if (!cursorSet) {
                    if (const auto& thing = tile->getTopUseThing()) {
                        // Check for both containers and corpses (corpses might not always be containers)
                        if (thing->isContainer() || thing->isLyingCorpse()) {
                            // Use quicklootcursor for dead creatures when quickloot is active
                            const bool isDeadCreature = thing->isLyingCorpse();
                            const bool quickLootActive = g_game.getFeature(Otc::GameThingQuickLoot);
                            const char* cursorName = (isDeadCreature && quickLootActive) ? "quicklootcursor" : "containercursor";
                            
                            int id = g_mouse.getCursorId(cursorName);
                            if (id != -1) {
                                g_window.setMouseCursor(id);
                                cursorSet = true;
                            }
                        }
                    }
                }

                if (!cursorSet) {
                    if (const auto& thing = tile->getTopUseThing()) {
                        if (thing->isUsable()) {
                            int id = g_mouse.getCursorId("pointinghand");
                            if (id != -1) {
                                g_window.setMouseCursor(id);
                                cursorSet = true;
                            }
                        }
                    }
                }

                if (!cursorSet && tile->isWalkable()) {
                    int id = g_mouse.getCursorId("walk");
                    if (id != -1) {
                        g_window.setMouseCursor(id);
                        cursorSet = true;
                    }
                }
            }
        }

        if (!cursorSet) {
            int id = g_mouse.getCursorId("default");
            if (id != -1)
                g_window.setMouseCursor(id);
            else
                g_window.restoreMouseCursor();
        }
    }
}

void MapView::onKeyRelease(const InputEvent& inputEvent)
{
    const bool shiftPressed = inputEvent.keyboardModifiers & Fw::KeyboardShiftModifier;
    if (shiftPressed != m_shiftPressed) {
        m_shiftPressed = shiftPressed;
        onMouseMove(m_mousePosition);
    }
}

void MapView::onMapCenterChange(const Position& /*newPos*/, const Position& /*oldPos*/)
{
    requestUpdateVisibleTiles();
}

void MapView::lockFirstVisibleFloor(const uint8_t firstVisibleFloor)
{
    m_lockedFirstVisibleFloor = firstVisibleFloor;
    requestUpdateVisibleTiles();
}

void MapView::unlockFirstVisibleFloor()
{
    m_lockedFirstVisibleFloor = -1;
    requestUpdateVisibleTiles();
}

void MapView::setVisibleDimension(const Size& visibleDimension)
{
    if (visibleDimension == m_visibleDimension)
        return;

    if (visibleDimension.width() % 2 != 1 || visibleDimension.height() % 2 != 1) {
        g_logger.traceError("visible dimension must be odd");
        return;
    }

    if (visibleDimension < 3) {
        g_logger.traceError("reach max zoom in");
        return;
    }

    const auto& awareRangeSize = Size(g_map.getAwareRange().left * 2, g_map.getAwareRange().top * 2);

    m_drawViewportEdge = m_forceDrawViewportEdge;
    if (visibleDimension.width() > awareRangeSize.width() || visibleDimension.height() > awareRangeSize.height()) {
        if (m_limitVisibleDimension)
            return;
        m_drawViewportEdge = true;
    }

    updateGeometry(visibleDimension);
}

void MapView::setFloorViewMode(const Otc::FloorViewMode floorViewMode)
{
    m_floorViewMode = floorViewMode;

    resetLastCamera();
    requestUpdateVisibleTiles();
}

// Upper bound on the render multiple. At 4 a 15x11 view is a 2304x1792 buffer (~16 MB), which
// every GPU this client runs on can hold, and by then the residual blit ratio is within 12% of
// 1:1 - past that there is nothing left to win.
static constexpr float MAX_RENDER_SCALE = 4.f;

// The map is rasterised into an offscreen buffer at an integer number of buffer pixels per sprite
// pixel, then blitted to the panel. Any non-integer ratio in that final blit is what smears the
// art: neighbouring destination pixels get different bilinear weights, so one column of a sprite
// edge is crisp and the next is half-grey. Picking the multiple closest to the panel's own size
// keeps that ratio within 1 +/- 0.5/N of pixel-exact, so a bigger panel lands *closer* to 1:1 -
// the opposite of a fixed multiple, which drifts further out the more the map is enlarged.
float MapView::getIdealRenderScale(const Size& visibleDimension) const
{
    // "Smooth Retro" keeps its meaning as an extra supersampling step on top of the ideal.
    const float supersample = m_antiAliasingMode == Otc::ANTIALIASING_SMOOTH_RETRO ? 2.f : 1.f;

    const int nativeWidth = visibleDimension.width() * g_gameConfig.getSpriteSize();
    if (nativeWidth <= 0 || m_posInfo.rect.isEmpty())
        return supersample;

    const float ratio = m_posInfo.rect.width() / static_cast<float>(nativeWidth);

    // Hysteresis. Rounding alone flips between two multiples the moment the panel sits on a .5
    // boundary, and the panel does sit there at some sizes - every flip rebuilds the framebuffer,
    // so the map tears continuously for as long as it lasts. Hold the multiple already in effect
    // until the panel is clearly past the halfway point; the dead zone is in whole steps, which is
    // supersample-sized because that is how much the total moves per step. The margin over the
    // natural half-step is deliberately small - it only has to swallow jitter, not shift the choice.
    const float applied = m_posInfo.scaleFactor;
    if (applied >= 1.f && std::abs(ratio * supersample - applied) <= 0.55f * supersample)
        return applied;

    return std::clamp<float>(std::round(ratio) * supersample, 1.f, MAX_RENDER_SCALE);
}

float MapView::getMapMagnification() const
{
    const int nativeWidth = m_visibleDimension.width() * g_gameConfig.getSpriteSize();
    if (nativeWidth <= 0 || m_posInfo.rect.isEmpty())
        return DEFAULT_DISPLAY_DENSITY;

    return m_posInfo.rect.width() / static_cast<float>(nativeWidth);
}

void MapView::setScaleCreatureInformation(const bool enable)
{
    m_scaleCreatureInformation = enable;

    // Nothing else writes this global, so hand it back to its default when switching off.
    if (!enable)
        g_app.setCreatureInformationScale(DEFAULT_DISPLAY_DENSITY);
}

void MapView::setAntiAliasingMode(const Otc::AntialiasingMode mode)
{
    m_antiAliasingMode = mode;

    g_mainDispatcher.addEvent([=, this] {
        m_pool->getFrameBuffer()->setSmooth(mode != Otc::ANTIALIASING_DISABLED);
    });

    updateGeometry(m_visibleDimension);
}

void MapView::followCreature(const CreaturePtr& creature)
{
    if (creature == m_followingCreature)
        return;

    if (!creature) {
        setCameraPosition(m_followingCreature ? m_followingCreature->getPosition() : g_map.getCentralPosition());
        return;
    }

    if (m_followingCreature) m_followingCreature->setCameraFollowing(false);
    m_followingCreature = creature;
    m_followingCreature->setCameraFollowing(true);
    m_lastCameraPosition = {};
    m_follow = true;

    requestUpdateVisibleTiles();
}

void MapView::setCameraPosition(const Position& pos)
{
    if (m_followingCreature)
        m_followingCreature->setCameraFollowing(false);

    m_follow = false;
    m_customCameraPosition = pos;
    m_followingCreature = nullptr;
    requestUpdateVisibleTiles();
}

Position MapView::getPosition(const Point& mousePos)
{
    const auto newMousePos = mousePos * g_window.getDisplayDensity();
    if (!m_posInfo.rect.contains(newMousePos))
        return {};

    const auto& relativeMousePos = newMousePos - m_posInfo.rect.topLeft();
    return getPosition(relativeMousePos, m_posInfo.rect.size());
}

Position MapView::getPosition(const Point& point, const Size& mapSize)
{
    const auto& cameraPosition = getCameraPosition();

    // if we have no camera, its impossible to get the tile
    if (!cameraPosition.isValid())
        return {};

    const auto& srcRect = calcFramebufferSource(mapSize);
    const float sh = srcRect.width() / static_cast<float>(mapSize.width());
    const float sv = srcRect.height() / static_cast<float>(mapSize.height());

    const auto& framebufferPos = Point(point.x * sh, point.y * sv);
    const auto& centerOffset = (framebufferPos + srcRect.topLeft()) / m_tileSize;

    const auto& tilePos2D = m_virtualCenterOffset - m_drawDimension.toPoint() + centerOffset + Point(2);
    if (tilePos2D.x + cameraPosition.x < 0 && tilePos2D.y + cameraPosition.y < 0)
        return {};

    const auto& position = Position(tilePos2D.x, tilePos2D.y, 0) + cameraPosition;

    if (!position.isValid())
        return {};

    return position;
}

void MapView::move(const int32_t x, const int32_t y)
{
    m_moveOffset.x += x;
    m_moveOffset.y += y;

    int32_t tmp = m_moveOffset.x / g_gameConfig.getSpriteSize();
    bool requestTilesUpdate = false;
    if (tmp != 0) {
        m_customCameraPosition.x += tmp;
        m_moveOffset.x %= g_gameConfig.getSpriteSize();
        requestTilesUpdate = true;
    }

    tmp = m_moveOffset.y / g_gameConfig.getSpriteSize();
    if (tmp != 0) {
        m_customCameraPosition.y += tmp;
        m_moveOffset.y %= g_gameConfig.getSpriteSize();
        requestTilesUpdate = true;
    }

    requestUpdateMapPosInfo();

    if (requestTilesUpdate)
        requestUpdateVisibleTiles();

    onCameraMove(m_moveOffset);
}

Rect MapView::calcFramebufferSource(const Size& destSize)
{
    Point drawOffset = ((m_drawDimension - m_visibleDimension - Size(1)).toPoint() / 2) * m_tileSize;
    if (isFollowingCreature())
        drawOffset += m_followingCreature->getWalkOffset() * m_pool->getScaleFactor();
    else if (!m_moveOffset.isNull())
        drawOffset += m_moveOffset * m_pool->getScaleFactor();

    const auto& srcVisible = m_visibleDimension * m_tileSize;

    Size srcSize = destSize;
    // Preserve the classic fractional zoom used by the UI. The framebuffer may be
    // rendered at a higher integer resolution, but the sampled area must still
    // follow the user's fractional zoom or tiles are visibly oversized.
    srcSize.scale(m_zoomFraction < 1.f ? srcVisible * m_zoomFraction : srcVisible, Fw::KeepAspectRatio);
    drawOffset.x += (srcVisible.width() - srcSize.width()) / 2;
    drawOffset.y += (srcVisible.height() - srcSize.height()) / 2;

    return Rect(drawOffset, srcSize);
}

uint8_t MapView::calcFirstVisibleFloor(const bool checkLimitsFloorsView) const
{
    uint8_t z = g_gameConfig.getMapSeaFloor();
    // return forced first visible floor
    if (m_lockedFirstVisibleFloor != -1) {
        z = m_lockedFirstVisibleFloor;
    } else {
        // this could happens if the player is not known yet
        if (m_posInfo.camera.isValid()) {
            // if nothing is limiting the view, the first visible floor is 0
            uint8_t firstFloor = 0;

            // limits to underground floors while under sea level
            if (m_posInfo.camera.z > g_gameConfig.getMapSeaFloor())
                firstFloor = std::max<uint8_t >(m_posInfo.camera.z - g_gameConfig.getMapAwareUndergroundFloorRange(), g_gameConfig.getMapUndergroundFloorRange());

            // loop in 3x3 tiles around the camera
            for (int ix = -1; checkLimitsFloorsView && ix <= 1 && firstFloor < m_posInfo.camera.z; ++ix) {
                for (int iy = -1; iy <= 1 && firstFloor < m_posInfo.camera.z; ++iy) {
                    const auto& pos = m_posInfo.camera.translated(ix, iy);
                    const bool isLookPossible = g_map.isLookPossible(pos);

                    // process tiles that we can look through, e.g. windows, doors
                    if ((ix == 0 && iy == 0) || ((std::abs(ix) != std::abs(iy)) && isLookPossible)) {
                        Position upperPos = pos;
                        Position coveredPos = pos;

                        while (coveredPos.coveredUp() && upperPos.up() && upperPos.z >= firstFloor) {
                            // check tiles physically above
                            if (const TilePtr& tile = g_map.getTile(upperPos)) {
                                if (tile->limitsFloorsView(!isLookPossible)) {
                                    firstFloor = upperPos.z + 1;
                                    break;
                                }
                            }

                            // check tiles geometrically above
                            if (const TilePtr& tile = g_map.getTile(coveredPos)) {
                                if (tile->limitsFloorsView(isLookPossible)) {
                                    firstFloor = coveredPos.z + 1;
                                    break;
                                }
                            }
                        }
                    }
                }
            }

            z = firstFloor;
        }
    }

    // just ensure the that the floor is in the valid range
    z = std::clamp<int>(z, 0, g_gameConfig.getMapMaxZ());
    return z;
}

uint8_t MapView::calcLastVisibleFloor() const
{
    uint8_t z = g_gameConfig.getMapSeaFloor();

    // this could happen if the player is not known yet
    if (m_posInfo.camera.isValid()) {
        // view only underground floors when below sea level
        if (m_posInfo.camera.z > g_gameConfig.getMapSeaFloor())
            z = m_posInfo.camera.z + g_gameConfig.getMapAwareUndergroundFloorRange();
        else
            z = g_gameConfig.getMapSeaFloor();
    }

    if (m_lockedFirstVisibleFloor != -1)
        z = std::max<int>(m_lockedFirstVisibleFloor, z);

    // just ensure the that the floor is in the valid range
    z = std::clamp<int>(z, 0, g_gameConfig.getMapMaxZ());
    return z;
}

TilePtr MapView::getTopTile(Position tilePos) const
{
    if (!tilePos.isValid())
        return nullptr;

    // we must check every floor, from top to bottom to check for a clickable tile
    if (m_floorViewMode == Otc::ALWAYS_WITH_TRANSPARENCY && tilePos.isInRange(m_lastCameraPosition, g_gameConfig.getTileTransparentFloorViewRange(), g_gameConfig.getTileTransparentFloorViewRange()))
        return g_map.getTile(tilePos);

    tilePos.coveredUp(tilePos.z - m_cachedFirstVisibleFloor);
    for (uint8_t i = m_cachedFirstVisibleFloor; i <= m_floorMax; ++i) {
        const auto& tile = g_map.getTile(tilePos);
        if (tile && (tilePos.z == m_lastCameraPosition.z || tile->isClickable()))
            return tile;

        tilePos.coveredDown();
    }

    return nullptr;
}

void MapView::setShader(const std::string_view name, const float fadein, const float fadeout)
{
    const auto& shader = g_shaders.getShader(name);

    if (m_shader == shader)
        return;

    g_mainDispatcher.addEvent([=, this] {
        if (fadeout > 0.0f && m_shader) {
            m_nextShader = shader;
            m_shaderSwitchDone = false;
        } else {
            m_shader = shader;
            m_nextShader = nullptr;
            m_shaderSwitchDone = true;
        }

        m_fadeTimer.restart();
        m_fadeInTime = fadein;
        m_fadeOutTime = fadeout;

        if (shader) m_shaderPosition = getCameraPosition();
    });
}

bool MapView::isDrawingLights() const { return m_drawingLight && m_lightView->isDark(); }
void MapView::setDrawLights(const bool enable)
{
    m_drawingLight = enable;

    if (enable) {
        Size lightSize = g_map.getAwareRange().dimension();
        if (m_drawDimension > lightSize)
            lightSize = m_drawDimension;

        m_lightView->resize(lightSize, m_tileSize);
        requestUpdateVisibleTiles();
    }

    updateLight();
}

void MapView::updateViewportDirectionCache()
{
    for (uint8_t dir = Otc::North; dir <= Otc::InvalidDirection; ++dir) {
        auto& vp = m_viewPortDirection[dir];
        vp.top = m_posInfo.awareRange.top;
        vp.right = m_posInfo.awareRange.right;
        vp.bottom = vp.top;
        vp.left = vp.right;

        switch (dir) {
            case Otc::North:
            case Otc::South:
                vp.top += 1;
                vp.bottom += 1;
                break;

            case Otc::West:
            case Otc::East:
                vp.right += 1;
                vp.left += 1;
                break;

            case Otc::NorthEast:
            case Otc::SouthEast:
            case Otc::NorthWest:
            case Otc::SouthWest:
                vp.left += 1;
                vp.bottom += 1;
                vp.top += 1;
                vp.right += 1;
                break;

            case Otc::InvalidDirection:
                vp.left -= 1;
                vp.right -= 1;
                break;

            default:
                break;
        }
    }
}

Position MapView::getCameraPosition() { return isFollowingCreature() ? m_followingCreature->getPosition() : m_customCameraPosition; }
std::vector<CreaturePtr> MapView::getSightSpectators(const bool multiFloor)
{
    return g_map.getSpectatorsInRangeEx(getCameraPosition(), multiFloor, m_posInfo.awareRange.left - 1, m_posInfo.awareRange.right - 2, m_posInfo.awareRange.top - 1, m_posInfo.awareRange.bottom - 2);
}

std::vector<CreaturePtr> MapView::getSpectators(const bool multiFloor)
{
    return g_map.getSpectatorsInRangeEx(getCameraPosition(), multiFloor, m_posInfo.awareRange.left, m_posInfo.awareRange.right, m_posInfo.awareRange.top, m_posInfo.awareRange.bottom);
}

void MapView::setCrosshairTexture(const std::string& texturePath)
{
    m_crosshairTexture = texturePath.empty() ? nullptr : g_textures.getTexture(texturePath);
}

void MapView::updateHighlightTile(const Position& mousePos) {
    if (m_drawHighlightTarget) {
        if ((m_lastHighlightTile = (m_shiftPressed ? getTopTile(mousePos) : g_map.getTile(mousePos))))
            m_lastHighlightTile->select(m_shiftPressed ? TileSelectType::NO_FILTERED : TileSelectType::FILTERED);
    }
}

void MapView::destroyHighlightTile() {
    if (m_lastHighlightTile) {
        m_lastHighlightTile->unselect();
        m_lastHighlightTile = nullptr;
    }
}

void MapView::addForegroundTile(const TilePtr& tile) {
    if (std::ranges::find(m_foregroundTiles, tile) == m_foregroundTiles.end())
        m_foregroundTiles.emplace_back(tile);
}
void MapView::removeForegroundTile(const TilePtr& tile) {
    const auto it = std::ranges::find(m_foregroundTiles, tile);
    if (it == m_foregroundTiles.end())
        return;

    m_foregroundTiles.erase(it);
}
