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

#include <array>
#include <atomic>
#include <chrono>
#include <cstdint>

/*
 * A frame profiler you can leave switched on.
 *
 * This is deliberately not the Stats/AUTO_STAT system next door. That one takes an arbitrary
 * string description, heap-allocates a Stat per call and locks a process-wide mutex to file it -
 * costs that are fine for a one-off investigation and are exactly why it ships compiled out. The
 * result was that answering "where does the frame go" meant hand-instrumenting the client and
 * rebuilding, once per question.
 *
 * So the trade here is the opposite one: a CLOSED set of zones, known at compile time, indexed by
 * an enum instead of hashed by name. That buys an accumulator that is a plain array slot in
 * thread-local storage - no allocation, no locking, no string work on the sampled path - which in
 * turn is what makes it safe to run for a whole play session rather than a ten-second capture.
 *
 * Cost when disabled: one relaxed atomic load and a not-taken branch per zone.
 * Cost when enabled: two clock reads and one add per zone, roughly 40-50 ns on Apple silicon.
 *
 * Threading: each thread accumulates into its own block and only ever writes its own, so the
 * counters need no atomic read-modify-write. The reporter sums every block from another thread,
 * which is the one genuine race - hence relaxed atomic load/store rather than plain integers.
 * Numbers may be a frame stale; nothing here is used for control flow.
 */

enum class ProfileZone : uint8_t
{
    // --- producer thread ---------------------------------------------------------------
    MapPreLoad,
    UpdateVisibleTiles,
    DrawFloor,
    DrawLights,
    DrawCreatureInfo,
    UITraversal,
    PoolRelease,
    PoolCompile,

    // --- render thread -----------------------------------------------------------------
    FrameDraw,
    FrameAssemble,
    BackendRender,
    BackendEncode,
    GpuPresent,
    Present,
    MainPoll,

    Count
};

class Profiler
{
public:
    static constexpr size_t ZONE_COUNT = static_cast<size_t>(ProfileZone::Count);

    // Checked before any clock is read, so a disabled profiler costs a load and a branch.
    bool isEnabled() const { return m_enabled.load(std::memory_order_relaxed); }

    // Safe to call from Lua at any time. Enabling always clears first, so a capture never
    // carries totals from before it was asked for.
    void setEnabled(bool enabled);

    void setReportInterval(uint32_t ms) { m_reportIntervalMs = ms; }
    uint32_t getReportInterval() const { return m_reportIntervalMs; }

    void reset();

    // One rendered frame. Everything is reported per-frame as well as in total, because a total
    // says nothing without knowing how many frames it was spread over.
    void countFrame() { if (isEnabled()) m_frames.fetch_add(1, std::memory_order_relaxed); }

    // Emits a report if the interval has elapsed. Call once per frame from the render thread;
    // it returns immediately when disabled or when the interval has not passed.
    void poll();

    // Emits a report now, whatever the interval says.
    void report();

    void addSample(ProfileZone zone, uint64_t nanos);

private:
    struct Accum
    {
        std::atomic<uint64_t> nanos{ 0 };
        std::atomic<uint64_t> calls{ 0 };
    };

    struct ThreadBlock
    {
        std::array<Accum, ZONE_COUNT> zones{};
    };

    ThreadBlock* threadBlock();

    std::atomic_bool m_enabled{ false };
    std::atomic<uint64_t> m_frames{ 0 };
    uint32_t m_reportIntervalMs{ 5000 };
    int64_t m_lastReportMs{ 0 };
    int64_t m_captureStartMs{ 0 };
};

extern Profiler g_profiler;

// RAII zone. Reads no clock and touches nothing when the profiler is off.
class ProfileGuard
{
public:
    explicit ProfileGuard(const ProfileZone zone) : m_zone(zone), m_active(g_profiler.isEnabled())
    {
        if (m_active)
            m_start = std::chrono::steady_clock::now();
    }

    ~ProfileGuard()
    {
        if (!m_active)
            return;

        const auto elapsed = std::chrono::steady_clock::now() - m_start;
        g_profiler.addSample(m_zone, static_cast<uint64_t>(
            std::chrono::duration_cast<std::chrono::nanoseconds>(elapsed).count()));
    }

    ProfileGuard(const ProfileGuard&) = delete;
    ProfileGuard& operator=(const ProfileGuard&) = delete;

private:
    ProfileZone m_zone;
    bool m_active;
    std::chrono::steady_clock::time_point m_start;
};

#define OTC_PROFILE_CAT_INNER(a, b) a##b
#define OTC_PROFILE_CAT(a, b) OTC_PROFILE_CAT_INNER(a, b)
#define PROFILE_ZONE(zone) ProfileGuard OTC_PROFILE_CAT(_profileGuard_, __LINE__)(ProfileZone::zone)
