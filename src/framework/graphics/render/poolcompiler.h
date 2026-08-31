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

#include "poolprogram.h"

class DrawPool;
class PainterShaderProgram;

/*
 * PoolCompiler - the successor to VkDrawFeeder.
 *
 * It reads a pool's PUBLISHED object list (m_objectsDraw[0], the buffer release() just filled
 * under the pool's lock) together with the declared side-channels, and produces explicit
 * passes and packets. It executes nothing: not one action callback, not one GL call.
 *
 * The two properties it is built for:
 *
 *  - DETERMINISM. Every handle it mints is a pure function of pool type, nesting depth, or a
 *    texture's process-wide unique id. The same object list compiles to identical output on
 *    any thread and any platform, which is what makes golden-frame tests meaningful and what
 *    lets a recorded frame decide whether a GL/Metal difference is above or below the boundary.
 *
 *  - HONESTY. Anything it cannot express goes into PoolProgram::unsupported and poisons the
 *    program. It never silently drops a draw.
 */
class PoolCompiler
{
public:
    // Compiles the pool's published object list. `viewportSize` is the drawable size, used as
    // the viewport for pools that render straight to the backbuffer.
    static void compile(const DrawPool& pool, const Size& viewportSize, PoolProgram& out);

    // The material a painter shader program maps to. Module programs are numbered from
    // BuiltinMaterial::FirstModule so they can never collide with a built-in.
    [[nodiscard]] static MaterialHandle materialOf(const PainterShaderProgram* program);
};
