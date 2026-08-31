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

#include <shared_mutex>

 //@bindsingleton g_shaders
class ShaderManager
{
public:
    // The client extension of the framework's uniform-location space. ITEM_ID_UNIFORM used to
    // be 10 - the same slot PainterShaderProgram::TRANSFORM_MATRIX_UNIFORM binds u_TransformMatrix
    // to, and writes on every single draw - so an item shader binding u_ItemId would have had its
    // uniform aliased by a matrix, and a backend uploading the parameter block onto these slots
    // would have corrupted the transform. It was latent rather than live, because nothing in
    // modules/ or mods/ ever called setupItemShader; it is retired here anyway, because a
    // parameter block that cannot be uploaded in full is not a parameter block.
    //
    // 20 is chosen over renumbering 11-19: those are already bound by shipped shaders' setup
    // calls, and moving them would change nothing while breaking any out-of-repo module that
    // hardcoded one. MAX_UNIFORM_LOCATIONS is 30.
    enum
    {
        ITEM_ID_UNIFORM = 20,
        OUTFIT_ID_UNIFORM = 11,
        MOUNT_ID_UNIFORM = 12,
        SHADER_ID_UNIFORM = 13,
        MAP_ZOOM = 14,
        MAP_WALKOFFSET = 15,
        MAP_CENTER_COORD = 16,
        MAP_GLOBAL_COORD = 17,
        TEXT_OFFSET_UNIFORM = 18,
        TEXT_CENTER_UNIFORM = 19,
    };

    void init();
    void terminate();
    void clear();

    // TODO: Move these setup methods to a ClientShaderManager
    void setupMapShader(std::string_view name);
    void setupTextShader(std::string_view name);
    void setupItemShader(std::string_view name);
    void setupOutfitShader(std::string_view name);
    void setupMountShader(std::string_view name);

    void createShader(std::string_view name, bool useFramebuffer = false);
    void createFragmentShader(std::string_view name, std::string_view file, bool useFramebuffer = false);
    void createFragmentShaderFromCode(std::string_view name, std::string_view code, bool useFramebuffer = false);

    void addMultiTexture(std::string_view name, std::string_view file);

    // Forgets the name and empties its slot. The slot itself is kept: an id indexes m_shadersVector
    // and is baked into every material handle and every Thing that names the shader, so compacting
    // the vector would silently renumber every shader registered after this one.
    bool removeShader(std::string_view name);

    PainterShaderProgramPtr getShader(std::string_view name);
    PainterShaderProgramPtr getShaderById(uint8_t id) const;

private:
    void putShader(std::string name, const PainterShaderProgramPtr& shader);

    // Registration happens on the main thread, from inside the g_mainDispatcher lambdas that
    // compile and link. Lookup happens on the map and async threads: getShader is bound straight to
    // Lua, and getShaderById is called while recording the draw pools. stdext::map is open
    // addressing, so an insert can rehash and move the whole slot array out from under a concurrent
    // find - and m_shadersVector reallocates as it grows. Both need guarding.
    mutable std::shared_mutex m_mutex;
    stdext::map<std::string, PainterShaderProgramPtr> m_shaders;
    std::vector<PainterShaderProgramPtr> m_shadersVector;
};

extern ShaderManager g_shaders;
