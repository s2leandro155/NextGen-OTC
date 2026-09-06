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

#include "mouse.h"

#include "framework/core/resourcemanager.h"
#include "framework/otml/otmldocument.h"
#include "framework/platform/platformwindow.h"

Mouse g_mouse;

void Mouse::init() {}

void Mouse::terminate()
{
    m_cursors.clear();
    m_cursorDefinitions.clear();
}

void Mouse::loadCursors(const std::string& filename)
{
    const auto& path = g_resources.guessFilePath(filename, "otml");
    try {
        const auto& doc = OTMLDocument::parse(path);
        const auto& cursorsNode = doc->at("Cursors");

        for (const auto& cursorNode : cursorsNode->children()) {
            addCursor(cursorNode->tag(),
                      stdext::resolve_path(cursorNode->valueAt("image"), cursorNode->source()),
                      cursorNode->valueAt<Point>("hot-spot"));
        }
        
        // Automatically set 'default' cursor as the main cursor (without pushing to stack)
        if (m_cursors.contains("default")) {
            const int defaultCursorId = m_cursors["default"];
            g_window.setMouseCursor(defaultCursorId);
        }

    } catch (stdext::exception& e) {
        g_logger.error("unable to load cursors file: {}", e.what());
    }
}


void Mouse::addCursor(const std::string& name, const std::string& file, const Point& hotSpot)
{
    m_cursorDefinitions[name] = { file, hotSpot };
    const int cursorId = g_window.loadMouseCursor(file, hotSpot, m_cursorDisplayScale);
    if (cursorId >= 0) {
        m_cursors[name] = cursorId;
    } else
        g_logger.error("unable to load cursor {}", name);
}

bool Mouse::pushCursor(const std::string& name)
{
    const auto it = m_cursors.find(name);
    if (it == m_cursors.end())
        return false;

    const int cursorId = it->second;
    m_cursorStack.push_back(cursorId);
    applyCurrentCursor();
    return true;
}

void Mouse::popCursor(const std::string& name)
{
    if (m_cursorStack.empty())
        return;

    if (name.empty() || !m_cursors.contains(name))
        m_cursorStack.pop_back();
    else {
        const int cursorId = m_cursors[name];
        int index = -1;
        for (uint32_t i = 0; i < m_cursorStack.size(); ++i) {
            if (m_cursorStack[i] == cursorId)
                index = i;
        }
        if (index >= 0)
            m_cursorStack.erase(m_cursorStack.begin() + index);
        else
            return;
    }

    applyCurrentCursor();
}

void Mouse::setUseNativeCursor(const bool useNative)
{
    if (m_useNativeCursor == useNative)
        return;

    m_useNativeCursor = useNative;
    applyCurrentCursor();
}

void Mouse::setCursorDisplayScale(const int scale)
{
    const int normalizedScale = scale > 1 ? 2 : 1;
    if (m_cursorDisplayScale == normalizedScale)
        return;

    m_cursorDisplayScale = normalizedScale;
    reloadCursors();
}

void Mouse::applyCurrentCursor()
{
    if (m_useNativeCursor) {
        g_window.restoreMouseCursor();
        return;
    }

    if (!m_cursorStack.empty())
        g_window.setMouseCursor(m_cursorStack.back());
    else if (m_cursors.contains("default"))
        g_window.setMouseCursor(m_cursors["default"]);
    else
        g_window.restoreMouseCursor();
}

void Mouse::reloadCursors()
{
    const auto definitions = m_cursorDefinitions;
    m_cursors.clear();
    m_cursorStack.clear();
    for (const auto& [name, definition] : definitions) {
        const int cursorId = g_window.loadMouseCursor(definition.file, definition.hotSpot, m_cursorDisplayScale);
        if (cursorId >= 0)
            m_cursors[name] = cursorId;
    }
    applyCurrentCursor();
}

bool Mouse::isCursorChanged()
{
    return !m_cursorStack.empty();
}

bool Mouse::isPressed(const Fw::MouseButton mouseButton)
{
    return g_window.isMouseButtonPressed(mouseButton);
}

int Mouse::getCursorId(const std::string& name)
{
    if (m_cursors.contains(name))
        return m_cursors[name];
    return -1;
}

void Mouse::checkStackSize()
{
    if (m_cursorStack.size() > 5) {
        g_logger.error("mouse cursor stack is too long");
        m_cursorStack.pop_front();
    }
}
