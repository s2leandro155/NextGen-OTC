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

#include "uiprogressarc.h"

#include "framework/graphics/drawpoolmanager.h"
#include "framework/otml/otmlnode.h"

#include <cmath>

namespace
{
    constexpr float ARC_PI = 3.14159265358979323846f;
    constexpr float ARC_DEG2RAD = ARC_PI / 180.f;
    constexpr float ARC_RAD2DEG = 180.f / ARC_PI;

    Point toPoint(const float x, const float y)
    {
        return { static_cast<int>(std::lround(x)), static_cast<int>(std::lround(y)) };
    }
}

void UIProgressArc::setPercent(float percent)
{
    percent = std::clamp<float>(percent, 0.f, 100.f);
    if (m_percent == percent)
        return;

    m_percent = percent;
    repaint();
}

void UIProgressArc::drawRingSegment(const float fromDeg, const float toDeg, const float rin, const float rout, const float cx, const float cy, const Color& color)
{
    const float span = toDeg - fromDeg;
    if (span < 0.05f || rout <= 0.5f)
        return;

    const int steps = std::clamp<int>(static_cast<int>(std::ceil(span / 3.f)), 1, 180);
    const float step = span / steps;

    float prevOx = 0, prevOy = 0, prevIx = 0, prevIy = 0;
    for (int i = 0; i <= steps; ++i) {
        const float rad = (fromDeg + i * step) * ARC_DEG2RAD;
        const float dx = std::sin(rad);
        const float dy = -std::cos(rad);
        const float ox = cx + dx * rout, oy = cy + dy * rout;
        const float ix = cx + dx * rin, iy = cy + dy * rin;

        if (i > 0) {
            g_drawPool.addFilledTriangle(toPoint(prevOx, prevOy), toPoint(prevIx, prevIy), toPoint(ox, oy), color);
            if (rin > 0.5f)
                g_drawPool.addFilledTriangle(toPoint(prevIx, prevIy), toPoint(ix, iy), toPoint(ox, oy), color);
        }

        prevOx = ox; prevOy = oy; prevIx = ix; prevIy = iy;
    }
}

void UIProgressArc::drawSelf(const DrawPoolType drawPane)
{
    if (drawPane != DrawPoolType::FOREGROUND)
        return;

    const auto& rect = getPaddingRect();
    const float w = rect.width();
    const float h = rect.height();

    if (w >= 1.f && h >= 1.f) {
        const float span = m_fullSpan;
        const float a0 = m_startAngle;
        const float a1 = a0 + span;

        // radius fitting: the bbox of the ring segment (outer arc + inner endpoints)
        // must fill the padding-rect; inner depends on thickness in px, hence the iteration
        float radius = std::max<float>(std::min(w, h), 1.f);
        float minx = -1.f, miny = -1.f, maxx = 1.f, maxy = 1.f;
        for (int it = 0; it < 4; ++it) {
            const float rout = std::max<float>(radius - m_radialInset, 1.f);
            const float rin = std::max<float>(rout - m_thickness, 0.f);

            // Always fit and align arcs against their common outer radius.
            // Using rout here made the fitting loop compensate m_radialInset by
            // enlarging the radius, which put inset layers (Harmony/Mana Shield)
            // back on top of the health or mana arc.
            const float fo = 1.f;
            const float fi = rin / radius;

            minx = miny = 1e9f;
            maxx = maxy = -1e9f;
            const auto add = [&](const float deg, const float f) {
                const float rad = deg * ARC_DEG2RAD;
                const float x = std::sin(rad) * f;
                const float y = -std::cos(rad) * f;
                minx = std::min(minx, x); maxx = std::max(maxx, x);
                miny = std::min(miny, y); maxy = std::max(maxy, y);
            };
            add(a0, fo); add(a1, fo);
            add(a0, fi); add(a1, fi);
            for (int k = static_cast<int>(std::ceil(a0 / 90.f)); k * 90.f <= a1; ++k)
                add(k * 90.f, fo);

            const float bw = std::max((maxx - minx) * radius, 1.f);
            const float bh = std::max((maxy - miny) * radius, 1.f);
            radius *= std::min(w / bw, h / bh);
        }

        const float bw = (maxx - minx) * radius;
        const float bh = (maxy - miny) * radius;
        const float cx = rect.left() - minx * radius + (w - bw) / 2.f;
        const float cy = rect.top() - miny * radius + (h - bh) / 2.f;

        const float rout = std::max<float>(radius - m_radialInset, 1.f);
        const float rin = std::max<float>(rout - m_thickness, 0.f);

        if (m_slotCount > 0) {
            const float slotSpan = span / m_slotCount;
            const float gap = std::min(2.f, slotSpan * 0.15f);
            for (int i = 0; i < m_slotCount; ++i) {
                const bool filled = m_fillFromEnd ? (i >= m_slotCount - m_filledSlots) : (i < m_filledSlots);
                if (!filled && !m_emptyTrack)
                    continue;
                drawRingSegment(a0 + i * slotSpan + gap / 2.f, a0 + (i + 1) * slotSpan - gap / 2.f,
                                rin, rout, cx, cy, filled ? m_fillColor : m_trackColor);
            }
        } else {
            const float fillSpan = span * (m_percent / 100.f);
            const float fa0 = m_fillFromEnd ? a1 - fillSpan : a0;
            const float fa1 = m_fillFromEnd ? a1 : a0 + fillSpan;

            if (m_emptyTrack) {
                drawRingSegment(a0, fa0, rin, rout, cx, cy, m_trackColor);
                drawRingSegment(fa1, a1, rin, rout, cx, cy, m_trackColor);
            }
            drawRingSegment(fa0, fa1, rin, rout, cx, cy, m_fillColor);
        }

        const float borderW = std::min<float>(m_arcBorderWidth, rout - rin);
        if (m_borderEnabled && borderW > 0.f) {
            drawRingSegment(a0, a1, rout - borderW, rout, cx, cy, m_arcBorderColor);
            if (rin > 0.5f)
                drawRingSegment(a0, a1, rin, rin + borderW, cx, cy, m_arcBorderColor);
            if (span < 359.9f) {
                const float capSpan = borderW / std::max((rin + rout) / 2.f, 1.f) * ARC_RAD2DEG;
                drawRingSegment(a0, a0 + capSpan, rin, rout, cx, cy, m_arcBorderColor);
                drawRingSegment(a1 - capSpan, a1, rin, rout, cx, cy, m_arcBorderColor);
            }
        }
    }

    drawImage(m_rect);
    drawBorder(m_rect);
    drawIcon(m_rect);
    drawText(m_rect);
}

void UIProgressArc::onStyleApply(const std::string_view styleName, const OTMLNodePtr& styleNode)
{
    UIWidget::onStyleApply(styleName, styleNode);

    for (const auto& node : styleNode->children()) {
        if (node->tag() == "percent")
            setPercent(node->value<float>());
        else if (node->tag() == "arc-layout")
            setArcLayoutSide(node->value());
        else if (node->tag() == "start-angle")
            setStartAngle(node->value<float>());
        else if (node->tag() == "total-span")
            setFullSpan(node->value<float>());
        else if (node->tag() == "ring-thickness")
            setThickness(node->value<int>());
        else if (node->tag() == "radial-inset")
            setRadialInset(node->value<int>());
        else if (node->tag() == "empty-track")
            setEmptyTrack(node->value<bool>());
        else if (node->tag() == "track-color")
            setTrackColor(node->value<Color>());
        else if (node->tag() == "fill-color")
            setFillColor(node->value<Color>());
        else if (node->tag() == "fill-from-end")
            setFillFromEnd(node->value<bool>());
        else if (node->tag() == "arc-slot-count")
            setArcSlotCount(node->value<int>());
        else if (node->tag() == "arc-border")
            setArcBorder(node->value<bool>());
        else if (node->tag() == "arc-border-color")
            setArcBorderColor(node->value<Color>());
        else if (node->tag() == "arc-border-width")
            setArcBorderWidth(node->value<int>());
        // arc-border-antialias / arc-cut-antialias etc. deliberately ignored (no AA in drawpool)
    }
}
