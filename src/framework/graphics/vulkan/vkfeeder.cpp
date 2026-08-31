
// The whole Vulkan renderer is Win32-only for now (window surface), and the vulkan-headers
// dependency is windows-only in vcpkg.json. Outside Windows this file compiles to nothing,
// so it can sit unconditionally on the source list in CMakeLists.
#ifdef WIN32
#include "vkfeeder.h"

#include <framework/core/logger.h>
#include <framework/graphics/animatedtexture.h>
#include <framework/graphics/drawpool.h>
#include <framework/graphics/drawpoolmanager.h>
#include <framework/graphics/image.h>
#include <framework/graphics/texture.h>

#include <algorithm>
#include <cmath>
#include <exception>
#include <vector>

namespace
{
    // An affine mapping of pool space onto screen pixels. For pools with a GL framebuffer it
    // replaces the pair "draw into the FBO, then FBO to screen into rect dest from the src cutout";
    // for pools drawing directly it is the identity.
    struct PoolMapping
    {
        float sx{ 1.0f };
        float sy{ 1.0f };
        float tx{ 0.0f };
        float ty{ 0.0f };

        void apply(float& x, float& y) const
        {
            x = x * sx + tx;
            y = y * sy + ty;
        }
    };

    // The equivalent of what u_TransformMatrix does in the GL shader: the matrix lies in memory
    // row-wise, but GL reads it column-wise (upload without transposition), so the effective
    // matrix's columns are the stored ROWS. Hence the indices 0/3/6 and 1/4/7.
    void applyTransform(const float* d, float& x, float& y)
    {
        const float nx = d[0] * x + d[3] * y + d[6];
        const float ny = d[1] * x + d[4] * y + d[7];
        x = nx;
        y = ny;
    }

    VkRect2D clampRect(float x0, float y0, float x1, float y1, const VkExtent2D& extent)
    {
        x0 = std::max(0.0f, x0);
        y0 = std::max(0.0f, y0);
        x1 = std::min(static_cast<float>(extent.width), x1);
        y1 = std::min(static_cast<float>(extent.height), y1);

        VkRect2D rect{};
        if (x1 <= x0 || y1 <= y0)
            return rect; // empty scissor = nothing passes; the segment will be empty anyway

        rect.offset.x = static_cast<int32_t>(std::floor(x0));
        rect.offset.y = static_cast<int32_t>(std::floor(y0));
        rect.extent.width = static_cast<uint32_t>(std::ceil(x1) - rect.offset.x);
        rect.extent.height = static_cast<uint32_t>(std::ceil(y1) - rect.offset.y);
        return rect;
    }

    VkRect2D fullRect(const VkExtent2D& extent)
    {
        return VkRect2D{ { 0, 0 }, extent };
    }

    VkRect2D intersectRects(const VkRect2D& a, const VkRect2D& b)
    {
        const int32_t x0 = std::max(a.offset.x, b.offset.x);
        const int32_t y0 = std::max(a.offset.y, b.offset.y);
        const int32_t x1 = std::min(a.offset.x + static_cast<int32_t>(a.extent.width),
                                    b.offset.x + static_cast<int32_t>(b.extent.width));
        const int32_t y1 = std::min(a.offset.y + static_cast<int32_t>(a.extent.height),
                                    b.offset.y + static_cast<int32_t>(b.extent.height));

        VkRect2D rect{};
        if (x1 <= x0 || y1 <= y0)
            return rect;

        rect.offset = { x0, y0 };
        rect.extent = { static_cast<uint32_t>(x1 - x0), static_cast<uint32_t>(y1 - y0) };
        return rect;
    }

    // An open "window" of a temporary GL framebuffer: objects between bind and release have
    // framebuffer-LOCAL coordinates, and we only learn the destination rectangle at release -
    // which is why the vertices are transformed RETROACTIVELY.
    struct FbFrame
    {
        uint32_t vertexStart{ 0 };
        float width{ 0.0f };
        float height{ 0.0f };
    };

    // FNV-1a 64 over the pixels + dimensions. Computed ONCE per uniqueId (afterwards the fast
    // m_slots map hits), so the ~1 us cost per 32x32 sprite is negligible next to decode/upload.
    uint64_t hashImageContent(const uint8_t* data, const size_t bytes, const int width, const int height)
    {
        uint64_t hash = 14695981039346656037ull;
        const auto mix = [&hash](const uint8_t byte) {
            hash ^= byte;
            hash *= 1099511628211ull;
        };

        for (size_t i = 0; i < bytes; ++i)
            mix(data[i]);

        for (const int dim : { width, height })
            for (int shift = 0; shift < 32; shift += 8)
                mix(static_cast<uint8_t>((static_cast<uint32_t>(dim) >> shift) & 0xFFu));

        return hash;
    }
}

VkDrawFeeder& VkDrawFeeder::instance()
{
    static VkDrawFeeder feeder;
    return feeder;
}

const VkAtlasSlot* VkDrawFeeder::whiteSlot(VkSpriteBatch& batch)
{
    if (m_white.valid)
        return &m_white;

    // A single white pixel: drawing solid rectangles and untextured triangles goes through
    // it with the color in the vertex - thanks to that the WHOLE frame stays in one pipeline.
    static constexpr uint8_t whitePixel[4] = { 255, 255, 255, 255 };
    m_white = batch.getAtlas().add(whitePixel, 1, 1);
    return m_white.valid ? &m_white : nullptr;
}

const VkDrawFeeder::BigSlot* VkDrawFeeder::registerBigTexture(VkSpriteBatch& batch, const uint32_t key, Image* image)
{
    const uint32_t width = static_cast<uint32_t>(image->getWidth());
    const uint32_t height = static_cast<uint32_t>(image->getHeight());
    const int bpp = image->getBpp();

    BigSlot big;
    big.texWidth = width;
    big.texHeight = height;
    // 1024: fits any layer with room to spare, and UI icon strips use 16/32/64 px cells,
    // all of which divide 1024 - an icon clip never straddles a chunk boundary.
    big.chunk = 1024;
    big.cols = (width + big.chunk - 1) / big.chunk;
    big.rows = (height + big.chunk - 1) / big.chunk;
    big.slots.reserve(static_cast<size_t>(big.cols) * big.rows);

    std::vector<uint8_t> chunkPixels;
    const uint8_t* source = image->getPixelData();

    for (uint32_t row = 0; row < big.rows; ++row) {
        for (uint32_t col = 0; col < big.cols; ++col) {
            const uint32_t x0 = col * big.chunk;
            const uint32_t y0 = row * big.chunk;
            const uint32_t w = std::min(big.chunk, width - x0);
            const uint32_t h = std::min(big.chunk, height - y0);

            chunkPixels.resize(static_cast<size_t>(w) * h * 4);
            for (uint32_t y = 0; y < h; ++y) {
                const uint8_t* srcRow = source + (static_cast<size_t>(y0 + y) * width + x0) * bpp;
                uint8_t* dstRow = chunkPixels.data() + static_cast<size_t>(y) * w * 4;
                if (bpp == 4) {
                    std::memcpy(dstRow, srcRow, static_cast<size_t>(w) * 4);
                } else {
                    for (uint32_t x = 0; x < w; ++x) {
                        dstRow[x * 4 + 0] = srcRow[x * bpp + 0];
                        dstRow[x * 4 + 1] = srcRow[x * bpp + 1];
                        dstRow[x * 4 + 2] = srcRow[x * bpp + 2];
                        dstRow[x * 4 + 3] = 255;
                    }
                }
            }

            const VkAtlasSlot slot = batch.getAtlas().add(chunkPixels.data(), w, h);
            if (!slot.valid) {
                if (m_loggedMissing.emplace(key).second)
                    g_logger.warning("[vulkan] feeder: chunk {}x{} of big texture {} did not fit the atlas", w, h, key);
                return nullptr;
            }
            big.slots.push_back(slot);
        }
    }

    return &m_bigSlots.emplace(key, std::move(big)).first->second;
}

VkDrawFeeder::ResolvedSlot VkDrawFeeder::resolveSlot(VkSpriteBatch& batch, Texture* texture)
{
    // Animated texture: draw its CURRENT frame. Every frame is a separate Texture with its own
    // uniqueId, so the registry naturally keeps each frame as a separate atlas region.
    // Animation advances via g_textures.poll() on the main thread, regardless of backend.
    if (texture->isAnimatedTexture()) {
        const auto& frame = static_cast<AnimatedTexture*>(texture)->getCurrentFrame();
        if (!frame)
            return {};
        texture = frame.get();
    }

    const uint32_t key = texture->getUniqueId();

    if (const auto bigIt = m_bigSlots.find(key); bigIt != m_bigSlots.end())
        return { nullptr, &bigIt->second };

    const auto it = m_slots.find(key);
    if (it != m_slots.end())
        return it->second.valid ? ResolvedSlot{ &it->second, nullptr } : ResolvedSlot{};

    // Pixels: first the copy held by the texture, then reload from disk.
    ImagePtr image = texture->m_image;
    if (!image && !texture->m_source.empty()) {
        try {
            image = Image::load(texture->m_source);
        } catch (const std::exception& e) {
            g_logger.warning("[vulkan] feeder: cannot reload {}: {}", texture->m_source, e.what());
        }
    }

    if (!image) {
        // NO registry entry: the texture may receive pixels later (e.g. downloaded), so
        // subsequent frames are allowed to retry. Log once.
        if (m_loggedMissing.emplace(key).second) {
            g_logger.warning("[vulkan] feeder: texture {} ({}x{}) has no pixels and no source - skipping",
                             key, texture->getWidth(), texture->getHeight());
        }
        return {};
    }

    // Oversized (wider/taller than an atlas layer, e.g. the 5248x64 imbuement icon strip):
    // store as a grid of chunks - a single region can never hold it.
    const uint32_t maxSide = batch.getAtlas().getSize() - 1;
    if (static_cast<uint32_t>(image->getWidth()) > maxSide ||
        static_cast<uint32_t>(image->getHeight()) > maxSide) {
        const BigSlot* big = registerBigTexture(batch, key, image.get());
        if (big)
            texture->m_image = nullptr;
        return { nullptr, big };
    }

    // Content-hash lookup first - thing-texture recycling by the GC creates new objects with
    // identical pixels, and identical sprites also repeat across different things.
    // A hit means zero new atlas regions.
    const uint64_t contentKey = hashImageContent(image->getPixelData(), image->getPixels().size(),
                                                 image->getWidth(), image->getHeight());

    if (const auto contentIt = m_slotsByContent.find(contentKey); contentIt != m_slotsByContent.end()) {
        const auto& stored = m_slots.emplace(key, contentIt->second).first->second;
        texture->m_image = nullptr;
        return stored.valid ? ResolvedSlot{ &stored, nullptr } : ResolvedSlot{};
    }

    const VkAtlasSlot slot = batch.getAtlas().add(image);
    const auto& stored = m_slots.emplace(key, slot).first->second;

    if (stored.valid) {
        m_slotsByContent.emplace(contentKey, slot);

        // The pixels already sit in the atlas upload queue (add copied them) - the CPU copy in
        // Texture would be double storage, and in Vulkan mode nobody else frees it (GL does so
        // in create() after upload, which never runs here). With 57k thing animation phases
        // that is tens of MB. Trade-off: if the Vulkan context dies mid-session, textures
        // without m_source render black in the GL fallback until the next thing-GC cycle.
        texture->m_image = nullptr;
    } else if (m_loggedMissing.emplace(key).second) {
        g_logger.warning("[vulkan] feeder: texture {} ({}x{}) did not fit the atlas",
                         key, image->getWidth(), image->getHeight());
    }

    return stored.valid ? ResolvedSlot{ &stored, nullptr } : ResolvedSlot{};
}

void VkDrawFeeder::consumeAllPools()
{
    for (int8_t i = -1; ++i < static_cast<int8_t>(DrawPoolType::LAST);)
        consumePool(g_drawPool.get(static_cast<DrawPoolType>(i)));
}

void VkDrawFeeder::consumePool(DrawPool* pool)
{
    if (!pool)
        return;

    // Even a pool we do NOT draw (LIGHT) must be consumed: the map thread, via
    // canDrawMap(), waits until the shouldRepaint flag is consumed - without this, after the
    // first frame with lighting it would stop emitting the map FOREVER.
    SpinLock::Guard guard(pool->m_threadLock);
    if (pool->m_shouldRepaint.load(std::memory_order_relaxed)) {
        pool->m_objectsDraw[0].swap(pool->m_objectsDraw[1]);
        pool->m_shouldRepaint.store(false, std::memory_order_relaxed);
    }
}

void VkDrawFeeder::feedPool(VkSpriteBatch& batch, DrawPool* pool, const VkExtent2D& extent)
{
    if (!pool || !pool->isEnabled())
        return;

    const bool hasFb = pool->hasFrameBuffer();

    Rect fbDest;
    Rect fbSrc;
    Rect mapHole;

    {
        // EXACTLY the same protocol as DrawPoolManager::drawObjects: swap under the lock and clear
        // the flag; the map thread writes only into m_objectsDraw[0] (in release(), also under the
        // lock), so after leaving the lock [1] is exclusively ours.
        SpinLock::Guard guard(pool->m_threadLock);
        if (pool->m_shouldRepaint.load(std::memory_order_relaxed)) {
            pool->m_objectsDraw[0].swap(pool->m_objectsDraw[1]);
            pool->m_shouldRepaint.store(false, std::memory_order_relaxed);
        }
        fbDest = pool->m_fbDest;
        fbSrc = pool->m_fbSrc;
        mapHole = pool->m_mapHole;
    }

    if (pool->m_objectsDraw[1].empty())
        return;

    // Pool mapping: we replace the FBO with the dest/src transform from preDraw. No src = the whole
    // framebuffer (FrameBuffer::draw on the GL side interprets it the same way).
    PoolMapping mapping;
    VkRect2D baseScissor = fullRect(extent);

    if (hasFb && fbDest.isValid()) {
        if (!fbSrc.isValid() && pool->m_framebuffer && pool->m_framebuffer->isValid())
            fbSrc = Rect(0, 0, pool->m_framebuffer->getSize());

        if (fbSrc.isValid() && fbSrc.width() > 0 && fbSrc.height() > 0) {
            mapping.sx = static_cast<float>(fbDest.width()) / static_cast<float>(fbSrc.width());
            mapping.sy = static_cast<float>(fbDest.height()) / static_cast<float>(fbSrc.height());
            mapping.tx = static_cast<float>(fbDest.x()) - static_cast<float>(fbSrc.x()) * mapping.sx;
            mapping.ty = static_cast<float>(fbDest.y()) - static_cast<float>(fbSrc.y()) * mapping.sy;
        }

        // The FBO clipped the drawing to dest naturally - without this the map would spill
        // out of its widget onto the rest of the interface.
        baseScissor = clampRect(static_cast<float>(fbDest.x()), static_cast<float>(fbDest.y()),
                                static_cast<float>(fbDest.x() + fbDest.width()),
                                static_cast<float>(fbDest.y() + fbDest.height()), extent);
    }

    // Start of this pool's geometry - the hole punch cuts only from its own pool,
    // exactly as in GL it cut only from its own FBO.
    const uint32_t poolStartVertex = batch.externalVertexCount();

    // A stack of open temporary framebuffers (bind/release). Objects inside are emitted
    // in LOCAL coordinates and transformed retroactively at release.
    std::vector<FbFrame> fbStack;

    for (const auto& obj : pool->m_objectsDraw[1]) {
        // Bind/release markers of a temporary GL framebuffer (also actions, but with metadata).
        if (obj.fbMarker == 1) {
            fbStack.push_back(FbFrame{ batch.externalVertexCount(),
                                       static_cast<float>(obj.fbSize.width()),
                                       static_cast<float>(obj.fbSize.height()) });
            continue;
        }

        if (obj.fbMarker == 2) {
            if (fbStack.empty())
                continue; // release without bind - the list was truncated, nothing to transform

            const FbFrame frame = fbStack.back();
            fbStack.pop_back();

            Rect dest = obj.fbDest;
            if (!dest.isValid())
                dest = Rect(0, 0, static_cast<int>(frame.width), static_cast<int>(frame.height));

            const float sx = frame.width > 0.0f ? static_cast<float>(dest.width()) / frame.width : 1.0f;
            const float sy = frame.height > 0.0f ? static_cast<float>(dest.height()) / frame.height : 1.0f;
            const float dx = static_cast<float>(dest.x());
            const float dy = static_cast<float>(dest.y());
            const bool toScreen = fbStack.empty(); // nested: we stay in the outer one's local coords
            const float opacity = std::clamp(obj.fbOpacity, 0.0f, 1.0f);

            VkSpriteVertex* data = batch.externalVertexData();
            const uint32_t end = batch.externalVertexCount();

            for (uint32_t i = frame.vertexStart; i < end; ++i) {
                float lx = data[i].pos[0];
                float ly = data[i].pos[1];

                // as in FrameBuffer::prepare: 1 = horizontal flip, 2 = vertical
                if (obj.fbFlip == 1)
                    lx = frame.width - lx;
                else if (obj.fbFlip == 2)
                    ly = frame.height - ly;

                float x = dx + lx * sx;
                float y = dy + ly * sy;

                if (toScreen)
                    mapping.apply(x, y);

                data[i].pos[0] = x;
                data[i].pos[1] = y;

                if (opacity < 1.0f)
                    data[i].color[3] = static_cast<uint8_t>(static_cast<float>(data[i].color[3]) * opacity);
            }
            continue;
        }

        // Actions are lambdas operating on OpenGL state (framebuffer binds, glDisable, ...) -
        // in the Vulkan world they have nothing to touch.
        if (obj.action)
            continue;

        if (!obj.coords)
            continue;

        const auto& st = obj.state;

        if (st.shaderProgram && !m_loggedShader) {
            m_loggedShader = true;
            g_logger.info("[vulkan] feeder: painter shader programs are ignored in stage 4 (drawing without the effect)");
        }

        // Color: as in the GL shaders - the color multiplies the texel, and opacity multiplies ONLY alpha.
        const float opacity = std::clamp(st.opacity, 0.0f, 1.0f);
        uint8_t rgba[4];
        rgba[0] = static_cast<uint8_t>(st.color.r());
        rgba[1] = static_cast<uint8_t>(st.color.g());
        rgba[2] = static_cast<uint8_t>(st.color.b());
        rgba[3] = static_cast<uint8_t>(static_cast<float>(st.color.a()) * opacity);

        const bool hasTransform = st.transformMatrix != DEFAULT_MATRIX3;
        const float* matrix = st.transformMatrix.data();

        const float* positions = obj.coords->getVertexArray();
        const float* texcoords = obj.coords->getTextureCoordArray();

        int count = obj.coords->getVertexCount();
        const bool useTexcoords = st.texture != nullptr && obj.coords->getTextureCoordCount() > 0;
        if (useTexcoords)
            count = std::min(count, obj.coords->getTextureCoordCount());
        count -= count % 3;

        if (count <= 0)
            continue;

        // The map hole punch: GL cut a transparent window in the foreground FBO by
        // writing alpha=0 with blending DISABLED (UIMap::drawSelf). For us the map already lies
        // UNDER the interface on the same image, so the equivalent is CUTTING OUT the previously
        // emitted geometry of this pool within that rectangle. A shape only counts as the map
        // window when it MATCHES the rect UIMap registered on the pool (m_mapHole) - guessing
        // by "untextured + alpha=0" alone used to cut holes through regular UI (any widget with
        // an alpha-0 fill), letting the world show through e.g. the prey window.
        if (hasFb && fbStack.empty() && !st.texture && st.textureId == 0 && rgba[3] == 0) {
            // Bounding box in pool-local coordinates - the same space m_mapHole lives in.
            float lx0 = 0.0f, ly0 = 0.0f, lx1 = 0.0f, ly1 = 0.0f;
            for (int i = 0; i < count; ++i) {
                float x = positions[i * 2];
                float y = positions[i * 2 + 1];
                if (hasTransform)
                    applyTransform(matrix, x, y);
                if (i == 0) {
                    lx0 = lx1 = x;
                    ly0 = ly1 = y;
                } else {
                    lx0 = std::min(lx0, x);
                    ly0 = std::min(ly0, y);
                    lx1 = std::max(lx1, x);
                    ly1 = std::max(ly1, y);
                }
            }

            // 2 px slack: Rect right/bottom are inclusive, and the widget rect may differ from
            // the emitted quad by a border pixel.
            constexpr float kHoleTolerance = 2.0f;
            const bool isMapHole = mapHole.isValid() &&
                std::abs(lx0 - static_cast<float>(mapHole.x())) <= kHoleTolerance &&
                std::abs(ly0 - static_cast<float>(mapHole.y())) <= kHoleTolerance &&
                std::abs(lx1 - static_cast<float>(mapHole.x() + mapHole.width())) <= kHoleTolerance &&
                std::abs(ly1 - static_cast<float>(mapHole.y() + mapHole.height())) <= kHoleTolerance;

            if (!isMapHole) {
                // Untextured with alpha=0 = invisible either way; skip it WITHOUT cutting.
                // One-shot log so a lingering visual bug report can pinpoint the emitter.
                if (!m_loggedSuspectPunch) {
                    m_loggedSuspectPunch = true;
                    g_logger.info("[vulkan] feeder: ignored a non-map alpha-0 shape {}x{} at ({},{}) - registered map hole is {}x{} at ({},{})",
                                  static_cast<int>(lx1 - lx0), static_cast<int>(ly1 - ly0),
                                  static_cast<int>(lx0), static_cast<int>(ly0),
                                  mapHole.width(), mapHole.height(), mapHole.x(), mapHole.y());
                }
                continue;
            }

            float bx0 = lx0, by0 = ly0, bx1 = lx1, by1 = ly1;
            mapping.apply(bx0, by0);
            mapping.apply(bx1, by1);
            batch.punchRect(poolStartVertex, bx0, by0, bx1, by1);
            continue;
        }

        // Atlas region: client texture with texcoords; without texcoords - the white pixel
        // multiplied by vertex color (GL also switches to the SOLID program in that case).
        const VkAtlasSlot* slot = nullptr;
        const BigSlot* big = nullptr;

        if (useTexcoords) {
            const ResolvedSlot resolved = resolveSlot(batch, st.texture.get());
            slot = resolved.slot;
            big = resolved.big;
            if (!slot && !big)
                continue;
        } else if (!st.texture && st.textureId != 0) {
            // The identifier exists only on the GL side (the texture was already uploaded to GL).
            // In pure Vulkan mode this does not happen; a one-time log in case of a regression.
            if (!m_loggedGlOnly) {
                m_loggedGlOnly = true;
                g_logger.warning("[vulkan] feeder: object with only a GL textureId ({}) - skipping", st.textureId);
            }
            continue;
        } else {
            slot = whiteSlot(batch);
            if (!slot)
                continue;
        }

        // Pipeline: NORMAL or MULTIPLY (tinting outfit layers). Other blend modes
        // are drawn as NORMAL for now - one-time log.
        if (st.compositionMode == CompositionMode::MULTIPLY) {
            batch.setPipeline(1);
        } else {
            if (st.compositionMode != CompositionMode::NORMAL && !m_loggedComposition) {
                m_loggedComposition = true;
                g_logger.info("[vulkan] feeder: blend mode {} drawn as NORMAL (stage 4)",
                              static_cast<int>(st.compositionMode));
            }
            batch.setPipeline(0);
        }

        // Scissor: the base one (pool dest) intersected with the state's clipRect, converted with
        // the same mapping. Inside a temporary framebuffer the clipRect is in FBO-local
        // coordinates we do not yet know on screen - we skip it (rare and at worst too wide).
        if (fbStack.empty()) {
            VkRect2D scissor = baseScissor;
            if (st.clipRect.isValid()) {
                float cx0 = static_cast<float>(st.clipRect.x());
                float cy0 = static_cast<float>(st.clipRect.y());
                float cx1 = static_cast<float>(st.clipRect.x() + st.clipRect.width());
                float cy1 = static_cast<float>(st.clipRect.y() + st.clipRect.height());
                mapping.apply(cx0, cy0);
                mapping.apply(cx1, cy1);
                scissor = intersectRects(clampRect(cx0, cy0, cx1, cy1, extent), baseScissor);
            }

            if (scissor.extent.width == 0 || scissor.extent.height == 0)
                continue;

            batch.setScissor(scissor);
        }

        VkSpriteVertex* out = batch.allocVertices(static_cast<uint32_t>(count));
        if (!out) {
            if (!m_loggedOverflow) {
                m_loggedOverflow = true;
                g_logger.warning("[vulkan] feeder: batch vertex limit exceeded - part of the frame truncated");
            }
            continue;
        }

        // Per-object slot values; for oversized textures they are re-picked per TRIANGLE
        // (each triangle selects the chunk containing its source-space bbox center).
        float invW = 0.0f, invH = 0.0f, spanU = 0.0f, spanV = 0.0f;
        float centerU = 0.0f, centerV = 0.0f, layer = 0.0f;
        float chunkOffX = 0.0f, chunkOffY = 0.0f;
        const VkAtlasSlot* activeSlot = slot;

        const auto applySlotValues = [&](const VkAtlasSlot* s, const float offX, const float offY) {
            invW = s->width > 0 ? 1.0f / static_cast<float>(s->width) : 0.0f;
            invH = s->height > 0 ? 1.0f / static_cast<float>(s->height) : 0.0f;
            spanU = s->uvMax[0] - s->uvMin[0];
            spanV = s->uvMax[1] - s->uvMin[1];
            centerU = (s->uvMin[0] + s->uvMax[0]) * 0.5f;
            centerV = (s->uvMin[1] + s->uvMax[1]) * 0.5f;
            layer = static_cast<float>(s->layer);
            chunkOffX = offX;
            chunkOffY = offY;
        };

        if (slot)
            applySlotValues(slot, 0.0f, 0.0f);

        const bool insideFb = !fbStack.empty();

        for (int i = 0; i < count; ++i) {
            // Oversized texture: at every triangle start pick the chunk under its bbox center.
            if (big && (i % 3) == 0) {
                const float cu = (texcoords[i * 2] + texcoords[(i + 1) * 2] + texcoords[(i + 2) * 2]) / 3.0f;
                const float cv = (texcoords[i * 2 + 1] + texcoords[(i + 1) * 2 + 1] + texcoords[(i + 2) * 2 + 1]) / 3.0f;
                const uint32_t col = std::min(big->cols - 1,
                    static_cast<uint32_t>(std::max(0.0f, cu)) / big->chunk);
                const uint32_t row = std::min(big->rows - 1,
                    static_cast<uint32_t>(std::max(0.0f, cv)) / big->chunk);
                activeSlot = &big->slots[static_cast<size_t>(row) * big->cols + col];
                applySlotValues(activeSlot, static_cast<float>(col * big->chunk),
                                static_cast<float>(row * big->chunk));
            }

            float x = positions[i * 2];
            float y = positions[i * 2 + 1];

            if (hasTransform)
                applyTransform(matrix, x, y);

            // Inside a temporary framebuffer we stay in local coordinates - the release step
            // maps them onto the screen retroactively (it knows the dest rect).
            if (!insideFb)
                mapping.apply(x, y);

            VkSpriteVertex& v = out[i];
            v.pos[0] = x;
            v.pos[1] = y;

            if (useTexcoords) {
                // Texture coordinates arrive in SOURCE PIXELS (GL normalized them with the
                // texture matrix) - we normalize into the atlas region. Clamp, because the
                // atlas cannot repeat a tile (its neighbor is a foreign image, not a wrap).
                const float un = std::clamp((texcoords[i * 2] - chunkOffX) * invW, 0.0f, 1.0f);
                const float vn = std::clamp((texcoords[i * 2 + 1] - chunkOffY) * invH, 0.0f, 1.0f);
                v.uv[0] = activeSlot->uvMin[0] + un * spanU;
                v.uv[1] = activeSlot->uvMin[1] + vn * spanV;
            } else {
                // Region center: for the white pixel there is one texel anyway, and for solid
                // shapes only the vertex color matters.
                v.uv[0] = centerU;
                v.uv[1] = centerV;
            }

            v.layer = layer;
            v.color[0] = rgba[0];
            v.color[1] = rgba[1];
            v.color[2] = rgba[2];
            v.color[3] = rgba[3];
        }
    }

    if (!fbStack.empty() && !m_loggedUnbalancedFb) {
        m_loggedUnbalancedFb = true;
        g_logger.warning("[vulkan] feeder: framebuffer bind without release in pool {} - geometry left in local coordinates",
                         static_cast<int>(pool->getType()));
    }
}

void VkDrawFeeder::feedFrame(VkSpriteBatch& batch, const VkExtent2D& extent)
{
    if (!batch.isReady() || extent.width == 0 || extent.height == 0)
        return;

    ++m_frame;

    // Cap unbounded atlas growth. The atlas never shrinks on its own - every new sprite that
    // comes into view adds a region, and over a long/dense session it climbs to 20+ layers
    // (16 MB each = 300+ MB of device memory, which counts toward the process's private bytes).
    //
    // DISABLED: a mid-session reset() reliably left the map GROUND rendering black while
    // creatures/UI kept drawing - re-registering the whole working set inside one frame does not
    // repopulate ground-tile slots correctly. A full nuke-and-rebuild is the wrong tool; RAM has
    // to be reclaimed with per-slot/per-layer LRU eviction instead (kept for a later pass). The
    // reset() method stays in VkTextureAtlas but is no longer triggered from the hot path.
    static constexpr bool kAtlasResetEnabled = false;
    static constexpr uint32_t kMaxAtlasLayers = 8; // 8 * 16 MB = 128 MB ceiling
    if (kAtlasResetEnabled && batch.getAtlas().getLayerCount() > kMaxAtlasLayers) {
        if (batch.getAtlas().reset()) {
            m_slots.clear();
            m_slotsByContent.clear();
            m_bigSlots.clear();
            m_white = VkAtlasSlot{};
            g_logger.info("[vulkan] feeder: atlas exceeded {} layers - rebuilt (frame {})",
                          kMaxAtlasLayers, m_frame);
        }
    }

    batch.beginExternal(extent);

    // The same order as the GL loop in DrawPoolManager::draw: the map at the bottom, the interface
    // on top. LIGHT is deliberately skipped in DRAWING, but its flag must be consumed -
    // see consumePool.
    static constexpr DrawPoolType kOrder[] = {
        DrawPoolType::MAP,
        DrawPoolType::CREATURE_INFORMATION,
        DrawPoolType::FOREGROUND_MAP,
        DrawPoolType::FOREGROUND,
    };

    if (!m_loggedLight) {
        m_loggedLight = true;
        g_logger.info("[vulkan] feeder: the LIGHT pool (lighting) is skipped in stage 4");
    }

    consumePool(g_drawPool.get(DrawPoolType::LIGHT));

    for (const DrawPoolType type : kOrder)
        feedPool(batch, g_drawPool.get(type), extent);

    // Upload everything that arrived into the atlas this frame BEFORE the frame is recorded.
    // After this line no descriptor can change generation in the middle of recording.
    // A failed upload = we abandon the external frame (record() falls back to the test scene,
    // which is the built-in, visible-to-the-naked-eye signal of feeder failure).
    if (!batch.getAtlas().flush()) {
        if (!m_loggedFlushFail) {
            m_loggedFlushFail = true;
            g_logger.warning("[vulkan] feeder: the atlas failed to upload pixels ({}) - frame abandoned",
                             batch.getAtlas().getError());
        }
        batch.abortExternal();
    }
}

#endif // WIN32
