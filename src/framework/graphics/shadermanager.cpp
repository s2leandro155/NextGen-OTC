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

#include "shadermanager.h"

#include "paintershaderprogram.h"
#include "framework/core/eventdispatcher.h"
#include "framework/core/resourcemanager.h"
#include "render/materialregistry.h"
#include "framework/luaengine/luainterface.h"
#include "shader/shadersources.h"
#include <framework/platform/platformwindow.h>

ShaderManager g_shaders;

namespace
{
[[nodiscard]] std::string joinManagerShaderSources(const std::string_view first, const std::string_view second)
{
    std::string source;
    source.reserve(first.size() + second.size());
    source.append(first.data(), first.size());
    source.append(second.data(), second.size());
    return source;
}

// The `.frag` basename, which is the unit the Metal translation works in: several registered
// names share one file, so the file is what a material resolves to and the name is only a label.
[[nodiscard]] std::string sourceKeyOf(const std::string& path)
{
    const auto slash = path.find_last_of("/\\");
    auto name = slash == std::string::npos ? path : path.substr(slash + 1);
    if (const auto dot = name.find_last_of('.'); dot != std::string::npos)
        name.erase(dot);
    return name;
}
}

void ShaderManager::init() { PainterShaderProgram::release(); }
void ShaderManager::terminate() { clear(); }

void ShaderManager::clear() {
    {
        std::unique_lock lock(m_mutex);
        m_shaders.clear();
        m_shadersVector.clear();
    }

    MaterialRegistry::instance().clear();
}

void ShaderManager::putShader(std::string name, const PainterShaderProgramPtr& shader) {
    uint8_t id = 0;

    {
        std::unique_lock lock(m_mutex);

        if (const auto it = m_shaders.find(name); it != m_shaders.end()) {
            // Replace in place rather than refusing. A recreate has to keep the id it already had:
            // the id indexes m_shadersVector, is baked into the material handle, and is stored on
            // every Thing that names this shader. It is also a uint8_t, so handing out a fresh id
            // per recreate would exhaust the whole space after 255 of them.
            id = it->second->m_id;
            it->second = shader;
            shader->m_id = id;

            if (id > 0 && id <= m_shadersVector.size())
                m_shadersVector[id - 1] = shader;
        } else {
            if (m_shadersVector.size() >= std::numeric_limits<uint8_t>::max()) {
                g_logger.error("shader id space is exhausted, cannot register '{}'", name);
                return;
            }

            m_shaders.emplace(name, shader);
            m_shadersVector.emplace_back(shader);
            id = shader->m_id = static_cast<uint8_t>(m_shadersVector.size());
        }
    }

    // Publish what this handle names, in a form a backend that is not OpenGL can read. The
    // handle arithmetic is PoolCompiler::materialOf's, stated once here so the two cannot drift.
    MaterialRegistry::instance().registerMaterial(
        MaterialHandle{ static_cast<uint16_t>(
            static_cast<uint16_t>(BuiltinMaterial::FirstModule) + id) },
        MaterialDesc{ name, shader->getSourceKey() });

    // Compiling and linking happen asynchronously on this thread, and until now the only way for
    // Lua to learn that a program exists was to poll getShader - which raced this very function.
    // Announce it instead, on the thread Lua actually runs on.
    g_dispatcher.addEvent([name = std::move(name)] {
        g_lua.callGlobalField("g_shaders", "onShaderReady", name);
    });
}

bool ShaderManager::removeShader(const std::string_view name) {
    std::unique_lock lock(m_mutex);

    const auto it = m_shaders.find(std::string{ name });
    if (it == m_shaders.end())
        return false;

    const auto id = it->second->m_id;
    m_shaders.erase(it);

    if (id > 0 && id <= m_shadersVector.size())
        m_shadersVector[id - 1] = nullptr;

    return true;
}

// GLSL is compiled only where there is an OpenGL context to compile it for: the Vulkan feeder
// ignores painter shader programs and the Metal backend has its own translated set, and
// attempting it produces dozens of red "failed to compile shader" lines at startup.
//
// REGISTRATION IS NOT SKIPPED WITH IT, and that separation is the substance of Phase 6.
// Registration is what assigns the program its id, and the id is what PoolCompiler turns into a
// MaterialHandle - so skipping it meant every module draw on a non-GL backend compiled to the
// default material and rendered unshaded. Splitting the two also removes a determinism hazard
// that was there all along: putShader used to run only after a successful link, so one driver
// rejecting one .frag renumbered every shader registered after it, and two machines could
// disagree about which material a handle named.
static bool canCompileGlShaders()
{
    if (g_window.hasGLContext())
        return true;

    static bool logged = false;
    if (!logged) {
        logged = true;
        g_logger.info("no GL context: GLSL painter shaders are registered but not compiled");
    }
    return false;
}

void ShaderManager::createShader(const std::string_view name, bool useFramebuffer)
{
    g_mainDispatcher.addEvent([this, name = std::string{ name }, useFramebuffer] {
        const auto& shader = std::make_shared<PainterShaderProgram>();
        shader->setUseFramebuffer(useFramebuffer);
        putShader(name, shader);
    });
}

void ShaderManager::createFragmentShader(const std::string_view name, const std::string_view file, bool useFramebuffer)
{
    const auto& filePath = g_resources.resolvePath(std::string{ file });
    g_mainDispatcher.addEvent([this, name = std::string{ name }, filePath, useFramebuffer] {
        const auto& shader = std::make_shared<PainterShaderProgram>();
        shader->setUseFramebuffer(useFramebuffer);
        shader->m_sourceKey = sourceKeyOf(filePath);

        if (canCompileGlShaders()) {
            const auto& path = g_resources.guessFilePath(filePath, "frag");

            shader->addShaderFromSourceCode(ShaderType::VERTEX, joinManagerShaderSources(glslMainWithTexCoordsVertexShader, glslPositionOnlyVertexShader));
            if (!shader->addShaderFromSourceFile(ShaderType::FRAGMENT, path)) {
                g_logger.error("unable to load fragment shader '{}' from source file '{}'", name, path);
                return;
            }

            if (!shader->link()) {
                g_logger.error("unable to link shader '{}' from file '{}'", name, path);
                return;
            }
        }

        putShader(name, shader);
    });
}

void ShaderManager::createFragmentShaderFromCode(const std::string_view name, const std::string_view code, bool useFramebuffer)
{
    g_mainDispatcher.addEvent([this, name = std::string{ name }, code = std::string{ code }, useFramebuffer] {
        const auto& shader = std::make_shared<PainterShaderProgram>();
        shader->setUseFramebuffer(useFramebuffer);
        // Deliberately no source key: nothing was translated for a program that has no file, so
        // a backend with no GLSL compiler draws it with the default built-in and says so once.
        // This is the documented policy for runtime-supplied GLSL.

        if (canCompileGlShaders()) {
            shader->addShaderFromSourceCode(ShaderType::VERTEX, joinManagerShaderSources(glslMainWithTexCoordsVertexShader, glslPositionOnlyVertexShader));
            if (!shader->addShaderFromSourceCode(ShaderType::FRAGMENT, code)) {
                g_logger.error("unable to load fragment shader '{}'", name);
                return;
            }

            if (!shader->link()) {
                g_logger.error("unable to link shader '{}'", name);
                return;
            }
        }

        putShader(name, shader);
    });
}

void ShaderManager::setupItemShader(const std::string_view name)
{
    g_mainDispatcher.addEvent([this, name = std::string{ name }] {
        const auto& shader = getShader(name);
        if (!shader) return;
        shader->bindUniformLocation(ITEM_ID_UNIFORM, "u_ItemId");
    });
}

void ShaderManager::setupOutfitShader(const std::string_view name)
{
    g_mainDispatcher.addEvent([this, name = std::string{ name }] {
        const auto& shader = getShader(name);
        if (!shader) return;
        shader->bindUniformLocation(OUTFIT_ID_UNIFORM, "u_OutfitId");
    });
}

void ShaderManager::setupMountShader(const std::string_view name)
{
    g_mainDispatcher.addEvent([this, name = std::string{ name }] {
        const auto& shader = getShader(name);
        if (!shader) return;
        shader->bindUniformLocation(MOUNT_ID_UNIFORM, "u_MountId");
    });
}

void ShaderManager::setupMapShader(const std::string_view name)
{
    g_mainDispatcher.addEvent([this, name = std::string{ name }] {
        const auto& shader = getShader(name);
        if (!shader) return;
        shader->bindUniformLocation(MAP_CENTER_COORD, "u_MapCenterCoord");
        shader->bindUniformLocation(MAP_GLOBAL_COORD, "u_MapGlobalCoord");
        shader->bindUniformLocation(MAP_WALKOFFSET, "u_WalkOffset");
        shader->bindUniformLocation(MAP_ZOOM, "u_MapZoom");
    });
}

void ShaderManager::setupTextShader(const std::string_view name)
{
    g_mainDispatcher.addEvent([this, name = std::string{ name }] {
        const auto& shader = getShader(name);
        if (!shader) return;
        shader->bindUniformLocation(TEXT_OFFSET_UNIFORM, "u_Offset");
        shader->bindUniformLocation(TEXT_CENTER_UNIFORM, "u_Center");
    });
}

void ShaderManager::addMultiTexture(const std::string_view name, const std::string_view file)
{
    const auto& filePath = g_resources.resolvePath(std::string{ file });
    g_mainDispatcher.addEvent([this, name = std::string{ name }, filePath] {
        const auto& shader = getShader(name);
        if (!shader) return;
        shader->addMultiTexture(filePath);
    });
}

PainterShaderProgramPtr ShaderManager::getShader(const std::string_view name)
{
    std::shared_lock lock(m_mutex);

    const auto it = m_shaders.find(std::string{ name });
    if (it != m_shaders.end())
        return it->second;

    return nullptr;
}

PainterShaderProgramPtr ShaderManager::getShaderById(const uint8_t id) const
{
    std::shared_lock lock(m_mutex);

    return id > 0 && id <= m_shadersVector.size() ? m_shadersVector[id - 1] : nullptr;
}
