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

#include "resourceregistry.h"

#include "renderhandles.h"

#include <framework/graphics/texture.h>

ResourceRegistry& ResourceRegistry::instance()
{
    // Function-local static rather than a global object: textures are constructed during
    // static initialisation in some translation units, and a plain global would not reliably
    // be alive by then.
    static ResourceRegistry registry;
    return registry;
}

void ResourceRegistry::registerTexture(Texture* texture)
{
    if (!texture)
        return;

    const std::unique_lock lock(m_textureMutex);
    m_textures[texture->getUniqueId()] = texture;
}

void ResourceRegistry::unregisterTexture(const uint32_t uniqueId)
{
    const std::unique_lock lock(m_textureMutex);
    m_textures.erase(uniqueId);
}

Texture* ResourceRegistry::resolveTexture(const TextureHandle handle) const
{
    if (!handle.isValid())
        return nullptr;

    // Render-target textures are not Textures owned by the texture plane - they belong to a
    // FrameBuffer and are resolved through the target plane. Answering "no" here rather than
    // taking the lock keeps the two spaces from being confused for one another.
    if (RenderHandles::isRenderTargetTexture(handle))
        return nullptr;

    const std::shared_lock lock(m_textureMutex);
    const auto it = m_textures.find(handle.id);
    return it == m_textures.end() ? nullptr : it->second;
}

void ResourceRegistry::bindTarget(const RenderTargetHandle handle, FrameBuffer* target)
{
    if (handle.isBackbuffer())
        return; // the backbuffer is not an object; it is the absence of one

    if (target)
        m_targets[handle.id] = target;
    else
        m_targets.erase(handle.id);
}

void ResourceRegistry::clearTargets()
{
    m_targets.clear();
}

FrameBuffer* ResourceRegistry::resolveTarget(const RenderTargetHandle handle) const
{
    if (handle.isBackbuffer())
        return nullptr;

    const auto it = m_targets.find(handle.id);
    return it == m_targets.end() ? nullptr : it->second;
}

size_t ResourceRegistry::textureCount() const
{
    const std::shared_lock lock(m_textureMutex);
    return m_textures.size();
}
