using StringSearch: StringSearch, findfirst, findnext, findlast, findprev
using Test

@testset "StringSearch.jl" begin
    b = "abracadabra"  # 11 bytes
    @test findfirst("", b) == 1:0
    @test findfirst("a", b) == 1:1
    @test findfirst("b", b) == 2:2
    @test findfirst("r", b) == 3:3
    @test findfirst("ra", b) == 3:4
    @test findfirst("abra", b) == 1:4
    @test findfirst("abracadabra", b) == 1:11
    @test findnext("abra", b, 1) == 1:4
    @test findnext("abra", b, 2) == 8:11

    @test findlast("a", b) == 11:11
    @test findlast("abra", b) == 8:11
    @test findlast("da", b) == 7:8
    @test findprev("da", b, 9) == 7:8
    @test findprev("da", b, 8) == 7:8
    @test findprev("da", b, 7) === nothing

    b = "abracadabraabracadabra"  # 22 bytes
    @test findfirst("", b) == 1:0
    @test findfirst("a", b) == 1:1
    @test findfirst("b", b) == 2:2
    @test findfirst("r", b) == 3:3
    @test findfirst("ra", b) == 3:4
    @test findfirst("abra", b) == 1:4
    @test findfirst("abracadabra", b) == 1:11
    @test findnext("abra", b, 1) == 1:4
    @test findnext("abra", b, 2) == 8:11

    @test findlast("a", b) == 22:22
    @test findlast("abra", b) == 19:22
    @test findlast("da", b) == 18:19
    @test findprev("a", b, 22) == 22:22
    @test findprev("a", b, 21) == 19:19
    @test findprev("abra", b, 21) == 12:15
    @test findprev("da", b, 22) == 18:19
    @test findprev("da", b, 19) == 18:19
    @test findprev("da", b, 18) == 7:8

    b = """
    Julia is a high-level, high-performance dynamic language for technical computing. The main homepage for Julia can be found at julialang.org. This is the GitHub repository of Julia source code, including instructions for compiling and installing Julia, below.
    """
    for a in ["a", ".", "be", "language", "code", "Julia", "installing"]
        @test findfirst(a, b) == Base.findfirst(a, b)
    end

    b = "Julia言語"
    @test findfirst("Julia", b) === 1:5
    @test findnext("Julia", b, 2) === nothing
    @test findfirst("言語", b) === 6:9
    @test findnext("言語", b, 2) === 6:9
    @test findnext("言語", b, 6) === 6:9
    @test findnext("言語", b, 7) === nothing

    @test findlast("Julia", b) === 1:5
    @test findlast("言語", b) === 6:9
    @test findprev("言語", b, 10) === 6:9
    @test findprev("言語", b, 9) === 6:9
    @test findprev("言語", b, 8) === nothing

    @test findfirst("a", "") === nothing
    @test findfirst("aa", "a") === nothing
    @test findfirst("aaa", "aa") === nothing

    @test findlast("a", "") === nothing
    @test findlast("aa", "a") === nothing
    @test findlast("aaa", "aa") === nothing

    @test findfirst("", "") === 1:0
    @test findnext("", "", -1) === 1:0
    @test findnext("", "", 0) === 1:0
    @test findnext("", "", 1) === 1:0
    @test findnext("", "", 2) === nothing
    @test findnext("", "", 3) === nothing

    @test findlast("", "") === 1:0
    @test findprev("", "", -2) === nothing
    @test findprev("", "", -1) === nothing
    @test findprev("", "", 0) === 1:0
    @test findprev("", "", 1) === 1:0
    @test findprev("", "", 2) === 1:0

    @test findfirst("", "a") === 1:0
    @test findnext("", "a", -1) === 1:0
    @test findnext("", "a", 0) === 1:0
    @test findnext("", "a", 1) === 1:0
    @test findnext("", "a", 2) === 2:1
    @test findnext("", "a", 3) === nothing

    @test findlast("", "a") === 1:0

    @test findnext("≠", "≠    ", 2) === nothing
    @test findnext(" ≠", "≠    ", 2) === nothing

    a = "ab"
    b = a ^ 100
    for i in 1:199
        @test findnext(a, b, i) == ifelse(iseven(i), i+1:i+2, i:i+1)
    end
    @test findnext(a, b, 200) === nothing
    for i in 200:2
        @test findprev(a, b, i) == ifelse(iseven(i), i-1:i, i:i-1)
    end
    @test findprev(a, b, 1) === nothing
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