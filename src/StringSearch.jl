module StringSearch

const Str = Union{String,SubString{String}}

const libstrsearch = joinpath(@__DIR__, "libstrsearch.so")

function findnext(a::Str, b::Str, i::Int)
    if i > lastindex(b) + 1
        return nothing
    elseif i < firstindex(b)
        i = firstindex(b)
    elseif i ≠ thisind(b, i)
        i = nextind(b, i)
    end
    offset = sse2_search_julia(a, @view b[i:end])
    if offset < 0
        return nothing
    else
        return i+offset:i+offset-1+ncodeunits(a)
    end
end

sse2_search(a, b) =
    GC.@preserve a b Int(ccall((:sse2_search, libstrsearch), Cssize_t, (Ptr{UInt8}, Cssize_t, Ptr{UInt8}, Cssize_t), a, sizeof(a), b, sizeof(b)))

avx_search(a, b) =
    GC.@preserve a b Int(ccall((:avx_search, libstrsearch), Cssize_t, (Ptr{UInt8}, Cssize_t, Ptr{UInt8}, Cssize_t), a, sizeof(a), b, sizeof(b)))

const m128i = NTuple{16,VecElement{UInt8}}

function set1_epi8(x::UInt8)
    Base.llvmcall("""
    %2 = insertelement <16 x i8> undef, i8 %0, i32 0
    %3 = shufflevector <16 x i8> %2, <16 x i8> undef, <16 x i32> zeroinitializer
    ret <16 x i8> %3
    """, m128i, Tuple{UInt8}, x)
end

function loadu_si128(p::Ptr{UInt8})
    Base.llvmcall("""
    %2 = inttoptr i64 %0 to <16 x i8>*
    %3 = load <16 x i8>, <16 x i8>* %2, align 1
    ret <16 x i8> %3
    """, m128i, Tuple{Ptr{UInt8}}, p)
end

function cmpeq_epi8(x::m128i, y::m128i)
    Base.llvmcall("""
    %3 = icmp eq <16 x i8> %0, %1
    %4 = sext <16 x i1> %3 to <16 x i8>
    ret <16 x i8> %4
    """, m128i, Tuple{m128i, m128i}, x, y)
end

function and_si128(x::m128i, y::m128i)
    Base.llvmcall("""
    %3 = and <16 x i8> %1, %0
    ret <16 x i8> %3
    """, m128i, Tuple{m128i, m128i}, x, y)
end

function movemask_epi8(x::m128i)
    Base.llvmcall("""
    %2 = icmp slt <16 x i8> %0, zeroinitializer
    %3 = bitcast <16 x i1> %2 to i16
    %4 = zext i16 %3 to i32
    ret i32 %4
    """, Int32, Tuple{m128i}, x)
end

memcmp(p, q, n) = ccall(:memcmp, Cint, (Ptr{UInt8}, Ptr{UInt8}, Csize_t), p, q, n)
memchr(p, c, n) = ccall(:memchr, Ptr{UInt8}, (Ptr{UInt8}, Cint, Csize_t), p, c, n)

function sse2_search_julia(a, b)
    m = sizeof(a)
    n = sizeof(b)
    if m == 0
        return 0
    elseif m == 1
        p = memchr(pointer(b), codeunit(a, 1), n)
        return p == C_NULL ? -1 : Int(p - pointer(b))
    end
    F = set1_epi8(codeunit(a, 1))
    L = set1_epi8(codeunit(a, sizeof(a)))
    i = 0
    while i < n - m - 14
        S = loadu_si128(pointer(b) + i)
        T = loadu_si128(pointer(b) + i + m - 1)
        mask = movemask_epi8(and_si128(cmpeq_epi8(S, F), cmpeq_epi8(T, L)))
        while mask ≠ 0
            offset = trailing_zeros(mask)
            if memcmp(pointer(a) + 1, pointer(b) + i + offset + 1, m - 2) == 0
                return i + offset
            end
            mask &= mask - 1
        end
        i += 16
    end
    while i < n - m + 1
        if memcmp(pointer(a), pointer(b) + i, m) == 0
            return i
        end
        i += 1
    end
    return -1
end

v2s(x::m128i) = String([Char(b.value) for b in x])

findnext(a::Str, b::Str, i::Integer) = findnext(a, b, Int(i))

findfirst(a::Str, b::Str) = findnext(a, b, firstindex(b))

end
