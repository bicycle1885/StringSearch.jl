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

function countall(findnext, a, b)
    n = 0
    r = findnext(a, b, firstindex(b))
    while r !== nothing
        n += 1
        r = findnext(a, b, first(r) + 1)
    end
    return n
end

function benchmark_countall(a, b)
    @assert countall(B.findnext, a, b) == countall(S.findnext, a, b)
    ss = @benchmark countall($S.findnext, $a, $b)
    base = @benchmark countall($B.findnext, $a, $b)
    report(a, ss, base, countall(B.findnext, a, b))
end

S.AVX2[] = get(ENV, "AVX2", "1") ≠ "0"
if S.use_avx2()
    @info "AVX2 is active"
else
    @info "AVX2 is not active"
end

@printf "%18s  %8s  %8s  %8s  %8s\n" "Query" "SS" "Base" "Ratio" "Result"

b = "abracadabra"
println()
println("# findfirst for a very short string ($(sizeof(b)) bytes)")
for a in ["c", "ca", "cad", "cada", "cadab", "cadabr", "cadabra"]
    benchmark_findfirst(a, b)
end

b = """
Julia is a high-level, high-performance dynamic language for technical computing. The main homepage for Julia can be found at julialang.org. This is the GitHub repository of Julia source code, including instructions for compiling and installing Julia, below.
"""
println()
println("# findfirst for a short string ($(sizeof(b)) bytes)")
for a in ["a", ".", "be", "language", "code", "Julia", "installing"]
    benchmark_findfirst(a, b)
end

if isfile("base.txt.zst")
    b = read(pipeline("base.txt.zst", `zstd -d`), String)
    println()
    println("# countall for a long string ($(sizeof(b)) bytes)")
    for a in [".", "if", "for", "end", "function", "baremodule", "https://julialang.org/license"]
        benchmark_countall(a, b)
    end
end

if isfile("chr1.txt.zst")
    b = read(pipeline("chr1.txt.zst", `zstd -d`), String)
    println()
    println("# countall for a low-complexity string ($(sizeof(b)) bytes)")
    for a in ["A", "AAA", "TATA", "GAATTC", "GTTTTCCCCTC", "CCCCCCCCCCCCC", "XXXXXXXXXXXXXXXX"]
        benchmark_countall(a, b)
    end
end