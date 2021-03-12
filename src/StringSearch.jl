module StringSearch

using Base.BinaryPlatforms: CPUID

const Str = Union{String,SubString{String}}
const AVX2 = Ref(CPUID.test_cpu_feature(CPUID.JL_X86_avx2))

use_avx2() = AVX2[]

# NOTE: You may need to GC.@preserve the referenced object.
struct MemoryView
    ptr::Ptr{UInt8}
    len::Int
end
Base.length(mem::MemoryView) = mem.len
Base.firstindex(mem::MemoryView) = 1
Base.lastindex(mem::MemoryView) = mem.len
Base.getindex(mem::MemoryView, i::Integer) = unsafe_load(mem.ptr + i - 1)

MemoryView(s::Str) = MemoryView(pointer(s), sizeof(s))

function findnext(a::Str, b::Str, i::Int)
    if i > lastindex(b) + 1
        return nothing
    end
    i = max(i, firstindex(b))
    offset = search_forward(a, b, i - 1)
    return offset ≥ 0 ? (offset+1:offset+lastindex(a)) : nothing
end

findnext(a::Str, b::Str, i::Integer) = findnext(a, b, Int(i))

findfirst(a::Str, b::Str) = findnext(a, b, firstindex(b))

function findprev(a::Str, b::Str, i::Int)
    if i < firstindex(b) - 1
        return nothing
    end
    i = min(i, lastindex(b))
    s = ncodeunits(b) - (nextind(b, i) - 1)
    offset = search_backward(a, b, s)
    return offset ≥ 0 ? (offset+1:offset+lastindex(a)) : nothing
end

findprev(a::Str, b::Str, i::Integer) = findprev(a, b, Int(i))

findlast(a::Str, b::Str) = findprev(a, b, lastindex(b))

search_forward(a::Str, b::Str, s::Int) =
    GC.@preserve a b search_forward(MemoryView(a), MemoryView(b), s)
search_backward(a::Str, b::Str, s::Int) =
    GC.@preserve a b search_backward(MemoryView(a), MemoryView(b), s)

function search_forward(a::UInt8, b::MemoryView, s::Int)
    p = memchr(b.ptr + s, a, length(b) - s)
    return p ≠ C_NULL ? Int(p - b.ptr) : -1
end

function search_backward(a::UInt8, b::MemoryView, s::Int)
    p = memrchr(b.ptr, a, length(b) - s)
    return p ≠ C_NULL ? Int(p - b.ptr) : -1
end

function search_forward(a::MemoryView, b::MemoryView, s::Int)
    m = length(a)
    n = length(b) - s
    if m > n
        return -1
    elseif m == 0
        return s
    elseif m == 1
        return search_forward(a[begin], b, s)
    end

    d = m - 1      # displacement between registers
    p = b.ptr + s  # search position
    p_end = p + n  # end position (exclusive)
    if n < d + 16
        # too short to use SIMD instructions
        while p + m - 1 < p_end
            if memcmp(p, a.ptr, m) == 0
                return Int(p - b.ptr)
            end
            p += 1
        end
        return -1
    elseif n < d + 32 || !use_avx2()
        # use 16-byte registers
        F = set1_epi8_128(a[begin])
        L = set1_epi8_128(a[end])
        while true
            S = loadu_si128(p)
            T = loadu_si128(p + d)
            mask = movemask_epi8(and_si128(cmpeq_epi8(S, F), cmpeq_epi8(T, L)))
            while mask ≠ 0
                i = trailing_zeros(mask)
                # NOTE: we already know that the first and the last byte are matching
                if memcmp(p + i + 1, a.ptr + 1, m - 2) == 0
                    return Int(p + i - b.ptr)
                end
                mask &= mask - 1
            end
            rem = p_end - (p + d + 16)
            if rem < 16
                p += rem
                break
            end
            p += 16
        end
        # Putting the following part inside the main loop above makes code
        # clean but it seems to have a significant negative impact on the
        # performance on Zen2, probably due to variable step size.
        S = loadu_si128(p)
        T = loadu_si128(p + d)
        mask = movemask_epi8(and_si128(cmpeq_epi8(S, F), cmpeq_epi8(T, L)))
        while mask ≠ 0
            i = trailing_zeros(mask)
            if memcmp(p + i + 1, a.ptr + 1, m - 2) == 0
                return Int(p + i - b.ptr)
            end
            mask &= mask - 1
        end
        return -1
    else
        # use 32-byte registers
        F = set1_epi8_256(a[begin])
        L = set1_epi8_256(a[end])
        while true
            S = loadu_si256(p)
            T = loadu_si256(p + d)
            mask = movemask_epi8(and_si256(cmpeq_epi8(S, F), cmpeq_epi8(T, L)))
            while mask ≠ 0
                i = trailing_zeros(mask)
                # NOTE: we already know that the first and the last byte are matching
                if memcmp(p + i + 1, a.ptr + 1, m - 2) == 0
                    return Int(p + i - b.ptr)
                end
                mask &= mask - 1
            end
            rem = p_end - (p + d + 32)
            if rem < 32
                p += rem
                break
            end
            p += 32
        end
        # Putting the following part inside the main loop above makes code
        # clean but it seems to have a significant negative impact on the
        # performance on Zen2, probably due to variable step size.
        S = loadu_si256(p)
        T = loadu_si256(p + d)
        mask = movemask_epi8(and_si256(cmpeq_epi8(S, F), cmpeq_epi8(T, L)))
        while mask ≠ 0
            i = trailing_zeros(mask)
            if memcmp(p + i + 1, a.ptr + 1, m - 2) == 0
                return Int(p + i - b.ptr)
            end
            mask &= mask - 1
        end
        return -1
    end
end

function search_backward(a::MemoryView, b::MemoryView, s::Int)
    m = length(a)
    n = length(b) - s
    if n < m
        return -1
    elseif m == 0
        return s
    elseif m == 1
        return search_backward(a[begin], b, s)
    end

    d = m - 1  # displacement between registers
    if n < d + 16
        # too short to use SIMD instructions
        p = b.ptr + n - m
        while p ≥ b.ptr
            if memcmp(p, a.ptr, m) == 0
                return Int(p - b.ptr)
            end
            p -= 1
        end
        return -1
    elseif n < d + 32 || !use_avx2()
        # use 16-byte registers
        F = set1_epi8_128(a[begin])
        L = set1_epi8_128(a[end])
        p = b.ptr + n - 16 - d
        while true
            S = loadu_si128(p)
            T = loadu_si128(p + d)
            mask = movemask_epi8(and_si128(cmpeq_epi8(S, F), cmpeq_epi8(T, L)))
            while mask ≠ 0
                i = sizeof(mask) * 8 - leading_zeros(mask) - 1
                if memcmp(a.ptr + 1, p + i + 1, m - 2) == 0
                    return Int(p + i - b.ptr)
                end
                mask ⊻= 1 << i
            end
            step = min(16, p - b.ptr)
            if step == 0
                return -1
            end
            p -= step
        end
    else
        # use 32-byte registers
        F = set1_epi8_256(a[begin])
        L = set1_epi8_256(a[end])
        p = b.ptr + n - 32 - d
        while true
            S = loadu_si256(p)
            T = loadu_si256(p + d)
            mask = movemask_epi8(and_si256(cmpeq_epi8(S, F), cmpeq_epi8(T, L)))
            while mask ≠ 0
                i = sizeof(mask) * 8 - leading_zeros(mask) - 1
                if memcmp(a.ptr + 1, p + i + 1, m - 2) == 0
                    return Int(p + i - b.ptr)
                end
                mask ⊻= 1 << i
            end
            rem = p - b.ptr
            if rem < 32
                p -= rem
                break
            end
            p -= 32
        end
        S = loadu_si256(p)
        T = loadu_si256(p + d)
        mask = movemask_epi8(and_si256(cmpeq_epi8(S, F), cmpeq_epi8(T, L)))
        while mask ≠ 0
            i = sizeof(mask) * 8 - leading_zeros(mask) - 1
            if memcmp(a.ptr + 1, p + i + 1, m - 2) == 0
                return Int(p + i - b.ptr)
            end
            mask ⊻= 1 << i
        end
        return -1
    end
end


# Low-level code
# --------------

memcmp(p, q, n) = ccall(:memcmp, Cint, (Ptr{UInt8}, Ptr{UInt8}, Csize_t), p, q, n)
memchr(p, c, n) = ccall(:memchr, Ptr{UInt8}, (Ptr{UInt8}, Cint, Csize_t), p, c, n)
memrchr(p, c, n) = ccall(:memrchr, Ptr{UInt8}, (Ptr{UInt8}, Cint, Csize_t), p, c, n)

const U8x16 = NTuple{16,VecElement{UInt8}}
const U8x32 = NTuple{32,VecElement{UInt8}}

function set1_epi8_128(x::UInt8)
    Base.llvmcall("""
    %2 = insertelement <16 x i8> undef, i8 %0, i32 0
    %3 = shufflevector <16 x i8> %2, <16 x i8> undef, <16 x i32> zeroinitializer
    ret <16 x i8> %3
    """, U8x16, Tuple{UInt8}, x)
end

function set1_epi8_256(x::UInt8)
    Base.llvmcall("""
    %2 = insertelement <32 x i8> undef, i8 %0, i32 0
    %3 = shufflevector <32 x i8> %2, <32 x i8> undef, <32 x i32> zeroinitializer
    ret <32 x i8> %3
    """, U8x32, Tuple{UInt8}, x)
end

function loadu_si128(p::Ptr{UInt8})
    Base.llvmcall("""
    %2 = inttoptr i64 %0 to <16 x i8>*
    %3 = load <16 x i8>, <16 x i8>* %2, align 1
    ret <16 x i8> %3
    """, U8x16, Tuple{Ptr{UInt8}}, p)
end

function loadu_si256(p::Ptr{UInt8})
    Base.llvmcall("""
    %2 = inttoptr i64 %0 to <32 x i8>*
    %3 = load <32 x i8>, <32 x i8>* %2, align 1
    ret <32 x i8> %3
    """, U8x32, Tuple{Ptr{UInt8}}, p)
end

function cmpeq_epi8(x::U8x16, y::U8x16)
    Base.llvmcall("""
    %3 = icmp eq <16 x i8> %0, %1
    %4 = sext <16 x i1> %3 to <16 x i8>
    ret <16 x i8> %4
    """, U8x16, Tuple{U8x16, U8x16}, x, y)
end

function cmpeq_epi8(x::U8x32, y::U8x32)
    Base.llvmcall("""
    %3 = icmp eq <32 x i8> %0, %1
    %4 = sext <32 x i1> %3 to <32 x i8>
    ret <32 x i8> %4
    """, U8x32, Tuple{U8x32, U8x32}, x, y)
end

function and_si128(x::U8x16, y::U8x16)
    Base.llvmcall("""
    %3 = and <16 x i8> %1, %0
    ret <16 x i8> %3
    """, U8x16, Tuple{U8x16, U8x16}, x, y)
end

function and_si256(x::U8x32, y::U8x32)
    Base.llvmcall("""
    %3 = and <32 x i8> %1, %0
    ret <32 x i8> %3
    """, U8x32, Tuple{U8x32, U8x32}, x, y)
end

function movemask_epi8(x::U8x16)
    Base.llvmcall("""
    %2 = icmp slt <16 x i8> %0, zeroinitializer
    %3 = bitcast <16 x i1> %2 to i16
    %4 = zext i16 %3 to i64
    ret i64 %4
    """, Int64, Tuple{U8x16}, x)
end

function movemask_epi8(x::U8x32)
    Base.llvmcall("""
    %2 = icmp slt <32 x i8> %0, zeroinitializer
    %3 = bitcast <32 x i1> %2 to i32
    %4 = zext i32 %3 to i64
    ret i64 %4
    """, Int64, Tuple{U8x32}, x)
end

# For debugging
v2s(x::Union{U8x16,U8x32}) = String([Char(b.value) for b in x])

end
