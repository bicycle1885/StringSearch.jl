using BenchmarkTools
using StringSearch
const B = Base
const S = StringSearch

b = "abracadabra"
println("findfirst for a very short string ($(sizeof(b)) bytes)")
for a in ["a", "cad", "dabra"]
    @assert B.findfirst(a, b) == S.findfirst(a, b)
    println("a = $(repr(a)) (result: $(S.findfirst(a, b)))")
    print("  B"); @btime B.findfirst($a, $b)
    print("  S"); @btime S.findfirst($a, $b)
end
println()

b = """
Julia is a high-level, high-performance dynamic language for technical computing. The main homepage for Julia can be found at julialang.org. This is the GitHub repository of Julia source code, including instructions for compiling and installing Julia, below.
"""
println("findfirst for a short string ($(sizeof(b)) bytes)")
for a in ["a", ".", "be", "language", "code", "Julia", "installing"]
    @assert B.findfirst(a, b) == S.findfirst(a, b)
    println("a = $(repr(a)) (result: $(S.findfirst(a, b)))")
    print("  B"); @btime B.findfirst($a, $b)
    print("  S"); @btime S.findfirst($a, $b)
end
println()

function countall(findnext, a, b)
    n = 0
    r = findnext(a, b, firstindex(b))
    while r !== nothing
        n += 1
        r = findnext(a, b, first(r) + 1)
    end
    return n
end
b = read(pipeline("test/base.txt.zst", `zstd -d`), String)
println("countall for a long string ($(sizeof(b)) bytes)")
for a in [".", "if", "for", "end", "function", "baremodule", "https://julialang.org/license"]
    @assert countall(B.findnext, a, b) == countall(S.findnext, a, b)
    println("a = $(repr(a)) (result: $(countall(S.findnext, a, b)))")
    print("  B"); @btime countall($B.findnext, $a, $b)
    print("  S"); @btime countall($S.findnext, $a, $b)
end