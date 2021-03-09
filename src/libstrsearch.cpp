// A reference implementation written in C++ based on:
// http://0x80.pl/articles/simd-strfind.html#algorithm-1-generic-simd
#include <unistd.h>
#include <stdint.h>
#include <string.h>
#include <emmintrin.h>
#include <immintrin.h>

extern "C"
ssize_t sse2_search(const uint8_t *a, const ssize_t m, const uint8_t *b, const ssize_t n)
{
    if (m == 0)
        return 0;
    if (m == 1) {
        auto *p = reinterpret_cast<const uint8_t*>(memchr(reinterpret_cast<const void*>(b), *a, n));
        return p == nullptr ? -1 : p - b;
    }
    const __m128i F = _mm_set1_epi8(*a);
    const __m128i L = _mm_set1_epi8(*(a + m - 1));
    ssize_t i = 0;
    for (; i < n - m - 14; i += 16) {
        const __m128i S =_mm_loadu_si128(reinterpret_cast<const __m128i*>(b + i));
        const __m128i T =_mm_loadu_si128(reinterpret_cast<const __m128i*>(b + i + m - 1));
        int mask = _mm_movemask_epi8(_mm_and_si128(_mm_cmpeq_epi8(S, F), _mm_cmpeq_epi8(T, L)));
        while (mask != 0) {
            int offset = __builtin_ctz(mask);
            if (memcmp(a + 1, b + i + offset + 1, m - 2) == 0)
                return i + offset;
            mask &= mask - 1;
        }
    }
    for (; i < n - m + 1; i += 1)
        if (memcmp(a, b + i, m) == 0)
            return i;
    return -1;
}

extern "C"
ssize_t avx2_search(const uint8_t *a, const ssize_t m, const uint8_t *b, const ssize_t n)
{
    if (m == 0)
        return 0;
    if (m == 1) {
        auto *p = reinterpret_cast<const uint8_t*>(memchr(reinterpret_cast<const void*>(b), *a, n));
        return p == nullptr ? -1 : p - b;
    }
    const __m256i F = _mm256_set1_epi8(*a);
    const __m256i L = _mm256_set1_epi8(*(a + m - 1));
    ssize_t i = 0;
    for (; i < n - m - 30; i += 32) {
        const __m256i S =_mm256_loadu_si256(reinterpret_cast<const __m256i*>(b + i));
        const __m256i T =_mm256_loadu_si256(reinterpret_cast<const __m256i*>(b + i + m - 1));
        int mask = _mm256_movemask_epi8(_mm256_and_si256(_mm256_cmpeq_epi8(S, F), _mm256_cmpeq_epi8(T, L)));
        while (mask != 0) {
            int offset = __builtin_ctz(mask);
            if (memcmp(a + 1, b + i + offset + 1, m - 2) == 0)
                return i + offset;
            mask &= mask - 1;
        }
    }
    for (; i < n - m + 1; i += 1)
        if (memcmp(a, b + i, m) == 0)
            return i;
    return -1;
}