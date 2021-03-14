module StringSearch

using Base: Fix2, BinaryPlatforms, first_utf8_byte

const AVX2 = Ref(BinaryPlatforms.CPUID.test_cpu_feature(BinaryPlatforms.CPUID.JL_X86_avx2))

use_avx2() = AVX2[]


# Generic Methods
# ---------------

const AbstractByteVector = AbstractVector{<:Union{Int8,UInt8}}

in(a::AbstractChar, b::AbstractString) = findfirst(isequal(a), b) !== nothing
in(::AbstractString, ::AbstractString) = error("use occursin(x, y) for string containment")

occursin(b) = Fix2(occursin, b)
occursin(a::Union{AbstractString,AbstractChar}, b::AbstractString) = findfirst(a, b) !== nothing

for (Ta, Tb) in [
        (Function, Union{AbstractString,AbstractByteVector}),
        (AbstractChar, AbstractString),
        (AbstractString, AbstractString),
        (AbstractByteVector, AbstractByteVector),
    ]
    @eval begin
        findfirst(a::$Ta, b::$Tb) = findnext(a, b, firstindex(b))
        findlast(a::$Ta, b::$Tb) = findprev(a, b, lastindex(b))
        findnext(a::$Ta, b::$Tb, i::Integer) = findnext(a, b, Int(i))
        findprev(a::$Ta, b::$Tb, i::Integer) = findprev(a, b, Int(i))
    end
end

findnext(a::AbstractChar, b::AbstractString, i::Int) = findnext(isequal(a), b, i)
findprev(a::AbstractChar, b::AbstractString, i::Int) = findprev(isequal(a), b, i)

function findnext(p::Function, b::Union{AbstractString,AbstractByteVector}, i::Int)
    i = max(i, firstindex(b))
    last = lastindex(b)
    @inbounds while i ≤ last
        p(b[i]) && return i
        i = nextind(b, i)
    end
    return nothing
end

function findprev(p::Function, b::Union{AbstractString,AbstractByteVector}, i::Int)
    i = min(i, lastindex(b))
    first = firstindex(b)
    @inbounds while i ≥ first
        p(b[i]) && return i
        i = prevind(b, i)
    end
    return nothing
end

function findnext(a::AbstractString, b::AbstractString, i::Int)
    i = max(i, firstindex(b))
    isempty(a) && return i:i-1
    last = lastindex(b)
    while i ≤ last
        startswith(SubString(b, i), a) && return i:nextind(b, i, length(a) - 1)
        i = nextind(b, i)
    end
    return nothing
end

function findprev(a::AbstractString, b::AbstractString, i::Int)
    i = min(i, lastindex(b))
    isempty(a) && return i+1:i
    first = firstindex(b)
    while i ≥ first
        endswith(SubString(b, first, i), a) && return prevind(b, i, length(a) - 1):i
        i = prevind(b, i)
    end
    return nothing
end

function findnext(a::AbstractByteVector, b::AbstractByteVector, i::Int)
    n = firstindex(b)
    offset = search_forward(a, b, max(i, n) - n)
    return offset ≥ 0 ? (offset+firstindex(a):offset+lastindex(a)) : nothing
end

function findprev(a::AbstractByteVector, b::AbstractByteVector, i::Int)
    n = lastindex(b)
    offset = search_backward(a, b, n - min(i, n))
    return offset ≥ 0 ? (offset+firstindex(a):offset+lastindex(a)) : nothing
end


# Specialized Methods
# -------------------

const Str = Union{String,SubString{String}}

const Fix2Eq{T} = Fix2{<:Union{typeof(isequal),typeof(==)},T}

function findnext(pred::Fix2Eq{<:AbstractChar}, b::Str, i::Int)
    i = max(i, firstindex(b))
    a = pred.x
    probe = first_utf8_byte(a)
    @inbounds while true
        offset = search_forward(probe, b, i - 1)
        if offset < 0
            return nothing
        elseif pred(b[offset+1])
            return offset + 1
        else
            i = nextind(b, i)
        end
    end
end

function findnext(a::Str, b::Str, i::Int)
    i = max(i, firstindex(b))
    offset = search_forward(a, b, i - 1)
    return offset ≥ 0 ? (offset+1:offset+lastindex(a)) : nothing
end

function findnext(pred::Fix2Eq{<:Union{Int8,UInt8}}, b::Vector{<:Union{Int8,UInt8}}, i::Int)
    a = pred.x
    typemin(eltype(b)) ≤ a ≤ typemax(eltype(b)) || return nothing
    i = max(i, firstindex(b))
    @inbounds while true
        offset = search_forward(a % UInt8, b, i - 1)
        if offset < 0
            return nothing
        elseif pred(b[offset+1])
            return offset + 1
        else
            i += 1
        end
    end
end

function findprev(pred::Fix2Eq{<:AbstractChar}, b::Str, i::Int)
    i < 0 && return nothing
    n = ncodeunits(b)
    i = nextind(b, min(i, n))
    a = pred.x
    probe = first_utf8_byte(a)
    @inbounds while true
        offset = search_backward(probe, b, n + 1 - i)
        if offset < 0
            return nothing
        elseif pred(b[offset+1])
            return offset + 1
        else
            i = prevind(b, i)
        end
    end
end

function findprev(pred::Fix2Eq{<:Union{Int8,UInt8}}, b::Vector{<:Union{Int8,UInt8}}, i::Int)
    a = pred.x
    typemin(eltype(b)) ≤ a ≤ typemax(eltype(b)) || return nothing
    n = length(b)
    i = min(i, lastindex(b))
    @inbounds while true
        offset = search_backward(a % UInt8, b, n - i)
        if offset < 0
            return nothing
        elseif pred(b[offset+1])
            return offset + 1
        else
            i -= 1
        end
    end
end

function findprev(a::Str, b::Str, i::Int)
    i < 0 && return nothing
    n = ncodeunits(b)
    offset = search_backward(a, b, n + 1 - nextind(b, min(i, n)))
    return offset ≥ 0 ? (offset+1:offset+lastindex(a)) : nothing
end


# MemoryView
# ----------

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
MemoryView(s::Vector{<:Union{Int8,UInt8}}) = MemoryView(pointer(s), sizeof(s))


# Search Functions
# ----------------

# The `search_forward` and `search_backward` function take following three
# arguments:
#
#   1. the needle (`a`)
#   2. the haystack (`b`)
#   3. the number of bytes ignored from the edge of the haystack (`k`)
#
# `search_forward` ignores `k` bytes from the head of the haystack and
# `search_backward` does from the tail of it. The `k` argument must be
# nonnegative, but it is allowed to be larger than the length of `b`. The
# functions return a zero-based offset of the matching position if any matching
# position is found. Thus, the caller will need to add `firstindex(b)` to the
# returned value in order to get the actual index. If there is no matching,
# they return a negative value (i.e., -1).

search_forward(a::UInt8, b::Str, k::Int) =
    GC.@preserve b search_forward(a, MemoryView(b), k)
search_forward(a::Str, b::Str, k::Int) =
    GC.@preserve a b search_forward(MemoryView(a), MemoryView(b), k)

search_backward(a::UInt8, b::Str, k::Int) =
    GC.@preserve b search_backward(a, MemoryView(b), k)
search_backward(a::Str, b::Str, k::Int) =
    GC.@preserve a b search_backward(MemoryView(a), MemoryView(b), k)

search_forward(a::T, b::Vector{T}, k::Int) where T <: Union{Int8,UInt8} =
    GC.@preserve b search_forward(a, MemoryView(b), k)
search_forward(a::Vector{T}, b::Vector{T}, k::Int) where T<: Union{Int8,UInt8} =
    GC.@preserve a b search_forward(MemoryView(a), MemoryView(b), k)

search_backward(a::T, b::Vector{T}, k::Int) where T <: Union{Int8,UInt8} =
    GC.@preserve b search_backward(a, MemoryView(b), k)
search_backward(a::Vector{T}, b::Vector{T}, k::Int) where T<: Union{Int8,UInt8} =
    GC.@preserve a b search_backward(MemoryView(a), MemoryView(b), k)

function search_forward(a::UInt8, b::MemoryView, k::Int)
    p = memchr(b.ptr + k, a, length(b) - k)
    return p ≠ C_NULL ? Int(p - b.ptr) : -1
end

function search_backward(a::UInt8, b::MemoryView, k::Int)
    p = memrchr(b.ptr, a, length(b) - k)
    return p ≠ C_NULL ? Int(p - b.ptr) : -1
end

# The following algorithm is based on this article:
# SIMD-friendly algorithms for substring searching, Wojciech Muła
# http://0x80.pl/articles/simd-strfind.html

function search_forward(a::MemoryView, b::MemoryView, k::Int)
    m = length(a)
    n = length(b) - k
    if m > n
        return -1
    elseif m == 0
        return k
    elseif m == 1
        return search_forward(a[begin], b, k)
    end

    d = m - 1      # displacement between registers
    p = b.ptr + k  # search position
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

function search_backward(a::MemoryView, b::MemoryView, k::Int)
    m = length(a)
    n = length(b) - k
    if n < m
        return -1
    elseif m == 0
        return k
    elseif m == 1
        return search_backward(a[begin], b, k)
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
            rem = p - b.ptr
            if rem < 16
                p -= rem
                break
            end
            p -= 16
        end
        S = loadu_si128(p)
        T = loadu_si128(p + d)
        mask = movemask_epi8(and_si128(cmpeq_epi8(S, F), cmpeq_epi8(T, L)))
        while mask ≠ 0
            i = sizeof(mask) * 8 - leading_zeros(mask) - 1
            if memcmp(a.ptr + 1, p + i + 1, m - 2) == 0
                return Int(p + i - b.ptr)
            end
            mask ⊻=1 << i
        end
        return -1
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

function search_forward(a::AbstractByteVector, b::AbstractByteVector, k::Int)
    m = length(a)
    n = length(b) - k
    if m > n
        return -1
    elseif m == 0
        return k
    end

    # preprocess
    a_end = a[end]
    filter = bloom_filter_bit(a_end)
    displacement = m
    @inbounds for i in firstindex(a):lastindex(a)-1
        filter |= bloom_filter_bit(a[i])
        if a[i] == a_end
            displacement = lastindex(a) - i
        end
    end

    # main loop
    last = lastindex(b)
    p = firstindex(b) + k
    @inbounds while p + m - 1 ≤ last
        if a_end == b[p+m-1]
            # the last byte is matching
            i = firstindex(a)
            while i < lastindex(a)
                a[i] == b[p+i-1] || break
                i += 1
            end
            if i == lastindex(a)
                return p - firstindex(b)
            elseif p + m ≤ last && !mayhave(filter, b[p+m])
                p += m + 1
            else
                p += displacement
            end
        else
            if p + m ≤ last && !mayhave(filter, b[p+m])
                p += m +  1
            else
                p += 1
            end
        end
    end
    return -1
end

function search_backward(a::AbstractByteVector, b::AbstractByteVector, k::Int)
    m = length(a)
    n = length(b) - k
    if m > n
        return -1
    elseif m == 0
        return k
    end

    # preprocess
    a_begin = a[begin]
    filter = bloom_filter_bit(a_begin)
    displacement = m
    @inbounds for i in lastindex(a):-1:firstindex(a)+1
        filter |= bloom_filter_bit(a[i])
        if a[i] == a_begin
            displacement = firstindex(a) - i
        end
    end

    # main loop
    first = firstindex(b)
    p = lastindex(b) + 1 - (m + k)
    @inbounds while p ≥ first
        if a_begin == b[p]
            # the first byte is matching
            i = lastindex(a)
            while i > firstindex(a)
                a[i] == b[p+i-1] || break
                i -= 1
            end
            if i == firstindex(a)
                return p - first
            elseif p - 1 ≥ first && !mayhave(filter, b[p-1])
                p -= m + 1
            else
                p -= displacement
            end
        else
            if p - 1 ≥ first && !mayhave(filter, b[p-1])
                p -= m + 1
            else
                p -= 1
            end
        end
    end
    return -1
end

# Bloom filter using a 64-bit integer
bloom_filter_bit(x::Union{Int8,UInt8}) = UInt64(1) << (x & 63)
mayhave(filter::UInt64, x::Union{Int8,UInt8}) = filter & bloom_filter_bit(x) ≠ 0


# Low-level operations
# --------------------

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

end
