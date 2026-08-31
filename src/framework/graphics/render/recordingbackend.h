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

#include "renderframe.h"

#include <string>

/*
 * RecordingBackend - a backend with no GPU behind it.
 *
 * render() serialises the RenderFrame it is handed into a stable, human-readable text form:
 * every pass, packet, blend mode, scissor and resource handle, with a content hash of each
 * vertex slice standing in for the geometry itself.
 *
 * It exists for three jobs:
 *
 *  1. Testing the compiler on hardware that has no GPU - which is every CI runner this
 *     project uses. The output depends on nothing but the object list, because every handle
 *     the compiler mints is a pure function of its input.
 *
 *  2. Golden-frame regression tests. A refactor that reorders passes, drops a state bit or
 *     changes geometry fails a diff instead of shipping a rendering bug.
 *
 *  3. Triage when two real backends disagree visually. Record the frame both consumed: if the
 *     recordings match, the bug is BELOW the boundary in one backend; if they differ, it is
 *     in the compiler. That turns "the pixels differ" into a bisectable question - but only
 *     while the u_Time pin survives into every backend, since two frames captured at
 *     different animation phases have nothing to compare.
 *
 * Text rather than binary, deliberately: a golden diff is read by a person.
 */
class RecordingBackend
{
public:
    // Serialises the frame. Floats are printed at fixed precision so the output is stable
    // across platforms and compilers rather than merely stable on this machine.
    [[nodiscard]] static std::string record(const RenderFrame& frame);

    // Just the structure - passes, targets, load actions and packet counts. Useful when a
    // test cares about pass splitting and not about geometry.
    [[nodiscard]] static std::string recordStructure(const RenderFrame& frame);
};
