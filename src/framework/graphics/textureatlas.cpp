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
#include "textureatlas.h"
#include "glutil.h"

#include "painter.h"
#include <framework/core/configmanager.h>

 // Extra padding around smooth textures to avoid sampling artifacts (in pixels)
static constexpr uint8_t SMOOTH_PADDING = 2;

// Limit texture size based on atlas size (Default: 35%)
static constexpr float MAX_ATLAS_TEXTURE_COVERAGE = 0.35f;

// Minimum texture size (including padding) to be cached in the atlas
// With SMOOTH_PADDING = 2 this results in 8 (4 + 2*2)
static constexpr int MIN_PADDED_ATLAS_TEXTURE_SIZE = 4 + SMOOTH_PADDING * 2;

TextureAtlas::TextureAtlas(Fw::TextureAtlasType type, int size, bool smoothSupport) :
    m_type(type),
    m_size({ std::min<int>(size, g_configs.getPublicConfig().graphics.maxAtlasSize) }) {
    createNewLayer(false);
    if (smoothSupport)
        createNewLayer(true);
}

void TextureAtlas::removeTexture(uint32_t uniqueId, bool smooth) {
    auto it = m_texturesCached.find(uniqueId);
    if (it == m_texturesCached.end()) {
        return;
    }

    it->second->enabled = false;

    // Drop any composite still pending for this region. It would otherwise paint the departing
    // texture into shelf space that has just been handed back for reuse - and, worse, set
    // `enabled` back to true on a region this call has just retired. Harmless while a composite
    // was executed the instant it was queued; not harmless now that one is executed later, by a
    // backend, from a description built here.
    if (const auto layerIndex = static_cast<size_t>(it->second->layer);
        layerIndex < m_filterGroups[smooth].layers.size()) {
        auto& pending = m_filterGroups[smooth].layers[layerIndex].textures;
        std::erase_if(pending, [region = it->second.get()](const PendingComposite& entry) {
            return entry.region == region;
        });
    }

    auto sizeKey = std::make_pair(it->second->width, it->second->height);
    m_filterGroups[smooth].inactiveTextures.try_emplace(sizeKey, std::vector<std::unique_ptr<AtlasRegion>>())
        .first->second.emplace_back(std::move(it->second));
    m_texturesCached.erase(it);
}

bool TextureAtlas::canAdd(const TexturePtr& texture) const {
    const auto textureWidth = texture->getWidth();
    const auto textureHeight = texture->getHeight();

    const int padding = texture->isSmooth() ? SMOOTH_PADDING : 0;
    const int paddedWidth = textureWidth + padding * 2;
    const int paddedHeight = textureHeight + padding * 2;

    if (paddedWidth <= 0 || paddedHeight <= 0 ||
        paddedWidth > m_size.width() || paddedHeight > m_size.height()) {
        return false; // don't cache
    }

    if (paddedWidth < MIN_PADDED_ATLAS_TEXTURE_SIZE ||
        paddedHeight < MIN_PADDED_ATLAS_TEXTURE_SIZE) {
        return false; // too small for atlas
    }

    const int64_t atlasPixelArea = static_cast<int64_t>(m_size.width()) * m_size.height();
    const int64_t maxTextureArea = static_cast<int64_t>(atlasPixelArea * MAX_ATLAS_TEXTURE_COVERAGE);

    // Maximum texture area relative to the atlas
    return static_cast<int64_t>(paddedWidth) * paddedHeight <= maxTextureArea;
}

void TextureAtlas::addTexture(const TexturePtr& texture) {
    if (!canAdd(texture))
        return;

    // The occupant's identity is its process-wide unique id, NOT its OpenGL name. The name was
    // the key until Phase 5, which made the atlas unusable on any backend that creates no GL
    // textures: every one of those reports name 0, so the whole client collided on one key.
    const auto textureId = texture->getUniqueId();
    const auto textureWidth = texture->getWidth();
    const auto textureHeight = texture->getHeight();

    auto& filterGroup = m_filterGroups[texture->isSmooth()];

    const auto sizeKey = std::make_pair(textureWidth, textureHeight);
    if (auto it = filterGroup.inactiveTextures.find(sizeKey);
        it != filterGroup.inactiveTextures.end()) {
        auto& pool = it->second;
        if (!pool.empty()) {
            auto regionInfo = std::move(pool.back());
            pool.pop_back();

            regionInfo->textureID = textureId;
            regionInfo->transformMatrixId = texture->getTransformMatrixId();
            texture->m_atlas[m_type] = regionInfo.get();

            filterGroup.layers[regionInfo->layer].textures.emplace_back(
                PendingComposite{ regionInfo.get(), texture });
            m_texturesCached.emplace(textureId, std::move(regionInfo));
            return;
        }
    }

    const int padding = texture->isSmooth() ? SMOOTH_PADDING : 0;
    const int paddedWidth = textureWidth + padding * 2;
    const int paddedHeight = textureHeight + padding * 2;

    auto bestRegion = findBestRegion(paddedWidth, paddedHeight, texture->isSmooth());
    if (!bestRegion) {
        // A layer stack that cannot grow leaves the texture unatlased, which is a supported
        // outcome rather than a failure - it draws standalone, exactly as one too large to pack
        // already does. Recursing regardless would spin forever now that growth can be refused.
        if (!canGrow(texture->isSmooth()))
            return;

        createNewLayer(texture->isSmooth());
        return addTexture(texture);
    }

    FreeRegion region = *bestRegion;
    splitRegion(region, paddedWidth, paddedHeight, texture->isSmooth());

    auto regionInfo = std::make_unique<AtlasRegion>(
        textureId,
        region.x + padding,
        region.y + padding,
        region.layer,
        static_cast<int16_t>(textureWidth),
        static_cast<int16_t>(textureHeight),
        texture->getTransformMatrixId(),
        m_filterGroups[texture->isSmooth()].layers[region.layer].framebuffer->getTexture().get(),
        m_filterGroups[texture->isSmooth()].layers[region.layer].target
    );

    texture->m_atlas[m_type] = regionInfo.get();
    filterGroup.layers[region.layer].textures.emplace_back(
        PendingComposite{ regionInfo.get(), texture });
    m_texturesCached.emplace(textureId, std::move(regionInfo));
}

bool TextureAtlas::canGrow(const bool smooth) const {
    // One layer is one render target handle, and the handle space reserves a fixed number of
    // them per (atlas, filter) group. Growing past that would mint a handle belonging to the
    // next group and silently composite into the wrong layer.
    return m_filterGroups[smooth].layers.size() < RenderHandles::ATLAS_LAYERS_PER_GROUP;
}

void TextureAtlas::createNewLayer(bool smooth) {
    const auto index = static_cast<uint32_t>(m_filterGroups[smooth].layers.size());
    if (index >= RenderHandles::ATLAS_LAYERS_PER_GROUP) {
        g_logger.warning("[atlas] {} {} layer stack is full at {} layers; further textures draw "
                         "standalone",
                         m_type == Fw::TextureAtlasType::MAP ? "map" : "foreground",
                         smooth ? "linear" : "nearest", index);
        return;
    }

    auto fbo = std::make_unique<FrameBuffer>();
    fbo->setAutoClear(false);
    fbo->setAutoResetState(true);
    fbo->setSmooth(smooth);
    fbo->resize(m_size);

    FreeRegion newRegion = { 0, 0, m_size.width(), m_size.height(), static_cast<int>(index) };

    auto& layer = m_filterGroups[smooth].layers.emplace_back();
    layer.framebuffer = std::move(fbo);
    layer.target = RenderHandles::atlasTarget(m_type, smooth, index);

    m_filterGroups[smooth].freeRegions.insert(newRegion);
    m_filterGroups[smooth].freeRegionsBySize[m_size.width() * m_size.height()].insert(newRegion);
}

void TextureAtlas::flush() {
    static CoordsBuffer buffer;
    for (auto i = -1; ++i < AtlasFilter::ATLAS_FILTER_COUNT;) {
        auto& group = m_filterGroups[i];

        const int pad = i == AtlasFilter::ATLAS_FILTER_LINEAR ? SMOOTH_PADDING : 0;

        for (auto& layer : group.layers) {
            if (!layer.textures.empty()) {
                layer.framebuffer->bind();
                glDisable(GL_BLEND);
                for (const auto& entry : layer.textures) {
                    auto* region = entry.region;
                    const int x = region->x;
                    const int y = region->y;
                    const int w = region->width;
                    const int h = region->height;

                    // The source's LIVE GL name rather than the one recorded when the region was
                    // allocated - the region no longer stores an OpenGL identity at all, and a
                    // texture re-created since then would have left a stale one behind.
                    const auto glId = entry.source->getId();

                    const Rect dest = { x - pad, y - pad, Size{ w + pad * 2, h + pad * 2 } };

                    g_painter->clearRect(Color::alpha, dest);

                    if (pad > 0) {
                        buffer.clear();
                        buffer.addRect(dest, { -pad, -pad, w + pad * 2, h + pad * 2 });
                        g_painter->setTexture(glId, region->transformMatrixId);
                        g_painter->drawCoords(buffer, DrawMode::TRIANGLE_STRIP);
                    }

                    buffer.clear();
                    buffer.addRect({ x, y, Size{ w, h } }, { 0, 0, w, h });
                    g_painter->setTexture(glId, region->transformMatrixId);
                    g_painter->drawCoords(buffer, DrawMode::TRIANGLE_STRIP);

                    region->enabled.store(true, std::memory_order_relaxed);
                }
                glEnable(GL_BLEND);
                layer.framebuffer->getTexture()->bumpContentRevision();
                layer.textures.clear();
                layer.framebuffer->release();
            }
        }
    }
}

const AtlasProgram* TextureAtlas::compileMaintenance()
{
    m_program.clear();

    CoordsBuffer buffer;

    for (auto i = -1; ++i < AtlasFilter::ATLAS_FILTER_COUNT;) {
        auto& group = m_filterGroups[i];

        const bool smooth = i == AtlasFilter::ATLAS_FILTER_LINEAR;
        const int pad = smooth ? SMOOTH_PADDING : 0;

        for (auto& layer : group.layers) {
            if (layer.textures.empty())
                continue;

            auto& pass = m_program.passes.emplace_back();
            pass.target = layer.target;
            // Keep, always. Atlas layer framebuffers are created with autoClear=false because
            // they ACCUMULATE: a clear here would erase every sprite packed in every earlier
            // frame, which is the whole reason LoadAction::Keep exists as a first-class thing.
            pass.load = LoadAction::Keep;
            pass.viewport = Rect(0, 0, m_size);
            pass.label = smooth ? "atlas-linear" : "atlas-nearest";

            // One packet emitter for all three draws below. Every one of them runs with blending
            // OFF and writes alpha, which is exactly the state `flush()` establishes with its
            // glDisable(GL_BLEND) bracket inside a framebuffer bound with alpha writing on.
            const auto emit = [&](const CoordsBuffer& coords, const bool textured,
                                  const TextureHandle texture, const uint16_t matrixId,
                                  const Color& color) {
                const auto slice = m_program.arena.append(coords);
                if (slice.isEmpty())
                    return;

                auto& packet = pass.packets.emplace_back();
                packet.vertexOffset = slice.offset;
                packet.vertexCount = slice.count;
                packet.textured = textured;
                packet.texture = texture;
                packet.textureMatrixId = matrixId;
                packet.color = color;
                packet.blendEnabled = false;
                packet.alphaWrite = true;
            };

            for (auto& entry : layer.textures) {
                auto* region = entry.region;

                const int x = region->x;
                const int y = region->y;
                const int w = region->width;
                const int h = region->height;

                const Rect dest = { x - pad, y - pad, Size{ w + pad * 2, h + pad * 2 } };

                const TextureHandle source{ entry.source->getUniqueId() };

                // `Painter::clearRect(Color::alpha, dest)`, as a packet. A scissored glClear and
                // an unblended transparent quad over the same integer-aligned rect write the
                // same zeros to the same pixels; the quad is the form a frame can describe.
                buffer.clear();
                buffer.addRect(dest);
                emit(buffer, false, {}, 0, Color::alpha);

                if (pad > 0) {
                    // The padding draw deliberately samples OUTSIDE the source, relying on
                    // clamp-to-edge to smear the border outwards so linear filtering inside the
                    // atlas never picks up a neighbour. Both backends sample this the same way:
                    // GL_CLAMP_TO_EDGE and MTLSamplerAddressModeClampToEdge are the non-repeat
                    // default on each.
                    buffer.clear();
                    buffer.addRect(dest, { -pad, -pad, w + pad * 2, h + pad * 2 });
                    emit(buffer, true, source, region->transformMatrixId, Color::white);
                }

                buffer.clear();
                buffer.addRect({ x, y, Size{ w, h } }, { 0, 0, w, h });
                emit(buffer, true, source, region->transformMatrixId, Color::white);

                // Copied, not moved: the pending list stays intact until commitMaintenance(),
                // so a frame the backend declines can still be drawn by the legacy path.
                m_program.sources.push_back(entry.source);
            }
        }
    }

    m_program.bindArena();

    return m_program.isEmpty() ? nullptr : &m_program;
}

void TextureAtlas::commitMaintenance()
{
    for (auto i = -1; ++i < AtlasFilter::ATLAS_FILTER_COUNT;) {
        for (auto& layer : m_filterGroups[i].layers) {
            if (layer.textures.empty())
                continue;

            for (const auto& entry : layer.textures)
                entry.region->enabled.store(true, std::memory_order_relaxed);

            // The layer's pixels have changed under a handle that did not. Say so, or a retained
            // target that samples this layer looks unchanged and is re-composited - the same
            // class of defect an advancing animation caused in Phase 3, reached through region
            // recycling instead: a destroyed sprite's shelf space is handed to a new sprite of
            // identical size, so the packet drawing it is byte-identical to the one that drew
            // its predecessor.
            layer.framebuffer->getTexture()->bumpContentRevision();
            layer.textures.clear();
        }
    }

    m_program.clear();
}

std::string TextureAtlas::getStats() const
{
    std::stringstream ss;
    ss << "size=" << m_size.width() << "x" << m_size.height()
        << " cached=" << m_texturesCached.size();

    for (int i = 0; i < ATLAS_FILTER_COUNT; ++i) {
        const auto& group = m_filterGroups[i];
        size_t textures = 0;
        for (const auto& layer : group.layers) {
            textures += layer.textures.size();
        }
        ss << " | " << (i == ATLAS_FILTER_LINEAR ? "linear" : "nearest")
            << ":layers=" << group.layers.size()
            << " textures=" << textures
            << " free=" << group.freeRegions.size()
            << " inactive=" << group.inactiveTextures.size();
    }

    return ss.str();
}
