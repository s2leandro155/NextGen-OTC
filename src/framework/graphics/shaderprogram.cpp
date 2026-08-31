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

#include "shaderprogram.h"
#include "glutil.h"

#include "graphics.h"
#include "shader.h"
#include "client/creature.h"
#include "framework/core/eventdispatcher.h"
#include "framework/core/graphicalapplication.h"
#include <framework/platform/platformwindow.h>

#include <atomic>

uint32_t ShaderProgram::m_currentProgram = 0;

namespace
{
    // Identity for programs that have no GL name to be identified by. Seeded far above any id
    // glCreateProgram would hand out so that the two spaces cannot collide in a session that
    // has both - a Vulkan run that falls back to GL builds a second Painter, with programs.
    std::atomic_uint32_t INERT_PROGRAM_SEED{ 1u << 24 };
}

// Constructed WITHOUT a GL context, this object compiles nothing and stays inert - and that is a
// use, not a degraded state. A draw records which material it wants by naming the program it
// bound, and `Painter`'s replace-colour program is what every marked creature and highlighted
// item binds; a backend that is not OpenGL needs that identity and nothing else about it. All the
// GL entry points below guard on the program id, so an inert program is safe to link, bind and
// destroy - it simply does none of those things.
ShaderProgram::ShaderProgram() : m_programId(g_window.hasGLContext() ? glCreateProgram() : 0)
{
    m_uniformLocations.fill(-1);

    if (!m_programId) {
        if (!g_window.hasGLContext()) {
            // The hash has to be distinct per program even here. DrawPool's state hash folds it
            // in, and PoolState equality IS hash equality - so leaving every inert program at the
            // same value would batch two draws that wanted different materials into one.
            m_hash = stdext::hash_int(INERT_PROGRAM_SEED.fetch_add(1, std::memory_order_relaxed));
            return;
        }

        g_logger.fatal("Unable to create GL shader program");
    }

    m_hash = stdext::hash_int(m_programId);
}

ShaderProgram::~ShaderProgram()
{
#ifndef NDEBUG
    assert(!g_app.isTerminated());
#endif
    if (g_graphics.ok() && m_programId != 0) {
        g_mainDispatcher.addEvent([id = m_programId] {
            glDeleteProgram(id);
        });
    }
}

bool ShaderProgram::addShader(const ShaderPtr& shader)
{
    glAttachShader(m_programId, shader->getShaderId());
    m_linked = false;
    m_shaders.emplace_back(shader);
    m_hash = stdext::hash_int(m_programId);
    return true;
}

bool ShaderProgram::addShaderFromSourceCode(ShaderType shaderType, const std::string_view sourceCode)
{
    // Nothing to compile into, and Shader's own constructor would reach glCreateShader. Reported
    // as success because the caller asked for a program carrying this source and got the only
    // thing this configuration can give it.
    if (!hasGLProgram())
        return true;

    const auto& shader = std::make_shared<Shader>(shaderType);
    if (shader->compileSourceCode(sourceCode))
        return addShader(shader);

    g_logger.error("failed to compile shader: {}", shader->log());
    return false;
}

bool ShaderProgram::addShaderFromSourceFile(ShaderType shaderType, const std::string_view sourceFile)
{
    const auto& shader = std::make_shared<Shader>(shaderType);
    if (shader->compileSourceFile(sourceFile))
        return addShader(shader);

    g_logger.error("failed to compile shader: {}", shader->log());
    return false;
}

void ShaderProgram::removeShader(const ShaderPtr& shader)
{
    const auto it = std::ranges::find(m_shaders, shader);
    if (it == m_shaders.end())
        return;

    glDetachShader(m_programId, shader->getShaderId());
    m_shaders.erase(it);
    m_linked = false;
    m_hash = 0;
}

void ShaderProgram::removeAllShaders()
{
    while (!m_shaders.empty())
        removeShader(m_shaders.front());
}

bool ShaderProgram::link()
{
    if (m_linked)
        return true;

    if (!hasGLProgram())
        return false;

    glLinkProgram(m_programId);

    int value = GL_FALSE;
    glGetProgramiv(m_programId, GL_LINK_STATUS, &value);
    m_linked = (value != GL_FALSE);

    if (!m_linked)
        g_logger.traceWarning(log());

    return m_linked;
}

bool ShaderProgram::bind()
{
    if (!hasGLProgram())
        return false;

    if (m_currentProgram == m_programId)
        return false;

    if (!m_linked && !link())
        return false;

    glUseProgram(m_programId);
    m_currentProgram = m_programId;
    return true;
}

void ShaderProgram::release()
{
    if (m_currentProgram == 0)
        return;

    m_currentProgram = 0;
    glUseProgram(0);
}

std::string ShaderProgram::log() const
{
    std::string infoLog;
    int infoLogLength = 0;
    glGetProgramiv(m_programId, GL_INFO_LOG_LENGTH, &infoLogLength);
    if (infoLogLength > 1) {
        std::vector<char> buf(infoLogLength);
        glGetShaderInfoLog(m_programId, infoLogLength - 1, nullptr, &buf[0]);
        infoLog = &buf[0];
    }
    return infoLog;
}

int ShaderProgram::getAttributeLocation(const char* name) const
{
    return hasGLProgram() ? glGetAttribLocation(m_programId, name) : -1;
}

void ShaderProgram::bindAttributeLocation(const int location, const char* name) const
{
    if (hasGLProgram())
        glBindAttribLocation(m_programId, location, name);
}

void ShaderProgram::bindUniformLocation(const int location, const char* name)
{
    assert(location >= 0 && location < MAX_UNIFORM_LOCATIONS);

    // An inert program - one built with no GL context - has no locations to look up, and the
    // GLEW entry point is a null pointer there rather than a function that fails politely. This
    // became reachable in Phase 6: module shaders are now REGISTERED without a GL context so
    // that they have a material identity, which means ShaderManager's setup*Shader calls run on
    // programs that were never linked. Every location stays -1, which glUniform* ignores by
    // specification, so a stray upload on such a program is a no-op rather than a corruption.
    if (!hasGLProgram())
        return;

    assert(m_linked);
    m_uniformLocations[location] = glGetUniformLocation(m_programId, name);
}
