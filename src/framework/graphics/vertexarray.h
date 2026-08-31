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

#include <cstring>
#include <memory>

/*
 * FloatBuffer - a growable float array whose appends are stores, not calls.
 *
 * This exists because std::vector is the wrong shape for the access pattern underneath it.
 * Every quad the client draws appends exactly twelve floats, and `insert(end(), first, last)`
 * turns that into a range construction that bottoms out in memmove - a call whose fixed
 * overhead dwarfs 48 bytes of payload. Profiling one producer frame put 57% of
 * DrawPool::add inside those inserts and the _platform_memmove beneath them, which was 28%
 * of the whole frame, to move data that fits in six SIMD registers.
 *
 * `claim(n)` hands back a write pointer for n floats and leaves them UNINITIALISED, so a
 * caller writes each value exactly once. resize() would have been the small fix, but it
 * value-initialises what it hands over, so every append would zero the bytes before
 * overwriting them - two passes where one will do.
 *
 * Growth doubles, so the amortised cost of an append is the stores alone.
 */
class FloatBuffer
{
public:
    explicit FloatBuffer(const size_t capacity = 64) { reserve(capacity); }

    FloatBuffer(const FloatBuffer& other) { assign(other); }
    FloatBuffer& operator=(const FloatBuffer& other)
    {
        if (this != &other)
            assign(other);
        return *this;
    }

    FloatBuffer(FloatBuffer&& other) noexcept
        : m_data(std::move(other.m_data)), m_size(other.m_size), m_capacity(other.m_capacity)
    {
        other.m_size = other.m_capacity = 0;
    }
    FloatBuffer& operator=(FloatBuffer&& other) noexcept
    {
        if (this != &other) {
            m_data = std::move(other.m_data);
            m_size = other.m_size;
            m_capacity = other.m_capacity;
            other.m_size = other.m_capacity = 0;
        }
        return *this;
    }

    ~FloatBuffer() = default;

    // Reserves room for n more floats and returns where to write them. The floats are
    // uninitialised: the caller owns all n of them and must write every one.
    float* claim(const size_t count)
    {
        if (m_size + count > m_capacity)
            grow(m_size + count);

        float* const at = m_data.get() + m_size;
        m_size += count;
        return at;
    }

    // Same, but zero-filled - for the texture-coordinate padding VertexArena owes untextured
    // geometry, which is the one place the client wants defined bytes it never writes.
    float* claimZeroed(const size_t count)
    {
        float* const at = claim(count);
        std::memset(at, 0, count * sizeof(float));
        return at;
    }

    void append(const float* source, const size_t count)
    {
        if (count > 0)
            std::memcpy(claim(count), source, count * sizeof(float));
    }

    // Keeps the allocation, as std::vector::clear does - the pools reuse these buffers every
    // frame and re-growing them each time is exactly what the cache is there to avoid.
    void clear() { m_size = 0; }

    void reserve(const size_t capacity)
    {
        if (capacity > m_capacity)
            grow(capacity);
    }

    const float* data() const { return m_data.get(); }
    size_t size() const { return m_size; }
    bool empty() const { return m_size == 0; }

private:
    void assign(const FloatBuffer& other)
    {
        m_size = 0;
        reserve(other.m_size);
        append(other.m_data.get(), other.m_size);
    }

    void grow(const size_t needed)
    {
        size_t capacity = m_capacity > 0 ? m_capacity : 64;
        while (capacity < needed)
            capacity *= 2;

        // Plain new[] rather than make_unique: for a trivial type that is DEFAULT-initialisation,
        // which leaves the bytes indeterminate. make_unique would value-initialise and zero the
        // whole buffer, which is the cost this class exists to avoid, and
        // make_unique_for_overwrite would be right but is C++20 - and this header is compiled by
        // the Android NDK and Emscripten toolchains too.
        std::unique_ptr<float[]> next(new float[capacity]);
        if (m_size > 0)
            std::memcpy(next.get(), m_data.get(), m_size * sizeof(float));

        m_data = std::move(next);
        m_capacity = capacity;
    }

    std::unique_ptr<float[]> m_data;
    size_t m_size{ 0 };
    size_t m_capacity{ 0 };
};

class VertexArray
{
public:
    VertexArray(const size_t size = 64) : m_buffer(size) {}

    ~VertexArray() = default;

    void addTriangle(const Point& a, const Point& b, const Point& c)
    {
        float* const v = m_buffer.claim(6);
        v[0] = a.x; v[1] = a.y;
        v[2] = b.x; v[3] = b.y;
        v[4] = c.x; v[5] = c.y;
    }

    // Float-precision triangle. The integer addTriangle above is fine for the axis-aligned
    // geometry the client draws, but a triangulated line's offset normal is a fraction of a
    // pixel on any diagonal segment, and rounding it visibly bends thin lines.
    void addTriangleF(const PointF& a, const PointF& b, const PointF& c)
    {
        float* const v = m_buffer.claim(6);
        v[0] = a.x; v[1] = a.y;
        v[2] = b.x; v[3] = b.y;
        v[4] = c.x; v[5] = c.y;
    }

    void addRect(const Rect& rect)
    {
        const float top = rect.top();
        const float right = rect.right() + 1;
        const float bottom = rect.bottom() + 1;
        const float left = rect.left();

        float* const v = m_buffer.claim(12);
        v[0] = left;  v[1] = top;
        v[2] = right; v[3] = top;
        v[4] = left;  v[5] = bottom;
        v[6] = left;  v[7] = bottom;
        v[8] = right; v[9] = top;
        v[10] = right; v[11] = bottom;
    }

    void addRect(const RectF& rect)
    {
        const float top = rect.top();
        const float right = rect.right() + 1.f;
        const float bottom = rect.bottom() + 1.f;
        const float left = rect.left();

        float* const v = m_buffer.claim(12);
        v[0] = left;  v[1] = top;
        v[2] = right; v[3] = top;
        v[4] = left;  v[5] = bottom;
        v[6] = left;  v[7] = bottom;
        v[8] = right; v[9] = top;
        v[10] = right; v[11] = bottom;
    }

    void addQuad(const Rect& rect)
    {
        const float top = rect.top();
        const float right = rect.right() + 1;
        const float bottom = rect.bottom() + 1;
        const float left = rect.left();

        float* const v = m_buffer.claim(12);
        v[0] = left;  v[1] = top;
        v[2] = right; v[3] = top;
        v[4] = left;  v[5] = bottom;
        v[6] = left;  v[7] = bottom;
        v[8] = right; v[9] = top;
        v[10] = right; v[11] = bottom;
    }

    void addHorizontallyFlippedQuad(const Rect& rect)
    {
        const float top = rect.top();
        const float right = rect.right() + 1;
        const float bottom = rect.bottom() + 1;
        const float left = rect.left();

        // Inverte left e right para flip horizontal
        float* const v = m_buffer.claim(12);
        v[0] = right; v[1] = top;
        v[2] = left;  v[3] = top;
        v[4] = right; v[5] = bottom;
        v[6] = right; v[7] = bottom;
        v[8] = left;  v[9] = top;
        v[10] = left; v[11] = bottom;
    }

    void addVerticallyFlippedQuad(const Rect& rect)
    {
        const float top = rect.top();
        const float right = rect.right() + 1;
        const float bottom = rect.bottom() + 1;
        const float left = rect.left();

        // Inverte top e bottom para flip vertical
        float* const v = m_buffer.claim(12);
        v[0] = left;  v[1] = bottom;
        v[2] = right; v[3] = bottom;
        v[4] = left;  v[5] = top;
        v[6] = left;  v[7] = top;
        v[8] = right; v[9] = bottom;
        v[10] = right; v[11] = top;
    }

    // The one four-vertex primitive here: a strip quad, not two triangles.
    void addUpsideDownQuad(const Rect& rect)
    {
        const float top = rect.top();
        const float right = rect.right() + 1;
        const float bottom = rect.bottom() + 1;
        const float left = rect.left();

        float* const v = m_buffer.claim(8);
        v[0] = left;  v[1] = bottom;
        v[2] = right; v[3] = bottom;
        v[4] = left;  v[5] = top;
        v[6] = right; v[7] = top;
    }

    void addUpsideDownRect(const Rect& rect)
    {
        const float top = rect.top();
        const float right = rect.right() + 1;
        const float bottom = rect.bottom() + 1;
        const float left = rect.left();

        float* const v = m_buffer.claim(12);
        v[0] = left;  v[1] = bottom;
        v[2] = right; v[3] = bottom;
        v[4] = left;  v[5] = bottom;
        v[6] = left;  v[7] = top;
        v[8] = right; v[9] = bottom;
        v[10] = right; v[11] = top;
    }

    void append(const VertexArray* buffer) {
        m_buffer.append(buffer->m_buffer.data(), buffer->m_buffer.size());
    }

    void clear() { m_buffer.clear(); }

    const float* vertices() const { return m_buffer.data(); }
    int vertexCount() const { return m_buffer.size() / 2; }
    int size() const { return m_buffer.size(); }

private:
    FloatBuffer m_buffer;
};
