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

#include "recordingbackend.h"

#include <algorithm>
#include <cstdio>
#include <cstring>
#include <sstream>

namespace
{
    const char* blendName(const BlendMode mode)
    {
        switch (mode) {
            case BlendMode::Normal:        return "Normal";
            case BlendMode::Multiply:      return "Multiply";
            case BlendMode::AddWeird:      return "AddWeird";
            case BlendMode::Replace:       return "Replace";
            case BlendMode::DestBlend:     return "DestBlend";
            case BlendMode::LightModulate: return "LightModulate";
        }
        return "?";
    }

    const char* loadName(const LoadAction load)
    {
        return load == LoadAction::Clear ? "Clear" : "Keep";
    }

    // Fixed precision, so a recording made by one compiler equals one made by another.
    std::string f(const float v)
    {
        char buf[32];
        std::snprintf(buf, sizeof(buf), "%.4f", v);
        return buf;
    }

    std::string rectOf(const Rect& r)
    {
        if (!r.isValid())
            return "-";
        std::ostringstream ss;
        ss << r.left() << ',' << r.top() << ',' << r.width() << 'x' << r.height();
        return ss.str();
    }

    // A content hash of the slice's geometry. Recording every vertex would make a golden file
    // enormous and unreadable; a hash still fails the diff when geometry changes.
    //
    // FNV-1a over the raw float BITS rather than std::hash. std::hash<float> is
    // implementation-defined, so a golden file produced under libc++ would not match one
    // produced under libstdc++ - and the whole point of a golden file here is that it is
    // checked in once and gates every platform's CI.
    uint64_t fnv1a(uint64_t hash, const float value)
    {
        uint32_t bits;
        std::memcpy(&bits, &value, sizeof(bits));

        // Normalise -0.0 to 0.0 so two numerically equal vertices hash equal.
        if (bits == 0x80000000u)
            bits = 0u;

        for (int byte = 0; byte < 4; ++byte) {
            hash ^= static_cast<uint8_t>(bits >> (byte * 8));
            hash *= 0x00000100000001B3ull;
        }
        return hash;
    }

    uint64_t sliceHash(const VertexArena* arena, const uint32_t offset, const uint32_t count, const bool textured)
    {
        if (!arena || count == 0)
            return 0;

        const auto available = arena->vertexCount();
        if (offset >= available)
            return 0;
        const auto usable = std::min<uint32_t>(count, available - offset);

        uint64_t hash = 0xCBF29CE484222325ull;
        const float* pos = arena->positions() + static_cast<size_t>(offset) * 2;
        for (uint32_t i = 0; i < usable * 2; ++i)
            hash = fnv1a(hash, pos[i]);

        if (textured) {
            const float* uv = arena->texCoords() + static_cast<size_t>(offset) * 2;
            for (uint32_t i = 0; i < usable * 2; ++i)
                hash = fnv1a(hash, uv[i]);
        }
        return hash;
    }
}

std::string RecordingBackend::recordStructure(const RenderFrame& frame)
{
    std::ostringstream ss;
    ss << "frame " << frame.drawableSize.width() << 'x' << frame.drawableSize.height()
       << " passes=" << frame.passes.size()
       << " uploads=" << frame.uploads.size()
       << " readbacks=" << frame.readbacks.size() << '\n';

    for (size_t i = 0; i < frame.passes.size(); ++i) {
        const auto& pass = frame.passes[i];
        ss << "  pass[" << i << "] target=" << pass.target.id
           << " load=" << loadName(pass.load)
           << " viewport=" << rectOf(pass.viewport)
           << " packets=" << pass.packets.size()
           << " label=" << (pass.label.empty() ? "-" : pass.label) << '\n';
    }
    return ss.str();
}

std::string RecordingBackend::record(const RenderFrame& frame)
{
    std::ostringstream ss;
    ss << "frame " << frame.drawableSize.width() << 'x' << frame.drawableSize.height() << '\n';

    for (const auto& upload : frame.uploads) {
        ss << "  upload tex=" << upload.texture.id
           << " size=" << upload.size.width() << 'x' << upload.size.height()
           << " bytes=" << upload.pixels.size() << '\n';
    }

    for (size_t i = 0; i < frame.passes.size(); ++i) {
        const auto& pass = frame.passes[i];
        ss << "  pass[" << i << "] target=" << pass.target.id
           << " load=" << loadName(pass.load)
           << " clear=" << static_cast<int>(pass.clearColor.a())
           << " viewport=" << rectOf(pass.viewport)
           << " label=" << (pass.label.empty() ? "-" : pass.label) << '\n';

        for (size_t j = 0; j < pass.packets.size(); ++j) {
            const auto& p = pass.packets[j];
            ss << "    packet[" << j << "]"
               << " verts=" << p.vertexCount
               << " geom=" << sliceHash(pass.arena, p.vertexOffset, p.vertexCount, p.textured)
               << " tex=" << p.texture.id
               << " texMat=" << p.textureMatrixId
               << " mat=" << p.material.id
               << " blend=" << blendName(p.blend)
               << " blendOn=" << (p.blendEnabled ? 1 : 0)
               << " alphaW=" << (p.alphaWrite ? 1 : 0)
               << " opacity=" << f(p.opacity)
               << " color=" << static_cast<int>(p.color.r()) << ':' << static_cast<int>(p.color.g())
               << ':' << static_cast<int>(p.color.b()) << ':' << static_cast<int>(p.color.a())
               << " scissor=" << (p.scissorEnabled ? rectOf(p.scissor) : std::string("off"))
               << (p.scissorEnabled && !p.scissor.isValid() ? "(all)" : "");

            if (p.params)
                ss << " params(time=" << f(p.params->time) << ",zoom=" << f(p.params->mapZoom) << ')';

            ss << '\n';
        }
    }

    for (const auto& readback : frame.readbacks)
        ss << "  readback src=" << readback.source.id << " region=" << rectOf(readback.region) << '\n';

    return ss.str();
}
