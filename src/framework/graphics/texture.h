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
#include <framework/core/timer.h>

#include <atomic>

// The unique-id counter is seeded here, above every id GL generates, so that a Texture's
// unique id can double as its logical render handle. The renderer boundary reserves everything
// BELOW this value for render-target textures and static_asserts against it, so lowering it
// would make a sprite's handle compare equal to a render target's.
inline constexpr uint32_t TEXTURE_UNIQUE_ID_SEED = UINT16_MAX;

class Texture
{
public:
    Texture();
    Texture(const Size& size);
    Texture(const ImagePtr& image, bool buildMipmaps = false, bool compress = false);
    virtual ~Texture();

    virtual void create();
    void uploadPixels(const ImagePtr& image, bool buildMipmaps = false, bool compress = false);
    void updateImage(const ImagePtr& image);
    void updatePixels(uint8_t* pixels, int level = 0, int channels = 4, bool compress = false);

    virtual void buildHardwareMipmaps();

    // Enable trilinear/mipmap minification for this texture. Unlike buildHardwareMipmaps()
    // it does not need the GL texture to exist yet: it just flags buildMipmaps + hasMipMaps
    // so that the deferred create()/uploadPixels() (on the render thread) uploads the CPU
    // mip chain and setupFilters() selects a *_MIPMAP_* filter. Safe to call right after
    // construction, before the texture is created.
    void enableMipmaps();

    virtual void setSmooth(bool smooth);
    virtual void setRepeat(bool repeat);
    void setUpsideDown(bool upsideDown);
    void setTime(const ticks_t time) { m_time = time; }

    const Size& getSize() const { return m_size; }
    auto getTransformMatrixId() const { return m_transformMatrixId; }

    // --- pixels for a backend that is not OpenGL ------------------------------------------
    // Read-only view of the CPU pixel copy. create() deliberately keeps it when there is no GL
    // context precisely so that a backend which owns its own GPU textures can upload from it,
    // and this is how that backend reaches it without joining the friend list.
    const ImagePtr& getPendingImage() const { return m_image; }

    // The non-GL twin of create()'s `m_image = nullptr` after uploadPixels. A backend that has
    // copied these pixels onto the GPU says so, and the CPU copy goes with it.
    //
    // Both halves matter. Without the flag, `m_id` stays 0 forever under such a backend, so
    // create() would reload the file from disk on every single frame the texture is drawn -
    // its "the garbage collector freed my pixels" recovery path, firing perpetually. Without
    // freeing the image, the process would carry every sprite twice.
    void markUploaded() { setProp(Prop::uploaded, true); m_image = nullptr; }
    bool isUploaded() const { return getProp(Prop::uploaded); }

    // --- content identity -----------------------------------------------------------------
    // Bumped whenever the pixels a sampler would read change WITHOUT the logical handle
    // changing: an animation advancing to its next frame, or an in-place pixel update.
    //
    // The frame compiler folds this into a pool's content hash. It has to: a retained target is
    // re-composited rather than re-rendered when the compiled output is byte-identical, and an
    // animation advancing produces byte-identical output by design - the handle is stable on
    // purpose. Phase 3 caught that case for OpenGL by folding in the native texture id, which
    // an AnimatedTexture re-aims every tick; that signal does not exist for a backend where the
    // native id is always 0, and it never covered updatePixels at all. This does both.
    //
    // Relaxed atomic because it is written on the main thread (TextureManager::poll) and read on
    // a producer thread (PoolCompiler). Only the change matters, never the ordering.
    uint32_t getContentRevision() const { return m_contentRevision.load(std::memory_order_relaxed); }
    void bumpContentRevision() { m_contentRevision.fetch_add(1, std::memory_order_relaxed); }

    auto getAtlasRegion(Fw::TextureAtlasType type) const { return m_atlas[type]; }
    const AtlasRegion* getAtlasRegion() const;

    ticks_t getTime() const { return m_time; }
    uint32_t getId() const { return m_id; }
    uint32_t getUniqueId() const { return m_uniqueId; }
    size_t hash() const { return m_hash; }

    int getWidth() const { return m_size.width(); }
    int getHeight() const { return m_size.height(); }

    virtual bool isAnimatedTexture() const { return false; }
    bool isEmpty() const { return m_id == 0; }
    bool hasRepeat() const { return getProp(repeat); }
    bool hasMipmaps() const { return getProp(hasMipMaps); }
    bool isSmooth() const { return getProp(smooth); }
    bool canCacheInAtlas() const { return getProp(Prop::_allowAtlasCache); }
    bool setupSize(const Size& size);

    virtual void allowAtlasCache();

    // Batched GL texture deletion. Call EXCLUSIVELY from the main thread (that is where the
    // OpenGL context is active). For details see the comment at the definition in texture.cpp.
    static void flushDeletedTextures();

    // Batched deletion diagnostics: total number of deleted GL textures and number of batches.
    // The ratio shows how many glDeleteTextures calls (and dispatcher events) we save.
    static size_t getDeletedCount();
    static size_t getDeletionBatchCount();

protected:
    void bind();
    void setupWrap() const;
    void setupFilters() const;
    void createTexture();
    void setupTranformMatrix();
    void setupPixels(int level, const Size& size, const uint8_t* pixels, int channels = 4, bool compress = false) const;
    void generateHash() { m_hash = stdext::hash_int(m_id > 0 ? m_id : m_uniqueId); }

    const uint32_t m_uniqueId;

    std::array<AtlasRegion*, Fw::TextureAtlasType::LAST> m_atlas{ };

    uint32_t m_id{ 0 };
    ticks_t m_time{ 0 };
    size_t m_hash{ 0 };

    Size m_size;
    Timer m_lastTimeUsage;

    // how many channels the texture's already-allocated memory has (-1 = nothing uploaded yet).
    // Lets us swap the contents via glTexSubImage2D instead of reallocating the whole texture.
    mutable int m_storageChannels{ -1 };

    uint16_t m_transformMatrixId{ 0 };

    std::atomic_uint32_t m_contentRevision{ 0 };

    ImagePtr m_image;

    // Path of the file this texture was created from (set by TextureManager when loading from disk).
    // Thanks to it, GC can free the pixel copy of a texture that was never drawn,
    // and create() can restore it from disk at exactly the moment of the first draw.
    // Empty = the texture came from memory (base64, HTTP, QR, framebuffer) and MUST NOT be cleared.
    std::string m_source;

public:
    // whether the texture still holds a CPU-side pixel copy (not yet uploaded to the GPU)
    bool hasPendingImage() const { return m_image != nullptr; }

    // whether we can restore this texture from disk after freeing the pixel copy
    bool isReloadableFromFile() const { return !m_source.empty(); }

protected:

    enum Prop : uint16_t
    {
        hasMipMaps = 1 << 0,
        smooth = 1 << 1,
        upsideDown = 1 << 2,
        repeat = 1 << 3,
        compress = 1 << 4,
        buildMipmaps = 1 << 5,
        _allowAtlasCache = 1 << 6,
        uploaded = 1 << 7 // a non-GL backend owns a GPU copy of these pixels; see markUploaded
    };

    uint16_t m_props{ 0 };
    void setProp(const Prop prop, const bool v) { if (v) m_props |= prop; else m_props &= ~prop; }
    bool getProp(const Prop prop) const { return m_props & prop; };

    friend class GarbageCollection;
    friend class TextureManager;
    friend class TextureAtlas;
    // Vulkan renderer stage 4: the feeder reads m_image/m_source to put the pixels into the atlas.
    friend class VkDrawFeeder;
};
