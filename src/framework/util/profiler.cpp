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

#include "profiler.h"

#include <framework/core/clock.h>
#include <framework/core/logger.h>

#include <algorithm>
#include <deque>
#include <mutex>
#include <vector>

Profiler g_profiler;

namespace
{
    // Zone names, in enum order. A static_assert below keeps this honest: adding a zone without
    // naming it fails the build rather than printing a blank row.
    constexpr std::array<const char*, Profiler::ZONE_COUNT> ZONE_NAMES{
        "map: preLoad",
        "map: updateVisibleTiles",
        "map: drawFloor",
        "map: drawLights",
        "map: drawCreatureInfo",
        "ui:  traversal",
        "pool: release",
        "pool: compile",
        "frame: draw",
        "frame: assemble",
        "frame: backend render",
        "frame:   encode",
        "frame:   gpu present/wait",
        "frame: swapBuffers",
        "main: poll",
    };
    static_assert(ZONE_NAMES.size() == Profiler::ZONE_COUNT, "every ProfileZone needs a name");

    // Blocks are handed out per thread and never reclaimed. The threads that matter here are the
    // render thread and a fixed worker pool, all of which live as long as the process, so a free
    // list would add a lifetime problem - the reporter walks this from another thread - to buy
    // back a few hundred bytes.
    std::mutex g_blocksMutex;
    std::deque<void*> g_blocks;
}

void Profiler::setEnabled(const bool enabled)
{
    if (enabled == m_enabled.load(std::memory_order_relaxed))
        return;

    if (enabled) {
        reset();
        m_captureStartMs = g_clock.millis();
        m_lastReportMs = m_captureStartMs;
    }

    m_enabled.store(enabled, std::memory_order_relaxed);
    g_logger.info("[profiler] {}", enabled ? "on" : "off");

    if (!enabled)
        report();
}

void Profiler::reset()
{
    std::scoped_lock lock(g_blocksMutex);
    for (void* raw : g_blocks) {
        auto* block = static_cast<ThreadBlock*>(raw);
        for (auto& zone : block->zones) {
            zone.nanos.store(0, std::memory_order_relaxed);
            zone.calls.store(0, std::memory_order_relaxed);
        }
    }
    m_frames.store(0, std::memory_order_relaxed);
}

Profiler::ThreadBlock* Profiler::threadBlock()
{
    // One allocation per thread, on that thread's first sample. Registration takes the lock;
    // sampling never does.
    thread_local ThreadBlock* block = [] {
        auto* created = new ThreadBlock();
        std::scoped_lock lock(g_blocksMutex);
        g_blocks.push_back(created);
        return created;
    }();

    return block;
}

void Profiler::addSample(const ProfileZone zone, const uint64_t nanos)
{
    auto& accum = threadBlock()->zones[static_cast<size_t>(zone)];

    // Only this thread writes these, so a read-modify-write would be wasted synchronisation;
    // the atomics are here so that the reporter's cross-thread read is defined, not to make the
    // increment itself safe against a competing writer.
    accum.nanos.store(accum.nanos.load(std::memory_order_relaxed) + nanos, std::memory_order_relaxed);
    accum.calls.store(accum.calls.load(std::memory_order_relaxed) + 1, std::memory_order_relaxed);
}

void Profiler::poll()
{
    if (!isEnabled())
        return;

    const int64_t now = g_clock.millis();
    if (now - m_lastReportMs < static_cast<int64_t>(m_reportIntervalMs))
        return;

    m_lastReportMs = now;
    report();
}

void Profiler::report()
{
    struct Row
    {
        const char* name;
        uint64_t nanos;
        uint64_t calls;
    };

    std::array<Row, ZONE_COUNT> rows{};
    for (size_t i = 0; i < ZONE_COUNT; ++i)
        rows[i] = { ZONE_NAMES[i], 0, 0 };

    {
        std::scoped_lock lock(g_blocksMutex);
        for (void* raw : g_blocks) {
            auto* block = static_cast<ThreadBlock*>(raw);
            for (size_t i = 0; i < ZONE_COUNT; ++i) {
                rows[i].nanos += block->zones[i].nanos.load(std::memory_order_relaxed);
                rows[i].calls += block->zones[i].calls.load(std::memory_order_relaxed);
            }
        }
    }

    const uint64_t frames = std::max<uint64_t>(m_frames.load(std::memory_order_relaxed), 1);
    const int64_t elapsedMs = std::max<int64_t>(g_clock.millis() - m_captureStartMs, 1);

    std::vector<Row> sorted(rows.begin(), rows.end());
    std::ranges::sort(sorted, [](const Row& a, const Row& b) { return a.nanos > b.nanos; });

    g_logger.info("[profiler] {} frames over {} ms ({:.1f} fps)",
                  frames, elapsedMs, frames * 1000.0 / static_cast<double>(elapsedMs));
    g_logger.info("[profiler] {:<26} {:>10} {:>12} {:>10}", "zone", "ms/frame", "calls/frame", "total ms");

    for (const auto& row : sorted) {
        if (row.calls == 0)
            continue;

        g_logger.info("[profiler] {:<26} {:>10.4f} {:>12.1f} {:>10.1f}",
                      row.name,
                      row.nanos / 1e6 / static_cast<double>(frames),
                      row.calls / static_cast<double>(frames),
                      row.nanos / 1e6);
    }

    // Each capture window stands alone; totals that span a scene change describe neither scene.
    reset();
    m_captureStartMs = g_clock.millis();
}
