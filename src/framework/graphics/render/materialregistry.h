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

#include "renderdeclarations.h"

#include <shared_mutex>
#include <string>
#include <unordered_map>

/*
 * MaterialRegistry - what a MaterialHandle above the module range actually names.
 *
 * A packet carries a material as a number. `GLBackend` can turn that number back into
 * something by asking `ShaderManager` for the program, because a GL program is what it needs.
 * A backend that is not OpenGL needs something else - the identity of the shader SOURCE - and
 * it must not reach for `PainterShaderProgram` to get it: that class's header pulls in GLEW
 * through `shaderprogram.h`, and the Metal translation units deliberately import no OpenGL.
 *
 * So the description is published here instead, by whoever registers the shader, in a header
 * with no graphics-API dependency at all. It is a description and not an object: registration
 * happens once at module load and resolution happens per packet on the render thread.
 *
 * `sourceKey` is the `.frag` BASENAME rather than the registered shader name, because several
 * names share one file - Party, Radial Blur, Heat and Noise are each registered two or three
 * times - and the file is the unit the Phase 6 toolchain translates. A material registered
 * from inline code rather than from a file has an empty key: nothing was translated for it,
 * so a non-GL backend draws it with the default built-in and says so once.
 */
struct MaterialDesc
{
    std::string name;      // the registered ShaderManager name - diagnostics only
    std::string sourceKey; // the .frag basename; empty means "no translatable source"
};

class MaterialRegistry
{
public:
    static MaterialRegistry& instance();

    // Called from ShaderManager::putShader, on the main thread, once per registered program.
    void registerMaterial(MaterialHandle handle, MaterialDesc desc);

    // Null when the handle names nothing: a built-in, or a program registered before this
    // registry existed in the process. Callers fall back to the default material.
    [[nodiscard]] const MaterialDesc* resolve(MaterialHandle handle) const;

    void clear();

    [[nodiscard]] size_t size() const;

private:
    mutable std::shared_mutex m_mutex;
    std::unordered_map<uint16_t, MaterialDesc> m_materials;
};
