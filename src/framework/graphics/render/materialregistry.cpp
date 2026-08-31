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

#include "materialregistry.h"

MaterialRegistry& MaterialRegistry::instance()
{
    static MaterialRegistry registry;
    return registry;
}

void MaterialRegistry::registerMaterial(const MaterialHandle handle, MaterialDesc desc)
{
    if (handle.isDefault())
        return;

    const std::unique_lock lock(m_mutex);
    m_materials.insert_or_assign(handle.id, std::move(desc));
}

const MaterialDesc* MaterialRegistry::resolve(const MaterialHandle handle) const
{
    const std::shared_lock lock(m_mutex);
    const auto it = m_materials.find(handle.id);
    return it == m_materials.end() ? nullptr : &it->second;
}

void MaterialRegistry::clear()
{
    const std::unique_lock lock(m_mutex);
    m_materials.clear();
}

size_t MaterialRegistry::size() const
{
    const std::shared_lock lock(m_mutex);
    return m_materials.size();
}
