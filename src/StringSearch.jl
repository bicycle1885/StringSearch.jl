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
    offset = GC.@preserve a b offset = avx_search(a, @view b[i:end])
    if offset < 0
        return nothing
    else
        return i+offset:i+offset-1+ncodeunits(a)
    end
end

sse2_search(a, b) =
    Int(ccall((:sse2_search, libstrsearch), Cssize_t, (Ptr{UInt8}, Cssize_t, Ptr{UInt8}, Cssize_t), a, sizeof(a), b, sizeof(b)))

avx_search(a, b) =
    Int(ccall((:avx_search, libstrsearch), Cssize_t, (Ptr{UInt8}, Cssize_t, Ptr{UInt8}, Cssize_t), a, sizeof(a), b, sizeof(b)))

findnext(a::Str, b::Str, i::Integer) = findnext(a, b, Int(i))

findfirst(a::Str, b::Str) = findnext(a, b, firstindex(b))

end
