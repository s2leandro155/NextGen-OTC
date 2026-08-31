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

#include "framework/util/color.h"

#include <algorithm>
#include <cmath>
#include <cstdint>

// The world-light cross-fade of the official client.
//
// A server never sends a gradient. It sends one (level, palette index) pair every ten seconds,
// and left alone those land as a slideshow - the same six-band ramp that reads as a smooth
// dusk in the official client arrives here as six hard cuts. What the official client does with
// them is fade: DURATION_MS below is its own GRAPHICS/millisecondsForAmbientLightChange,
// transcribed from the 15.32 macOS binary rather than tuned.
//
// The 200 ms of overlap past the server's tick is the whole point of the number and not a
// rounding artefact. A fade is always still in flight when the next value lands, so the light
// never comes to rest on one of the steps, and consecutive fades read as one continuous ramp.
namespace AmbientFade
{
    // GRAPHICS/millisecondsForAmbientLightChange, default 0x27d8.
    inline constexpr int64_t DURATION_MS = 10200;

    // How often a world light arrives - crystalserver's EVENT_LIGHTINTERVAL_MS, and the
    // official server's cadence too. Recorded here only so the overlap above stays checkable.
    inline constexpr int64_t SERVER_TICK_MS = 10000;

    // A world light with its hue resolved out of the palette. The two halves stay apart because
    // the roof and cloud policies in MapView::updateLight both have to work on the brightness
    // before it is ever multiplied into the colour.
    struct Value
    {
        Color base{ Color::white };  // the palette entry at full strength
        float intensity{ 0.f };      // 0..255, as the protocol sends it
    };

    inline Value resolve(const uint8_t colorIndex, const uint8_t intensity)
    {
        // Resolving to RGB here is what makes a fade possible at all. The palette is a 6x6x6
        // cube indexed r*36 + g*6 + b, so it is not a continuous space: interpolating the index
        // walks through entries neither endpoint asked for - 200 to 123 passes through greens
        // and teals on its way from orange to mauve - whereas interpolating the colours those
        // indices name goes straight there.
        return { Color::from8bit(colorIndex), static_cast<float>(intensity) };
    }

    inline float progress(const int64_t elapsedMs)
    {
        return std::clamp(static_cast<float>(elapsedMs) / DURATION_MS, 0.f, 1.f);
    }

    // std::lerp rather than the hand-written form: it is the one that lands exactly on `to` at
    // t == 1. `a + (b - a) * t` misses by an ulp there, and Color truncates on the way back to
    // bytes, so that ulp becomes a whole unit of colour left standing at the end of every fade.
    inline Value blend(const Value& from, const Value& to, const float t)
    {
        return { Color(std::lerp(from.base.rF(), to.base.rF(), t),
                       std::lerp(from.base.gF(), to.base.gF(), t),
                       std::lerp(from.base.bF(), to.base.bF(), t)),
                 std::lerp(from.intensity, to.intensity, t) };
    }
}
