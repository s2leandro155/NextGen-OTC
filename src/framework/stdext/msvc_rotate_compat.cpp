#include <cstddef>
#include <utility>

// Libraries produced by newer MSVC STL releases call this byte-range helper.
// Some installed MSVC runtime combinations do not export it, so provide the
// equivalent operation locally to keep static vcpkg libraries compatible.
#if _MSC_VER < 1950
extern "C" __declspec(noalias) void __stdcall __std_rotate(void* first, void* const middle, void* last) noexcept
{
    auto* begin = static_cast<unsigned char*>(first);
    auto* mid = static_cast<unsigned char*>(middle);
    auto* end = static_cast<unsigned char*>(last);

    if (begin == mid || mid == end)
        return;

    auto reverse = [](unsigned char* left, unsigned char* right) noexcept {
        while (left < right) {
            --right;
            if (left >= right)
                break;
            const auto value = *left;
            *left++ = *right;
            *right = value;
        }
    };

    reverse(begin, mid);
    reverse(mid, end);
    reverse(begin, end);
}
#endif
