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

#include "image.h"

#include "apngloader.h"
#include "framework/core/filestream.h"
#include "framework/core/resourcemanager.h"

#include <algorithm>
#include <atomic>
#include <limits>
#include <map>
#include <mutex>

using namespace qrcodegen;

namespace
{
    // RAM diagnostics (see header): total pixel bytes of all live Images in the process.
    std::atomic<size_t> g_imageLiveCount{ 0 };
    std::atomic<size_t> g_imageLiveBytes{ 0 };

    // Register of disk loads since the last [mem] dump - points to the module grinding the disk.
    std::mutex g_imageLoadStatsMutex;
    std::map<std::string, std::pair<size_t, size_t>> g_imageLoadStats; // prefix -> {count, bytes}

    // Prefix of the first 3 path segments: "/images/game/wheel/..." -> "/images/game/wheel".
    std::string pathPrefix(const std::string& path)
    {
        size_t pos = 0;
        for (int i = 0; i < 4 && pos != std::string::npos; ++i)
            pos = path.find('/', pos + 1);
        return pos == std::string::npos ? path : path.substr(0, pos);
    }
}

void Image::adjustLiveBytes(const ptrdiff_t delta)
{
    if (delta >= 0)
        g_imageLiveBytes.fetch_add(static_cast<size_t>(delta), std::memory_order_relaxed);
    else
        g_imageLiveBytes.fetch_sub(static_cast<size_t>(-delta), std::memory_order_relaxed);
}

size_t Image::getLiveCount() { return g_imageLiveCount.load(std::memory_order_relaxed); }
size_t Image::getLiveBytes() { return g_imageLiveBytes.load(std::memory_order_relaxed); }

std::string Image::drainLoadStats()
{
    std::map<std::string, std::pair<size_t, size_t>> stats;
    {
        std::scoped_lock lock(g_imageLoadStatsMutex);
        stats.swap(g_imageLoadStats);
    }

    if (stats.empty())
        return "none";

    std::vector<std::pair<std::string, std::pair<size_t, size_t>>> sorted(stats.begin(), stats.end());
    std::ranges::sort(sorted, [](const auto& a, const auto& b) { return a.second.second > b.second.second; });

    std::string out;
    for (size_t i = 0; i < sorted.size() && i < 6; ++i) {
        if (!out.empty())
            out += ", ";
        out += fmt::format("{} x{} (~{} KB)", sorted[i].first, sorted[i].second.first, sorted[i].second.second / 1024);
    }
    return out;
}

Image::Image(const Size& size, const int bpp, const uint8_t* pixels) : m_size(size), m_bpp(bpp)
{
    m_pixels.resize(size.area() * bpp, 0);
    if (pixels)
        memcpy(&m_pixels[0], pixels, m_pixels.size());

    g_imageLiveCount.fetch_add(1, std::memory_order_relaxed);
    adjustLiveBytes(static_cast<ptrdiff_t>(m_pixels.size()));
}

Image::~Image()
{
    g_imageLiveCount.fetch_sub(1, std::memory_order_relaxed);
    adjustLiveBytes(-static_cast<ptrdiff_t>(m_pixels.size()));
}

ImagePtr Image::load(const std::string& file)
{
    const auto& path = g_resources.guessFilePath(file, "png");
    try {
        const auto& image = loadPNG(path);

        if (image) {
            std::scoped_lock lock(g_imageLoadStatsMutex);
            auto& entry = g_imageLoadStats[pathPrefix(path)];
            ++entry.first;
            entry.second += image->getPixels().size();
        }

        return image;
    } catch (const stdext::exception& e) {
        g_logger.error("unable to load image '{}': {}", path, e.what());
    }
    return nullptr;
}

ImagePtr Image::loadPNG(const char* data, const size_t size)
{
    std::stringstream fin(std::string{ data, size });
    ImagePtr image;
    if (apng_data apng; load_apng(fin, &apng) == 0) {
        image = std::make_shared<Image>(Size(apng.width, apng.height), apng.bpp, apng.pdata);
        if (apng.num_frames > 1 && apng.frames_delay) {
            const size_t frameSize = static_cast<size_t>(apng.width) * apng.height * apng.bpp;
            const uint32_t frames = std::min(apng.num_frames, apng.last_frame);
            for (uint32_t i = 0; i < frames; ++i) {
                // Create a new Image for every frame to avoid circular reference (image -> m_animation -> image)
                ImagePtr frameImage = std::make_shared<Image>(Size(apng.width, apng.height), apng.bpp, apng.pdata + (static_cast<size_t>(i) * frameSize));
                image->addAnimationFrame(frameImage, apng.frames_delay[i]);
            }
        }
        free_apng(&apng);
    }

    if (!image)
        return nullptr;

    int cntTransparentPixel = 0;
    for (const auto& pixel : image->getPixels()) {
        if (pixel == 0 && ++cntTransparentPixel == 4) {
            image->setTransparentPixel(true);
            break;
        }
    }

    return image;
}

ImagePtr Image::loadPNG(const std::string& file)
{
    std::stringstream fin;
    g_resources.readFileStream(file, fin);

    const std::string buffer{ fin.str() };

    return loadPNG(buffer.data(), buffer.size());
}

void Image::savePNG(const std::string& fileName)
{
    const auto& fin = g_resources.createFile(fileName);
    if (!fin)
        throw Exception("failed to open file '{}' for write", fileName);

    fin->cache();
    std::stringstream data;
    save_png(data, m_size.width(), m_size.height(), 4, getPixelData());
    fin->write(data.str().c_str(), data.str().length());
    fin->flush();
    fin->close();
}

void Image::overwriteMask(const Color& maskedColor, const Color& insideColor, const Color& outsideColor)
{
    assert(m_bpp == 4);

    // Outfit masks normally contain the four exact Tibia palette colors.
    // Texture upscalers (for example xBRZ) interpolate their edge pixels,
    // though, so an exact comparison drops those pixels and corrupts the
    // outfit colors. Classify interpolated pixels by the nearest mask color
    // while ignoring transparent and neutral (black/grey/white) pixels.
    static constexpr uint8_t MASK_CHROMA_TOLERANCE = 8;
    const Color maskPalette[] = { Color::red, Color::green, Color::blue, Color::yellow };

    for (int p = 0; p < getPixelCount(); ++p) {
        uint8_t& r = m_pixels[p * 4 + 0];
        uint8_t& g = m_pixels[p * 4 + 1];
        uint8_t& b = m_pixels[p * 4 + 2];
        uint8_t& a = m_pixels[p * 4 + 3];

        const Color pixelColor(r, g, b, a);
        bool matchesMask = pixelColor == maskedColor;

        if (!matchesMask && a != 0) {
            const uint8_t minChannel = std::min({ r, g, b });
            const uint8_t maxChannel = std::max({ r, g, b });

            if (maxChannel - minChannel >= MASK_CHROMA_TOLERANCE) {
                int nearestDistance = std::numeric_limits<int>::max();
                Color nearestMask = Color::alpha;

                for (const auto& candidate : maskPalette) {
                    const int dr = static_cast<int>(r) - candidate.r();
                    const int dg = static_cast<int>(g) - candidate.g();
                    const int db = static_cast<int>(b) - candidate.b();
                    const int distance = dr * dr + dg * dg + db * db;
                    if (distance < nearestDistance) {
                        nearestDistance = distance;
                        nearestMask = candidate;
                    }
                }

                matchesMask = nearestMask == maskedColor;
            }
        }

        const Color writeColor = matchesMask ? insideColor : outsideColor;

        r = writeColor.r();
        g = writeColor.g();
        b = writeColor.b();
        a = writeColor.a();
    }
}

void Image::overwrite(const Color& color)
{
    assert(m_bpp == 4);

    for (int p = 0; p < getPixelCount(); ++p) {
        uint8_t& r = m_pixels[p * 4 + 0];
        uint8_t& g = m_pixels[p * 4 + 1];
        uint8_t& b = m_pixels[p * 4 + 2];
        uint8_t& a = m_pixels[p * 4 + 3];

        Color pixelColor(r, g, b, a);
        Color writeColor = (pixelColor == Color::alpha) ? Color::alpha : color;

        r = writeColor.r();
        g = writeColor.g();
        b = writeColor.b();
        a = writeColor.a();
    }
}

void Image::blit(const Point& dest, const ImagePtr& other)
{
    assert(m_bpp == 4);

    if (!other)
        return;

    const uint8_t* otherPixels = other->getPixelData();
    for (int p = 0; p < other->getPixelCount(); ++p) {
        const int x = p % other->getWidth();
        const int y = p / other->getWidth();
        const int pos = ((dest.y + y) * m_size.width() + (dest.x + x)) * 4;

        if (otherPixels[p * 4 + 3] != 0) {
            m_pixels[pos + 0] = otherPixels[p * 4 + 0];
            m_pixels[pos + 1] = otherPixels[p * 4 + 1];
            m_pixels[pos + 2] = otherPixels[p * 4 + 2];
            m_pixels[pos + 3] = otherPixels[p * 4 + 3];
        }
    }
}

void Image::paste(const ImagePtr& other)
{
    assert(m_bpp == 4);

    if (!other)
        return;

    const uint8_t* otherPixels = other->getPixelData();
    for (int p = 0; p < other->getPixelCount(); ++p) {
        const int x = p % other->getWidth();
        const int y = p / other->getWidth();
        const int pos = (y * m_size.width() + x) * 4;

        m_pixels[pos + 0] = otherPixels[p * 4 + 0];
        m_pixels[pos + 1] = otherPixels[p * 4 + 1];
        m_pixels[pos + 2] = otherPixels[p * 4 + 2];
        m_pixels[pos + 3] = otherPixels[p * 4 + 3];
    }
}

bool Image::nextMipmap()
{
    assert(m_bpp == 4);

    const int iw = m_size.width();
    const int ih = m_size.height();
    if (iw == 1 && ih == 1 || m_pixels.empty())
        return false;

    const int ow = iw > 1 ? iw / 2 : 1;
    const int oh = ih > 1 ? ih / 2 : 1;

    std::vector<uint8_t > pixels(ow * oh * 4, 0xFF);

    //FIXME: calculate mipmaps for 8x1, 4x1, 2x1 ...
    if (iw != 1 && ih != 1) {
        for (int x = 0; x < ow; ++x) {
            for (int y = 0; y < oh; ++y) {
                uint8_t* inPixel[4];
                inPixel[0] = &m_pixels[((y * 2) * iw + (x * 2)) * 4];
                inPixel[1] = &m_pixels[((y * 2) * iw + (x * 2) + 1) * 4];
                inPixel[2] = &m_pixels[((y * 2 + 1) * iw + (x * 2)) * 4];
                inPixel[3] = &m_pixels[((y * 2 + 1) * iw + (x * 2) + 1) * 4];
                uint8_t* outPixel = &pixels[(y * ow + x) * 4];

                int pixelsSum[4];
                for (int& i : pixelsSum)
                    i = 0;

                int usedPixels = 0;
                for (auto& j : inPixel) {
                    // ignore colors of complete alpha pixels
                    if (j[3] < 16)
                        continue;

                    for (int i = 0; i < 4; ++i)
                        pixelsSum[i] += j[i];

                    ++usedPixels;
                }

                // try to guess the alpha pixel more accurately
                for (int i = 0; i < 4; ++i) {
                    if (usedPixels > 0)
                        outPixel[i] = pixelsSum[i] / usedPixels;
                    else
                        outPixel[i] = 0;
                }
                outPixel[3] = pixelsSum[3] / 4;
            }
        }
    }

    adjustLiveBytes(static_cast<ptrdiff_t>(pixels.size()) - static_cast<ptrdiff_t>(m_pixels.size()));
    m_pixels = pixels;
    m_size = { ow, oh };
    return true;
}

void Image::flipVertically()
{
    for (int line = 0, h = m_size.height(), w = m_size.width(); line != h / 2; ++line) {
        std::swap_ranges(
            m_pixels.begin() + 4 * w * line,
            m_pixels.begin() + 4 * w * (line + 1),
            m_pixels.begin() + 4 * w * (h - line - 1));
    }
}

void Image::setOpacity(const uint8_t v) {
    for (size_t i = 3, s = m_pixels.size(); i < s; i += 4)
        m_pixels[i] = v;
}

void Image::reverseChannels()
{
    uint8_t* pixelData = m_pixels.data();
    for (uint8_t* itr = pixelData; itr < pixelData + m_pixels.size(); itr += m_bpp) {
        std::swap(*(itr + 0), *(itr + 2));
    }
}

ImagePtr Image::fromQRCode(const std::string& code, const int border)
{
    try {
        const QrCode qrCode = QrCode::encodeText(code.c_str(), QrCode::Ecc::MEDIUM);

        const auto size = qrCode.getSize();
        ImagePtr image(new Image(Size(size + border * 2, size + border * 2)));

        for (int x = 0; x < size + border * 2; ++x) {
            for (int y = 0; y < size + border * 2; ++y) {
                image->setPixel(x, y, qrCode.getModule(x - border, y - border) ? Color::black : Color::white);
            }
        }

        return image;
    } catch (const std::exception& e) {
        g_logger.error("Failed to encode qr-code: '{}': {}", code, e.what());
    }

    return {};
}
