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

#include <framework/graphics/coordsbuffer.h>
#include <cmath>
#include <vector>

/*
 * Line triangulation.
 *
 * GL draws UIGraph's lines with GL_LINE_STRIP + glLineWidth + GL_LINE_SMOOTH. Metal has
 * neither wide lines nor smoothed ones, so a line has to become geometry: each segment
 * expands into a screen-space quad `width` pixels across, as two triangles.
 *
 * The result deliberately does NOT try to reproduce GL's rasterisation, because there is no
 * single GL rasterisation to reproduce - the two GL stacks already used as references
 * disagree with each other by 1.52% of the frame on identical `graph-lines` geometry, one
 * antialiasing wide lines and the other rasterising them hard-edged. Line scenes are
 * therefore compared same-environment only, and this path inherits that tolerance. It draws
 * analytics graphs, not game art.
 */
namespace RenderLines
{
    // Expands a polyline into triangles. Zero-length segments are skipped: a normal cannot be
    // derived from them, and the GL path draws nothing visible for them either.
    inline void triangulateStrip(CoordsBuffer& buffer, const std::vector<Point>& points, const float width)
    {
        if (points.size() < 2 || width <= 0.f)
            return;

        const float half = width * 0.5f;

        for (size_t i = 0; i + 1 < points.size(); ++i) {
            const PointF a{ static_cast<float>(points[i].x),     static_cast<float>(points[i].y) };
            const PointF b{ static_cast<float>(points[i + 1].x), static_cast<float>(points[i + 1].y) };

            const float dx = b.x - a.x;
            const float dy = b.y - a.y;
            const float len = std::sqrt(dx * dx + dy * dy);
            if (len <= 0.f)
                continue;

            // Normal of the segment, scaled to half the line width.
            const float nx = -dy / len * half;
            const float ny = dx / len * half;

            const PointF a0{ a.x + nx, a.y + ny };
            const PointF a1{ a.x - nx, a.y - ny };
            const PointF b0{ b.x + nx, b.y + ny };
            const PointF b1{ b.x - nx, b.y - ny };

            buffer.addTriangleF(a0, b0, a1);
            buffer.addTriangleF(a1, b0, b1);
        }
    }
}
