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

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>

// The drifting cloud shadows of the official client, taken from TLightMap in the 15.32 macOS
// binary. Three travelling sine waves are summed per map tile; only the troughs count, so the
// field subtracts light from an otherwise sunlit map and never adds any.
//
// The numbers below are transcribed, not tuned - periods, directions, amplitudes and both
// scroll rates are the client's own. Two of them look like mistakes and are not. The clamp is
// deliberately one-sided, and that one carries the whole look of the effect. Pi is the client's
// hard-coded 3.14f, and that one is nearly cosmetic: against a real pi the phase drifts by at
// most 0.05%, worth about 0.007 of coverage at its widest. It is kept because it is what the
// client computes, not because the difference is visible.
namespace CloudField
{
    // TLightMap's SpeedFactor - the master scale behind every period and both scroll rates.
    inline constexpr int SPEED_FACTOR = 500;

    struct Wave
    {
        int64_t period;    // milliseconds for one full phase rotation
        float dirX, dirY;  // radians per map tile
        float amplitude;
    };

    inline constexpr std::array<Wave, 3> WAVES{ {
        { SPEED_FACTOR * 31, 0.5f,    1.0f,  0.25f },  // fine ripple, about 6 tiles across
        { SPEED_FACTOR * 43, 0.25f,  -0.25f, 0.5f  },  // diagonal banding, about 25 tiles
        { SPEED_FACTOR * 67, 0.125f,  0.25f, 1.0f  },  // the dominant cloud mass, about 50
    } };

    // The three periods are coprime multiples of SPEED_FACTOR, so the field only repeats after
    // their product - 12 h 24 m. Folding time into that span keeps the floats small enough to
    // stay precise without moving a single sample.
    inline constexpr int64_t PHASE_PERIOD_LCM = static_cast<int64_t>(SPEED_FACTOR) * 31 * 43 * 67;

    // How much sun a tile keeps: 1 in the open, down to 0 at the heart of a shadow. Takes world
    // coordinates rather than screen ones, so the pattern stays pinned to the map and slides
    // past the player as they walk instead of travelling with the camera.
    inline float coverage(const int64_t timeMs, const float worldX, const float worldY)
    {
        const int64_t t = timeMs % PHASE_PERIOD_LCM;
        const float seconds = t * 0.001f;

        // Two drifts on each axis: a steady push, and the scroll the waves themselves ride on.
        // They oppose, and what is left is about half a tile per second westward, crossed with
        // a north-south meander that takes some twelve minutes to come back around.
        const float x = worldX + seconds * 0.5f - t / (1.9f * SPEED_FACTOR);
        const float y = worldY + std::sin(seconds / 120.f) * 120.f - t / (20.f * SPEED_FACTOR);

        float sum = 0.f;
        for (const auto& wave : WAVES) {
            const float phase = static_cast<float>(t % wave.period) / wave.period;
            sum += wave.amplitude * std::sin(2.f * 3.14f * phase + wave.dirX * x + wave.dirY * y);
        }

        // Crests are thrown away before the depth is capped. Discarding them is what makes this
        // read as shadows cast onto a sunlit map, rather than as brightness noise across all
        // of it - a tile is either in shade or it is in plain sun.
        return 1.f + std::clamp(sum * 1.5f, -1.f, 0.f);
    }
}
