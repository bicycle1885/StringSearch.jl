module StringSearch

const Str = Union{String,SubString{String}}

function supports_avx2()
    if Sys.islinux()
        success(pipeline(`cat /proc/cpuinfo`, `grep -c avx2`))
    else
        false
    end
end

function findnext(a::Str, b::Str, i::Int)
    if i > lastindex(b) + 1
        return nothing
    elseif i < firstindex(b)
        i = firstindex(b)
    end
    @static if supports_avx2()
        offset = avx2_search_julia(a, b, i-1)
    else
        offset = sse2_search_julia(a, b, i-1)
    end
    if offset < 0
        return nothing
    else
        return i+offset:i+offset-1+lastindex(a)
    end
end

findnext(a::Str, b::Str, i::Integer) = findnext(a, b, Int(i))

findfirst(a::Str, b::Str) = findnext(a, b, firstindex(b))

const libstrsearch = joinpath(@__DIR__, "libstrsearch.so")

sse2_search_cxx(a, b, o) =
    GC.@preserve a b Int(ccall((:sse2_search, libstrsearch), Cssize_t, (Ptr{UInt8}, Cssize_t, Ptr{UInt8}, Cssize_t), a, ncodeunits(a), pointer(b) + o, ncodeunits(b) - o))

avx2_search_cxx(a, b, o) =
    GC.@preserve a b Int(ccall((:avx2_search, libstrsearch), Cssize_t, (Ptr{UInt8}, Cssize_t, Ptr{UInt8}, Cssize_t), a, ncodeunits(a), pointer(b) + o, ncodeunits(b) - o))

function sse2_search_julia(a, b, o)
    m = ncodeunits(a)
    n = ncodeunits(b) - o
    p = pointer(b) + o
    if m == 0
        return 0
    elseif m == 1
        q = memchr(p, codeunit(a, 1), n)
        return q == C_NULL ? -1 : Int(q - p)
    end
    F = set1_epi8_128(codeunit(a, 1))
    L = set1_epi8_128(codeunit(a, m))
    i = 0
    while i < n - m - 14
        S = loadu_si128(p + i)
        T = loadu_si128(p + i + m - 1)
        mask = movemask_epi8(and_si128(cmpeq_epi8(S, F), cmpeq_epi8(T, L)))
        while mask ≠ 0
            offset = trailing_zeros(mask)
            if memcmp(pointer(a) + 1, p + i + offset + 1, m - 2) == 0
                return i + offset
            end
            mask &= mask - 1
        end
        i += 16
    end
    while i < n - m + 1
        if memcmp(pointer(a), p + i, m) == 0
            return i
        end
        i += 1
    end
    return -1
end

function avx2_search_julia(a, b, o)
    m = ncodeunits(a)
    n = ncodeunits(b) - o
    p = pointer(b) + o
    if m == 0
        return 0
    elseif m == 1
        q = memchr(p, codeunit(a, 1), n)
        return q == C_NULL ? -1 : Int(q - p)
    end
    F = set1_epi8_256(codeunit(a, 1))
    L = set1_epi8_256(codeunit(a, m))
    i = 0
    while i < n - m - 30
        S = loadu_si256(p + i)
        T = loadu_si256(p + i + m - 1)
        mask = movemask_epi8(and_si256(cmpeq_epi8(S, F), cmpeq_epi8(T, L)))
        while mask ≠ 0
            offset = trailing_zeros(mask)
            if memcmp(pointer(a) + 1, p + i + offset + 1, m - 2) == 0
                return i + offset
            end
            mask &= mask - 1
        end
        i += 32
    end
    while i < n - m + 1
        if memcmp(pointer(a), p + i, m) == 0
            return i
        end
        i += 1
    end
    return -1
end

# Low-level code
# --------------

memcmp(p, q, n) = ccall(:memcmp, Cint, (Ptr{UInt8}, Ptr{UInt8}, Csize_t), p, q, n)
memchr(p, c, n) = ccall(:memchr, Ptr{UInt8}, (Ptr{UInt8}, Cint, Csize_t), p, c, n)

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
