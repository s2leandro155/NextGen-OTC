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

#include "garbagecollection.h"

#include "client/const.h"
#include "client/spriteappearances.h"
#include "client/thingtype.h"
#include "client/thingtypemanager.h"
#include "framework/graphics/declarations.h"
#include "framework/graphics/image.h"
#include "framework/graphics/texture.h"
#include "framework/graphics/texturemanager.h"
#include "framework/graphics/animatedtexture.h"
#include "framework/graphics/drawpoolmanager.h"
#include "framework/luaengine/luainterface.h"
#include "framework/core/eventdispatcher.h"

#include <shared_mutex>

#ifdef WIN32
#include <malloc.h>
#include <windows.h>
#include <psapi.h>
#pragma comment(lib, "psapi.lib")
#endif

// How OFTEN we check each pool. Previously textures were checked once every 30 minutes,
// and Lua once every 15, so memory could grow for the whole session with nothing giving it back.
constexpr uint32_t LUA_TIME = 60 * 1000; // 1min - a full collect costs a few ms, so it can run often
constexpr uint32_t TEXTURE_TIME = 5 * 60 * 1000; // 5min
constexpr uint32_t THINGTYPE_TIME = 2 * 1000; // 2sec
constexpr uint32_t SPRITESHEET_TIME = 30 * 1000; // 30sec - sprite sheets are the biggest, we look more often
constexpr uint32_t PENDING_IMAGE_TIME = 30 * 1000; // 30sec - pixel copies of textures nobody has drawn

Timer lua_timer, texture_timer, drawpool_timer, thingtype_timer, spritesheet_timer, pendingimage_timer;

void GarbageCollection::poll() {
    if (canCheck(thingtype_timer, THINGTYPE_TIME))
        thingType();

    if (canCheck(texture_timer, TEXTURE_TIME))
        texture();

    if (canCheck(pendingimage_timer, PENDING_IMAGE_TIME))
        pendingImages();

    if (canCheck(lua_timer, LUA_TIME))
        lua();

    if (canCheck(spritesheet_timer, SPRITESHEET_TIME))
        spriteSheets();
}

void GarbageCollection::spriteSheets() {
    // sprite sheets (~576 KB each) were loaded and never freed - the biggest RAM
    // eater after a longer session. 3 minutes since last use is a compromise: memory comes back
    // during gameplay, while sheets from the area the player is moving around in stay in memory.
    static constexpr uint32_t IDLE_TIME = 3 * 60 * 1000;

    const size_t loadedBefore = g_spriteAppearances.getLoadedSheetCount();
    const size_t freed = g_spriteAppearances.collectGarbage(IDLE_TIME);

    // std::free returns memory to the process heap, not to the system - without this the RAM counter
    // would barely move after freeing the sheets. _heapmin returns free blocks to the system.
    if (freed > 0) {
#ifdef WIN32
        _heapmin();
#endif
    }

    if (loadedBefore > 0) {
        g_logger.info("[gc] sprite sheets: {} loaded, freed {}, {} remain (~{} MB)",
                      loadedBefore, freed, loadedBefore - freed,
                      ((loadedBefore - freed) * 576) / 1024);
    }

    reportMemory();
}

size_t GarbageCollection::privateBytesMb() {
#ifdef WIN32
    PROCESS_MEMORY_COUNTERS_EX pmc{};
    if (GetProcessMemoryInfo(GetCurrentProcess(), reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&pmc), sizeof(pmc)))
        return pmc.PrivateUsage / (1024 * 1024);
#endif
    return 0;
}

void GarbageCollection::trimHeap() {
#ifdef WIN32
    _heapmin();
#endif
}

void GarbageCollection::logBootStage(const std::string& stage) {
    // Memory usage on the login screen (800 MB) is much larger than the sum of what we can
    // name (textures + Lua + sheets = ~170 MB). We measure the growth in stages to point at the culprit.
    // Next to private also the sum of live Images - the difference of the two is NON-pixel memory
    // (structures, heaps, driver), which is the actual hunting target.
    g_logger.info("[boot] {}: private = {} MB | Images in RAM: {} pcs (~{} MB)",
                  stage, privateBytesMb(), Image::getLiveCount(), Image::getLiveBytes() / (1024 * 1024));
}

void GarbageCollection::reportMemory() {
    // Measurement instead of estimation: breaks usage down into categories so it's visible which one grows.
    // Sprite sheets measured separately turned out small (~40 MB), so the gigabyte sits elsewhere.
    size_t texturesWithImage = 0;   // textures that still hold a CPU-side copy of the pixels
    size_t imageBytes = 0;
    size_t textureBytes = 0;

    for (const auto& [key, tex] : g_textures.m_textures) {
        if (!tex)
            continue;

        const auto& size = tex->getSize();
        const size_t bytes = static_cast<size_t>(size.width()) * size.height() * 4;

        // Only RESIDENT bytes (GL storage or a CPU pixel copy) - in Vulkan mode the texture
        // object holds neither of them (pixels live in the VK atlas) and the nominal w*h*4
        // produced a phantom ~116 MB that skewed the whole accounting.
        if (tex->m_id != 0)
            textureBytes += bytes;

        if (tex->hasPendingImage()) {
            ++texturesWithImage;
            textureBytes += bytes;
            imageBytes += bytes;
        }
    }

    // Who exactly keeps pixels in RAM despite never having been drawn.
    // This is the fastest route to pointing at the module that loads graphics ahead of time.
    {
        std::vector<std::pair<size_t, std::string>> offenders;
        for (const auto& [key, tex] : g_textures.m_textures) {
            if (!tex || !tex->hasPendingImage())
                continue;

            const auto& size = tex->getSize();
            offenders.emplace_back(static_cast<size_t>(size.width()) * size.height() * 4, key);
        }

        std::ranges::sort(offenders, [](const auto& a, const auto& b) { return a.first > b.first; });

        std::string top;
        for (size_t i = 0; i < offenders.size() && i < 8; ++i) {
            if (!top.empty())
                top += ", ";
            top += fmt::format("{} ({} KB)", offenders[i].second, offenders[i].first / 1024);
        }

        if (!top.empty())
            g_logger.info("[mem] largest unused textures: {}", top);
    }

    // THING textures (ThingType) - the ones the texture manager doesn't see because they are
    // created directly. These are exactly the ones missing from previous measurements.
    size_t thingBytes = 0;
    size_t thingPendingBytes = 0;
    size_t thingTextures = 0;
    size_t thingsWithTexture = 0;

    for (uint8_t category = 0; category < ThingLastCategory; ++category) {
        for (const auto& thing : g_things.m_thingTypes[category]) {
            if (!thing || !thing->hasTexture())
                continue;

            ++thingsWithTexture;
            thing->accumulateTextureMemory(thingBytes, thingPendingBytes, thingTextures);
        }
    }

    g_logger.info("[mem] THING textures: {} objects with a texture, {} textures, ~{} MB (of which {} MB of pixels in RAM)",
                  thingsWithTexture, thingTextures,
                  thingBytes / (1024 * 1024), thingPendingBytes / (1024 * 1024));

    // Batched GL texture deletion - how many were destroyed and in how many batches. The average
    // batch size is exactly how many glDeleteTextures calls (and dispatcher events) we save.
    const size_t deleted = Texture::getDeletedCount();
    const size_t batches = Texture::getDeletionBatchCount();
    g_logger.info("[mem] deleted GL textures: {} in {} batches (average {} per batch)",
                  deleted, batches, batches > 0 ? deleted / batches : 0);

    const size_t luaKb = g_lua.getMemoryUsageKb();

    // All live Images in the process (textures, sheets, minimap, animations) + who loaded
    // from disk since the previous tick. The Image-vs-texture-counters difference = hidden holders.
    g_logger.info("[mem] Images in RAM: {} pcs (~{} MB) | loads since last tick: {}",
                  Image::getLiveCount(), Image::getLiveBytes() / (1024 * 1024), Image::drainLoadStats());

    g_logger.info("[mem] private={} MB | textures: {} pcs (~{} MB), of which {} hold pixels in RAM (~{} MB) | Lua: {} MB | ThingType: {} | atlas: {}",
                  privateBytesMb(),
                  g_textures.m_textures.size(), textureBytes / (1024 * 1024),
                  texturesWithImage, imageBytes / (1024 * 1024),
                  luaKb / 1024,
                  g_things.getThingTypeCount(),
                  g_drawPool.getAtlasStats());
}

void GarbageCollection::lua() {
    g_lua.collectGarbage();
}

void GarbageCollection::texture() {
    // was 25 min and checked once every 30 min, so in practice textures never came back for a whole session
    static constexpr uint32_t IDLE_TIME = 8 * 60 * 1000; // 8min

    std::erase_if(g_textures.m_textures, [](const auto& item) {
        const auto& [key, tex] = item;
        return tex.use_count() == 1 && tex->m_lastTimeUsage.ticksElapsed() > IDLE_TIME;
    });

    std::erase_if(g_textures.m_animatedTextures, [](const TexturePtr& tex) {
        return tex.use_count() == 1 && tex->m_lastTimeUsage.ticksElapsed() > IDLE_TIME;
    });
}

void GarbageCollection::pendingImages() {
    // A texture loaded from disk keeps a full CPU-side copy of its pixels (Texture::m_image) until
    // the FIRST draw - only Texture::create() uploads it to GL and clears the copy. The wheel of
    // destiny module builds a hidden window at startup with dozens of ~1 MB images,
    // so those copies were never freed: measured ~92 MB on the login screen alone.
    //
    // WHY we free the PIXEL COPIES and not the whole texture from the manager:
    // these images are held by a live widget (UIWidget::m_imageTexture), so use_count() > 1 and the
    // "remove from the manager, it will be re-fetched on getTexture()" variant would not free a single
    // byte - exactly the textures that hurt the most would survive such a cleanup.
    // (The variant that removes unused entries already exists anyway - see texture() above.)
    //
    // WHY this cannot result in blank graphics:
    //  1. we clear ONLY textures with m_id == 0, i.e. ones that never made it to GL,
    //     and therefore physically cannot be drawn by anything at this moment;
    //  2. we clear ONLY textures with a known source path (Texture::m_source is set by
    //     TextureManager when loading from disk) - Texture::create() will read the file back
    //     exactly at the moment of the first draw;
    //  3. animated ones (APNG) are left alone - their frames live in separate objects and cannot
    //     be recreated with a single Image::load().
    static constexpr uint32_t IDLE_TIME = 30 * 1000;

    std::vector<TexturePtr> candidates;

    {
        std::shared_lock l(g_textures.m_mutex);
        for (const auto& [key, tex] : g_textures.m_textures) {
            if (!tex || tex->isAnimatedTexture())
                continue;

            if (!tex->hasPendingImage() || tex->m_id != 0 || !tex->isReloadableFromFile())
                continue;

            if (tex->m_lastTimeUsage.ticksElapsed() < IDLE_TIME)
                continue;

            candidates.emplace_back(tex);
        }
    }

    if (candidates.empty())
        return;

    // The actual clearing of m_image is done on the main thread, because that's where Texture::create()
    // runs. The GC runs on the map thread - if we cleared the image here, we would race exactly
    // at the moment the renderer reads m_image to upload it to GL.
    // addEvent called from the main thread executes immediately, so client startup works too.
    g_mainDispatcher.addEvent([textures = std::move(candidates)] {
        size_t freed = 0;
        size_t bytes = 0;

        for (const auto& tex : textures) {
            // Re-check now on the proper thread: the texture may have been drawn in the
            // meantime (m_id != 0) or the image may have vanished on its own - then we do nothing.
            if (tex->m_id != 0 || !tex->hasPendingImage())
                continue;

            const auto& size = tex->getSize();
            bytes += static_cast<size_t>(size.width()) * size.height() * 4;
            tex->m_image = nullptr;
            ++freed;
        }

        if (freed == 0)
            return;

#ifdef WIN32
        // std::free returns memory to the process heap, not to the system - without this the private
        // bytes counter would barely move (same reason as with the sprite sheets).
        _heapmin();
#endif

        g_logger.info("[gc] freed pixel copies of {} unused textures (~{} MB)",
                      freed, bytes / (1024 * 1024));
    });
}

void GarbageCollection::thingType() {
    // 60 s was too short: while walking, the same ThingTypes dropped out and came right back, giving
    // an unload/load cycle and micro-stutters. 5 minutes keeps them in memory for the span of real gameplay.
    // Note: 300000 does not fit in uint16_t, hence a separate type for the threshold.
    static constexpr uint32_t IDLE_TIME = 5 * 60 * 1000;
    static constexpr uint16_t AMOUNT_PER_CHECK = 500; // maximum number of objects to be checked.

    static uint8_t category{ ThingLastCategory };
    static size_t index = 0;

    if (category == ThingLastCategory)
        category = ThingCategoryItem;

    const auto& thingTypes = g_things.m_thingTypes[category];
    const size_t limit = std::min<size_t>(index + AMOUNT_PER_CHECK, thingTypes.size());

    while (index < limit) {
        auto& thing = thingTypes[index];
        if (thing->hasTexture() && thing->getLastTimeUsage().ticksElapsed() > IDLE_TIME) {
            thing->unload();
        }
        ++index;
    }

    if (limit == thingTypes.size()) {
        index = 0;
        ++category;
    }
}