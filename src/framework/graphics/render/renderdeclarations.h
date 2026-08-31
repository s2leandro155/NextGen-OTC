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

#include <framework/graphics/declarations.h>

/*
 * The renderer boundary vocabulary.
 *
 * Above this boundary the client decides WHAT to draw; below it a backend decides HOW to
 * encode it. Nothing declared here names a graphics API, and this header pulls in none -
 * which is the whole point: game, UI and map code can describe a frame completely without
 * a GL, Vulkan or Metal type ever entering a translation unit.
 */

 // ---------------------------------------------------------------------------------------
 // Logical resource handles
 //
 // Shared code never holds a GL texture id, a VkImage or an id<MTLTexture>; it holds one of
 // these. The active backend owns the handle -> native object mapping, which is what lets a
 // resource be recreated after device loss, destroyed only once every in-flight frame that
 // referenced it has retired, and labelled centrally for GPU captures.
 //
 // Note the zero conventions differ per type on purpose; they are not interchangeable.
 // ---------------------------------------------------------------------------------------

struct TextureHandle
{
    // 0 = no texture. A packet with no texture draws untextured (solid colour), which is
    // exactly how the GL path already behaves when Painter has no bound texture.
    uint32_t id{ 0 };

    [[nodiscard]] constexpr bool isValid() const { return id != 0; }
    constexpr bool operator==(const TextureHandle&) const = default;
};

struct RenderTargetHandle
{
    // 0 = the backbuffer, which is a perfectly ORDINARY target. Unlike the other two handle
    // types, zero here does not mean "none" - there is no such thing as a pass with no target.
    static constexpr uint32_t BACKBUFFER = 0;

    uint32_t id{ BACKBUFFER };

    [[nodiscard]] constexpr bool isBackbuffer() const { return id == BACKBUFFER; }
    constexpr bool operator==(const RenderTargetHandle&) const = default;
};

struct MaterialHandle
{
    // 0 = the default built-in: Textured when the packet has a texture, SolidColor when it
    // does not. This mirrors Painter::drawCoords picking its program from `textured`.
    uint16_t id{ 0 };

    [[nodiscard]] constexpr bool isDefault() const { return id == 0; }
    constexpr bool operator==(const MaterialHandle&) const = default;
};

template<> struct std::hash<TextureHandle>
{ size_t operator()(const TextureHandle h) const noexcept { return std::hash<uint32_t>{}(h.id); } };
template<> struct std::hash<RenderTargetHandle>
{ size_t operator()(const RenderTargetHandle h) const noexcept { return std::hash<uint32_t>{}(h.id); } };
template<> struct std::hash<MaterialHandle>
{ size_t operator()(const MaterialHandle h) const noexcept { return std::hash<uint16_t>{}(h.id); } };

// ---------------------------------------------------------------------------------------
// Blend state
//
// This is the surveyed GL blend table reproduced BY FORMULA, not by name. Two of the six
// are misleadingly named at the producer layer and are renamed here deliberately, because a
// backend author reading "Add" and implementing classic additive blending would silently
// break every particle effect in the game:
//
//   CompositionMode::ADD   is (1-srcColor, 1-srcColor)  -> AddWeird
//   CompositionMode::LIGHT is (0, srcColor)             -> LightModulate
//
// CompositionMode remains the producer-facing vocabulary (it is what Lua, the .otps particle
// parser and the client draw code speak). BlendMode is the renderer-facing one. They are
// 1:1 today; keeping them distinct is what allows the producer names to stay stable while
// the renderer names describe what the GPU actually does.
// ---------------------------------------------------------------------------------------

enum class BlendMode : uint8_t
{
    Normal,        // rgb: SRC_ALPHA, 1-SRC_ALPHA | alpha: ONE, ONE  -- alpha ACCUMULATES
    Multiply,      // DST_COLOR, 1-SRC_ALPHA
    AddWeird,      // 1-SRC_COLOR, 1-SRC_COLOR  -- NOT classic additive. Particles depend on it.
    Replace,       // ONE, ZERO
    DestBlend,     // 1-DST_ALPHA, DST_ALPHA
    LightModulate, // ZERO, SRC_COLOR
};

[[nodiscard]] constexpr BlendMode blendModeOf(const CompositionMode mode)
{
    switch (mode) {
        case CompositionMode::NORMAL:               return BlendMode::Normal;
        case CompositionMode::MULTIPLY:             return BlendMode::Multiply;
        case CompositionMode::ADD:                  return BlendMode::AddWeird;
        case CompositionMode::REPLACE:              return BlendMode::Replace;
        case CompositionMode::DESTINATION_BLENDING: return BlendMode::DestBlend;
        case CompositionMode::LIGHT:                return BlendMode::LightModulate;
    }
    return BlendMode::Normal;
}

// ---------------------------------------------------------------------------------------
// Pass load action
//
// Keep is not a nicety. Two load-bearing behaviours need it: a pool whose content hash did
// not change is re-composited WITHOUT re-rendering its target, and atlas layers accumulate
// across frames (autoClear=false). A clear-every-pass model would destroy both.
// ---------------------------------------------------------------------------------------

enum class LoadAction : uint8_t
{
    Clear, // clear the target to clearColor first
    Keep,  // preserve whatever the target already holds
};

// ---------------------------------------------------------------------------------------
// Materials
//
// Every shader in this client - built-in or module - shares one vertex stage and one
// fragment ABI, so a material is a FRAGMENT VARIANT, not an arbitrary pipeline.
// ---------------------------------------------------------------------------------------

enum class BuiltinMaterial : uint16_t
{
    Textured = 0,     // tex(Tex0) * u_Color
    SolidColor = 1,   // u_Color
    ReplaceColor = 2, // a > 0.01 ? u_Color : transparent  (marked/highlighted things)

    // GL's fourth built-in program is the line shader. It has no slot here on purpose: the
    // compiler triangulates UIGraph's lines into ordinary SolidColor quads, because Metal
    // has neither wide nor smoothed lines. Nothing may ever emit a "Line" material.

    FirstModule = 16, // registry-assigned from here up: Fog, Rain, Outline, ...
};

[[nodiscard]] constexpr MaterialHandle materialHandleOf(const BuiltinMaterial m)
{
    return MaterialHandle{ static_cast<uint16_t>(m) };
}

// ---------------------------------------------------------------------------------------
// Action idioms
//
// The GL path expresses seven things as opaque std::function callbacks. A backend that does
// not execute GL cannot run them, so each one is TAGGED at record time with what it means.
// The compiler switches on the tag rather than trying to infer intent from geometry - which
// is not a theoretical concern: inferring the map-hole punch from "untextured and alpha 0"
// was tried, and it cut holes through any UI widget that happened to be faded to zero.
//
// `Opaque` is the default on purpose. An untagged action reaching the compiler is reported as
// unsupported and poisons the program rather than being silently skipped, because a frame
// that quietly omits a draw is worse than one that refuses to be built.
// ---------------------------------------------------------------------------------------

enum class ActionIdiom : uint8_t
{
    Opaque = 0,          // unknown callback - the compiler cannot express it
    BlendOff,            // glDisable(GL_BLEND)
    BlendOn,             // glEnable(GL_BLEND)
    PoolTargetPrepare,   // preDraw's framebuffer prepare: metadata only, declared as rects
    MapShaderBind,       // MapView installs the map-shader composition hooks
    LineStrip,           // UIGraph line: the object also carries pre-triangulated geometry
    LightOverlay,        // LightView: pixel upload plus one multiply quad
};
