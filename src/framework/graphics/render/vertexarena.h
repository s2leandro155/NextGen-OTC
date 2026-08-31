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
#include <algorithm>
#include <cstdint>
#include <vector>

/*
 * VertexArena - the compiled geometry store for one pool.
 *
 * The GL path draws straight out of client memory: two separate float2 arrays, no buffer
 * objects anywhere, handed to glVertexAttribPointer per draw. The arena keeps that shape
 * (positions and texture coordinates stay NON-interleaved, because the fixed vertex stage
 * takes them as two attributes) but consolidates a whole pool's geometry into two growable
 * buffers that packets address by (offset, count).
 *
 * Backends upload an arena however suits them - GL can keep pointing attributes straight at
 * it, Metal copies it into a per-frame MTLBuffer ring - without either having to understand
 * where the vertices came from.
 *
 * The texture-coordinate buffer is ALWAYS kept the same length as the position buffer, even
 * for untextured geometry that has no texture coordinates at all. That wastes 8 bytes per
 * untextured vertex and buys a single shared offset per slice: a packet indexes both arrays
 * with one number instead of carrying two. `DrawPacket::textured` says whether the texture
 * coordinates at that offset mean anything.
 */
class VertexArena
{
public:
    struct Slice
    {
        uint32_t offset{ 0 }; // in VERTICES, not floats
        uint32_t count{ 0 };
        bool textured{ false };

        [[nodiscard]] constexpr bool isEmpty() const { return count == 0; }
    };

    void clear()
    {
        m_positions.clear();
        m_texCoords.clear();
    }

    void reserveVertices(const size_t vertices)
    {
        m_positions.reserve(vertices * 2);
        m_texCoords.reserve(vertices * 2);
    }

    // Copies a producer-side CoordsBuffer in. A CoordsBuffer may legitimately carry zero
    // texture coordinates (solid-colour geometry) - that is what makes the slice untextured.
    Slice append(const CoordsBuffer& coords)
    {
        const auto count = static_cast<uint32_t>(coords.getVertexCount());
        if (count == 0)
            return {};

        const auto texCoordCount = static_cast<uint32_t>(coords.getTextureCoordCount());
        const Slice slice{ vertexCount(), count, texCoordCount > 0 };

        m_positions.append(coords.getVertexArray(), count * 2);

        if (texCoordCount > 0) {
            const float* uv = coords.getTextureCoordArray();
            // Defensive: CoordsBuffer builds the two arrays in lockstep, but a packet that
            // indexed past the end would be a memory error rather than a visual one.
            const auto usable = std::min(texCoordCount, count);
            m_texCoords.append(uv, usable * 2);
            if (usable < count)
                m_texCoords.claimZeroed((count - usable) * 2);
        } else {
            m_texCoords.claimZeroed(count * 2);
        }

        return slice;
    }

    [[nodiscard]] uint32_t vertexCount() const { return static_cast<uint32_t>(m_positions.size() / 2); }
    [[nodiscard]] const float* positions() const { return m_positions.data(); }
    [[nodiscard]] const float* texCoords() const { return m_texCoords.data(); }

    // Byte size of ONE of the two arrays; a backend uploading both needs this twice.
    [[nodiscard]] size_t arrayBytes() const { return m_positions.size() * sizeof(float); }

private:
    // Same claim-and-write buffer VertexArray uses, for the same reason: an arena append is a
    // bulk copy of a whole CoordsBuffer, and the texture-coordinate padding untextured geometry
    // owes is a zero-fill the vector API could only express as a second pass over the data.
    FloatBuffer m_positions;
    FloatBuffer m_texCoords;
};
