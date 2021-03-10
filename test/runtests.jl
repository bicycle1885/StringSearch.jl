using StringSearch: StringSearch, findfirst, findnext
using Test

const SS = StringSearch

@testset "StringSearch.jl" begin
    b = "abracadabra"  # 11 bytes
    @test SS.findfirst("", b) == 1:0
    @test SS.findfirst("a", b) == 1:1
    @test SS.findfirst("b", b) == 2:2
    @test SS.findfirst("r", b) == 3:3
    @test SS.findfirst("ra", b) == 3:4
    @test SS.findfirst("abra", b) == 1:4
    @test SS.findfirst("abracadabra", b) == 1:11
    @test SS.findnext("abra", b, 1) == 1:4
    @test SS.findnext("abra", b, 2) == 8:11

    b = "abracadabraabracadabra"  # 22 bytes
    @test SS.findfirst("", b) == 1:0
    @test SS.findfirst("a", b) == 1:1
    @test SS.findfirst("b", b) == 2:2
    @test SS.findfirst("r", b) == 3:3
    @test SS.findfirst("ra", b) == 3:4
    @test SS.findfirst("abra", b) == 1:4
    @test SS.findfirst("abracadabra", b) == 1:11
    @test SS.findnext("abra", b, 1) == 1:4
    @test SS.findnext("abra", b, 2) == 8:11

    b = """
    Julia is a high-level, high-performance dynamic language for technical computing. The main homepage for Julia can be found at julialang.org. This is the GitHub repository of Julia source code, including instructions for compiling and installing Julia, below.
    """
    for a in ["a", ".", "be", "language", "code", "Julia", "installing"]
        @test SS.findfirst(a, b) == Base.findfirst(a, b)
    end

    @test SS.findfirst("Julia", "Julia言語") === 1:5
    @test SS.findnext("Julia", "Julia言語", 2) === nothing
    @test SS.findfirst("言語", "Julia言語") === 6:9
    @test SS.findnext("言語", "Julia言語", 2) === 6:9
    @test SS.findnext("言語", "Julia言語", 6) === 6:9
    @test SS.findnext("言語", "Julia言語", 7) === nothing

    @test SS.findfirst("", "") === 1:0
    @test SS.findnext("", "", -1) === 1:0
    @test SS.findnext("", "", 0) === 1:0
    @test SS.findnext("", "", 1) === 1:0
    @test SS.findnext("", "", 2) === nothing
    @test SS.findnext("", "", 3) === nothing

    @test SS.findfirst("", "a") === 1:0
    @test SS.findnext("", "a", -1) === 1:0
    @test SS.findnext("", "a", 0) === 1:0
    @test SS.findnext("", "a", 1) === 1:0
    @test SS.findnext("", "a", 2) === 2:1
    @test SS.findnext("", "a", 3) === nothing
end

@testset "Base tests" begin
    # Taken from: https://github.com/JuliaLang/julia/blob/b4c79e76fb699cf67d0e6b14ecfa75b1aaca923f/test/strings/search.jl
    # License is MIT: https://julialang.org/license

    # string forward search with a two-char string literal
    @test findfirst("xx", "foo,bar,baz") == nothing
    @test findfirst("fo", "foo,bar,baz") == 1:2
    @test findnext("fo", "foo,bar,baz", 3) == nothing
    @test findfirst("oo", "foo,bar,baz") == 2:3
    @test findnext("oo", "foo,bar,baz", 4) == nothing
    @test findfirst("o,", "foo,bar,baz") == 3:4
    @test findnext("o,", "foo,bar,baz", 5) == nothing
    @test findfirst(",b", "foo,bar,baz") == 4:5
    @test findnext(",b", "foo,bar,baz", 6) == 8:9
    @test findnext(",b", "foo,bar,baz", 10) == nothing
    @test findfirst("az", "foo,bar,baz") == 10:11
    @test findnext("az", "foo,bar,baz", 12) == nothing

    # issue #9365
    # string forward search with a two-char UTF-8 (2 byte) string literal
    @test findfirst("éé", "ééé") == 1:3
    @test findnext("éé", "ééé", 1) == 1:3
    # string forward search with a two-char UTF-8 (3 byte) string literal
    @test findfirst("€€", "€€€") == 1:4
    @test findnext("€€", "€€€", 1) == 1:4
    # string forward search with a two-char UTF-8 (4 byte) string literal
    @test findfirst("\U1f596\U1f596", "\U1f596\U1f596\U1f596") == 1:5
    @test findnext("\U1f596\U1f596", "\U1f596\U1f596\U1f596", 1) == 1:5

    # string forward search with a two-char UTF-8 (2 byte) string literal
    @test findfirst("éé", "éé") == 1:3
    @test findnext("éé", "éé", 1) == 1:3
    # string forward search with a two-char UTF-8 (3 byte) string literal
    @test findfirst("€€", "€€") == 1:4
    @test findnext("€€", "€€", 1) == 1:4
    # string forward search with a two-char UTF-8 (4 byte) string literal
    @test findfirst("\U1f596\U1f596", "\U1f596\U1f596") == 1:5
    @test findnext("\U1f596\U1f596", "\U1f596\U1f596", 1) == 1:5
end