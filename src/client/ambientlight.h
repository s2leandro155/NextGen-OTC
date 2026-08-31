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
#include <cstdint>

// The Ambient Light and Clouds & Indoor Effect options, as the official client applies them -
// transcribed from TLightMap and TEffectsQMLOptionsPage in the 15.32 macOS binary rather than
// matched by eye.
//
// The one thing to know before reading further: ambient light is NOT a brightness floor. It is
// a lerp of the world light towards a fixed tint, and it is quantised to half strength on the
// way in. Both of those are easy to mistake for bugs and both are what the client does.
namespace AmbientLight
{
    // TLightMap's constructor takes the 0..1 option and stores `(uint8)(level * 127)` - 127,
    // where every other 0..1-to-byte conversion in the client uses 255. Everything downstream
    // divides by 255 again, so the option can only ever contribute half of what its name
    // suggests: at 100% a pitch-black scene reaches 127, not 255. The help text's "position the
    // bar at 100%" to "see everything in a bright light" overpromises, and matching that
    // overpromise is the point - a client that honoured it would be brighter than the original.
    inline constexpr float SCALE = 127.f;

    // What the ambience is tinted towards. Both are the client's own QColor literals, picked by
    // the same sea-floor test that decides `underground` elsewhere: outdoor ambience reads as
    // moonlight, and a cave's stays neutral so torchlight keeps its own colour.
    inline constexpr Color TINT_SURFACE{ 200, 200, 255 };
    inline constexpr Color TINT_UNDERGROUND{ 255, 255, 255 };

    // How much light the Clouds & Indoor slider may take away at 100%: half of it. The client
    // stores that option inverted - lightAttenuationCloudsIndoor = 1 - 0.005 * percent - so its
    // float is the share a shaded tile KEEPS and 1 means the option is off, which is why the
    // slider tags its 0% end "(off)". Reading the shipped 0.75 as "75%" gets both the default
    // and the slope wrong; it is 50%.
    inline constexpr float CLOUDS_MAX_ATTENUATION = .5f;

    // The 0..1 option as the byte the client actually keeps. Truncation, not rounding: the
    // client's `cvttss2si` rounds towards zero, so 25% is 31 rather than 32.
    inline uint8_t level(const float option)
    {
        return static_cast<uint8_t>(std::clamp(option, 0.f, 1.f) * SCALE);
    }

    // What a tile keeps of its light at a given Clouds & Indoor setting - the client's stored
    // float, rebuilt from the 0..1 the options module hands over.
    inline float keptUnderAttenuation(const float attenuation)
    {
        return 1.f - CLOUDS_MAX_ATTENUATION * std::clamp(attenuation, 0.f, 1.f);
    }

    // A roofed tile keeps the square of that. The client multiplies the clouds float by the
    // indoor one and both are fed from this single slider, so the option compounds with itself.
    inline float indoorFactor(const float attenuation)
    {
        const float kept = keptUnderAttenuation(attenuation);
        return kept * kept;
    }

    // TLightMap's base colour. Per channel:
    //
    //     out = min(255, base + tint * ((255 - base) * ambient / 255) / 255)
    //
    // Integer arithmetic throughout, and both divisions truncate - kept that way because the
    // client's are integer divisions too, and rounding here would drift a unit of colour away
    // from it at most settings.
    //
    // Written as a lerp towards `tint` rather than as a floor, this explains itself: a channel
    // already at 255 has nothing left to lift, so the option fades out on its own as the day
    // brightens and costs nothing at noon. And nothing can push a channel past the tint, which
    // is why no slider position turns night into day.
    inline Color lift(const Color& base, const uint8_t ambient, const Color& tint)
    {
        const auto channel = [ambient](const int from, const int towards) {
            return std::min(255, from + towards * ((255 - from) * ambient / 255) / 255);
        };

        return { channel(base.r(), tint.r()), channel(base.g(), tint.g()), channel(base.b(), tint.b()) };
    }

    // One number for a colour, for the test that decides whether the light pass is worth
    // running at all. Max channel rather than a luma: the light map multiplies, so a tile is
    // still taking something away as long as any one channel is short of full, and a blue-
    // tinted ambience is exactly the case a luma would round away.
    inline uint8_t brightestChannel(const Color& color)
    {
        return std::max(std::max(color.r(), color.g()), color.b());
    }
}
