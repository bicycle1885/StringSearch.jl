using BenchmarkTools
using StringSearch
using Printf

function time(t)
    if t < 1e3
        @sprintf "%.1f ns" t / 1e0
    elseif t < 1e6
        @sprintf "%.1f μs" t / 1e3
    elseif t < 1e9
        @sprintf "%.1f ms" t / 1e6
    else
        @sprintf "%.1f  s" t / 1e9
    end
end

function report(a, ss, base, result)
    t_ss = minimum(ss).time
    t_base = minimum(base).time
    t_ratio = @sprintf "x%.2f" t_ss \ t_base
    @printf "%18s  %8s  %8s  %8s  %8s\n" repr(a) time(t_ss) time(t_base) t_ratio repr(result)
end

const B = Base
const S = StringSearch

function benchmark_findfirst(a, b)
    @assert B.findfirst(a, b) == S.findfirst(a, b)
    ss = @benchmark S.findfirst($a, $b)
    base = @benchmark B.findfirst($a, $b)
    report(a, ss, base, S.findfirst(a, b))
end

function benchmark_findlast(a, b)
    @assert B.findlast(a, b) == S.findlast(a, b)
    ss = @benchmark S.findlast($a, $b)
    base = @benchmark B.findlast($a, $b)
    report(a, ss, base, S.findlast(a, b))
end

# AVX2
S.AVX2[] = "-avx2" ∈ ARGS || "-noavx2" ∉ ARGS
if S.use_avx2()
    @info "AVX2 is active"
else
    @info "AVX2 is not active"
end

# search direction
const forward = "-forward" ∈ ARGS || "-backward" ∉ ARGS
if forward
    @info "forward search mode"
else
    @info "backward search mode"
end

# short query only
const short = "-short" ∈ ARGS

# char query only
const char = "-char" ∈ ARGS

# quick benchmark
if "-quick" ∈ ARGS
    BenchmarkTools.DEFAULT_PARAMETERS.samples = 1000
    BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1.0
end

if forward
    function countall(findnext, a, b)
        n = 0
        r = findnext(a, b, firstindex(b))
        while r !== nothing
            n += 1
            r = findnext(a, b, first(r) + 1)
        end
        return n
    end
else
    function countall(findprev, a, b)
        n = 0
        r = findprev(a, b, lastindex(b))
        while r !== nothing
            n += 1
            r = findprev(a, b, last(r) - 1)
        end
        return n
    end
end

function benchmark_countall(a, b)
    if forward
        sfind = S.findnext
        bfind = B.findnext
    else
        sfind = S.findprev
        bfind = B.findprev
    end
    @assert countall(bfind, a, b) == countall(sfind, a, b)
    ss = @benchmark countall($sfind, $a, $b)
    base = @benchmark countall($bfind, $a, $b)
    report(a, ss, base, countall(sfind, a, b))
end

@printf "%18s  %8s  %8s  %8s  %8s\n" "Query" "SS" "Base" "Ratio" "Result"

b = "abracadabra"
println()
println("# findfirst/last for a very short string ($(sizeof(b)) bytes)")
for a in ['a', 'd', "c", "ca", "cad", "cada", "cadab", "cadabr", "cadabra", "namnam"]
    short && sizeof(a) > 3 && continue
    char && !(a isa Char) && continue
    if forward
        benchmark_findfirst(a, b)
    else
        benchmark_findlast(a, b)
    end
end

b = """
Julia is a high-level, high-performance dynamic language for technical computing. The main homepage for Julia can be found at julialang.org. This is the GitHub repository of Julia source code, including instructions for compiling and installing Julia, below.
"""
println()
println("# findfirst/last for a short string ($(sizeof(b)) bytes)")
for a in ['a', 'G', "a", "be", "the", "code", "Julia", "language", "installing", "Python"]
    short && sizeof(a) > 3 && continue
    char && !(a isa Char) && continue
    if forward
        benchmark_findfirst(a, b)
    else
        benchmark_findlast(a, b)
    end
end

if isfile("base.txt.zst")
    b = read(pipeline("base.txt.zst", `zstd -d`), String)
    println()
    println("# countall for a long string ($(sizeof(b)) bytes)")
    for a in ['.', '=', ".", "if", "for", "struct", "function", "baremodule", "abracadabra", "https://julialang.org/license"]
        short && sizeof(a) > 3 && continue
        char && !(a isa Char) && continue
        benchmark_countall(a, b)
    end
end

if isfile("chr1.txt.zst")
    b = read(pipeline("chr1.txt.zst", `zstd -d`), String)
    println()
    println("# countall for a low-complexity string ($(sizeof(b)) bytes)")
    for a in ['A', 'N', "A", "AAA", "TATA", "GAATTC", "CGTACGTAC", "GTTTTCCCCTC", "CCCCCCCCCCCCC", "XXXXXXXXXXXXXXXX"]
        short && sizeof(a) > 3 && continue
        char && !(a isa Char) && continue
        benchmark_countall(a, b)
    end
end