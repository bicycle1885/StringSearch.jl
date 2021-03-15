using StringSearch: StringSearch, findfirst, findnext, findlast, findprev, occursin
using Test

@testset "StringSearch.jl" begin
    b = "abracadabra"  # 11 bytes

    @test findfirst('a', b) == 1
    @test findfirst('b', b) == 2
    @test findfirst('c', b) == 5
    @test findfirst('z', b) === nothing

    @test findfirst(==('a'), b) == 1
    @test findfirst(==('b'), b) == 2
    @test findfirst(==('c'), b) == 5
    @test findfirst(==('z'), b) === nothing

    @test invoke(findfirst, Tuple{Function, AbstractString}, isequal('b'), "abc") == 2
    @test invoke(findnext, Tuple{Function, AbstractString, Int}, isequal('b'), "abc", 1) == 2
    @test invoke(findnext, Tuple{Function, AbstractString, Int}, isequal('z'), "abc", 1) === nothing

    @test findfirst(GenericString(""), GenericString(b)) == 1:0
    @test findfirst(GenericString("ab"), GenericString(b)) == 1:2
    @test findfirst(GenericString("abra"), GenericString(b)) == 1:4
    @test findfirst(GenericString("cad"), GenericString(b)) == 5:7
    @test findfirst(GenericString("foo"), GenericString(b)) === nothing

    @test findfirst("", b) == 1:0
    @test findfirst("a", b) == 1:1
    @test findfirst("b", b) == 2:2
    @test findfirst("r", b) == 3:3
    @test findfirst("ra", b) == 3:4
    @test findfirst("abra", b) == 1:4
    @test findfirst("abracadabra", b) == 1:11
    @test findnext("abra", b, 1) == 1:4
    @test findnext("abra", b, 2) == 8:11

    @test findlast('a', b) == 11
    @test findlast('b', b) == 9
    @test findlast('c', b) == 5
    @test findlast('z', b) === nothing

    @test findlast(==('a'), b) == 11
    @test findlast(==('b'), b) == 9
    @test findlast(==('c'), b) == 5
    @test findlast(==('z'), b) === nothing

    @test invoke(findlast, Tuple{Function, AbstractString}, isequal('b'), "abc") == 2
    @test invoke(findprev, Tuple{Function, AbstractString, Int}, isequal('b'), "abc", 3) == 2
    @test invoke(findprev, Tuple{Function, AbstractString, Int}, isequal('z'), "abc", 3) === nothing

    @test findlast(GenericString(""), GenericString(b)) == 11:10
    @test findlast(GenericString("ab"), GenericString(b)) == 8:9
    @test findlast(GenericString("abra"), GenericString(b)) == 8:11
    @test findlast(GenericString("cad"), GenericString(b)) == 5:7
    @test findlast(GenericString("foo"), GenericString(b)) === nothing

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
        @test findlast(a, b) == Base.findlast(a, b)
    end

    b = "Julia言語"

    @test findfirst(==('J'), b) === 1
    @test findfirst(==('u'), b) === 2
    @test findfirst(==('言'), b) === 6
    @test findfirst(==('語'), b) === 9

    @test findfirst("Julia", b) === 1:5
    @test findnext("Julia", b, 2) === nothing
    @test findfirst("言語", b) === 6:9
    @test findnext("言語", b, 2) === 6:9
    @test findnext("言語", b, 6) === 6:9
    @test findnext("言語", b, 7) === nothing

    @test findlast(==('J'), b) === 1
    @test findlast(==('u'), b) === 2
    @test findlast(==('言'), b) === 6
    @test findlast(==('語'), b) === 9

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

    @test findlast("", "a") === 2:1

    for b in ["αβ", GenericString("αβ")]  # 4 bytes in UTF-8
        @test findnext("", b, -1) === 1:0
        @test findnext("", b, 0) === 1:0
        @test findnext("", b, 1) === 1:0
        @test findnext("", b, 2) === 3:2
        @test findnext("", b, 3) === 3:2
        @test findnext("", b, 4) === 5:4
        @test findnext("", b, 5) === 5:4
        @test findnext("", b, 6) === nothing
        @test findprev("", b, -1) === nothing
        @test findprev("", b, 0) === 1:0
        @test findprev("", b, 1) === 1:0
        @test findprev("", b, 2) === 3:2
        @test findprev("", b, 3) === 3:2
        @test findprev("", b, 4) === 5:4
        @test findprev("", b, 5) === 5:4
        @test findprev("", b, 6) === 5:4
        @test findfirst("", b) === 1:0
        @test findlast("", b) === 5:4
    end

    function findall_forward(a, b)
        rs = UnitRange{Int}[]
        r = findfirst(a, b)
        while r !== nothing
            push!(rs, r)
            r = findnext(a, b, first(r) + 1)
        end
        return rs
    end
    function findall_backward(a, b)
        rs = UnitRange{Int}[]
        r = findlast(a, b)
        while r !== nothing
            push!(rs, r)
            r = findprev(a, b, last(r) - 1)
        end
        return rs
    end
    rsf = findall_forward("", "αβγ")
    rsb = reverse(findall_backward("", "αβγ"))
    @test length(rsf) == length(rsb) && all(r1 === r2 for (r1, r2) in zip(rsf, rsb))

    @test findnext("≠", "≠    ", 2) === nothing
    @test findnext(" ≠", "≠    ", 2) === nothing

    a = "ab"
    b = a ^ 100
    for i in 1:199
        @test findnext(a, b, i) == ifelse(iseven(i), i+1:i+2, i:i+1)
    end
    @test findnext(a, b, 200) === nothing
    for i in 200:-1:2
        @test findprev(a, b, i) == ifelse(iseven(i), i-1:i, i-2:i-1)
    end
    @test findprev(a, b, 1) === nothing

    b = [0x00, 0x01, 0x02, 0x03]
    @test findfirst(isequal(0x00), b) == 1
    @test findfirst(isequal(0x03), b) == 4
    @test findfirst([0x00, 0x01, 0x02], b) == 1:3
    @test findfirst([0x01, 0x02, 0x03], b) == 2:4
    @test findlast(isequal(0x00), b) == 1
    @test findlast(isequal(0x03), b) == 4
    @test findlast([0x00, 0x01, 0x02], b) == 1:3
    @test findlast([0x01, 0x02, 0x03], b) == 2:4

    b = [0xff] 
    @test findfirst(isequal(Int8(-1)), b) === nothing
    @test findlast(isequal(Int8(-1)), b) === nothing

    b = [Int8(-1)]
    @test findfirst(isequal(0xff), b) === nothing
    @test findlast(isequal(0xff), b) === nothing

    f0(x) = isequal(x, 0x00)
    f4(x) = isequal(x, 0x04)
    b = [0x00, 0x01, 0x02, 0x03]
    @test findfirst(f0, b) == 1
    @test findfirst(f4, b) === nothing
    @test findlast(f0, b) == 1
    @test findlast(f4, b) === nothing

    b = GenericArray([0x00, 0x01, 0x02, 0x03])
    @test findfirst([0x00], b) == 1:1
    @test findfirst([0x03], b) == 4:4
    @test findfirst([0x01, 0x02], b) == 2:3
    @test findfirst([0x03, 0x04], b) === nothing
    @test findlast([0x00], b) == 1:1
    @test findlast([0x03], b) == 4:4
    @test findlast([0x01, 0x02], b) == 2:3
    @test findlast([0x03, 0x04], b) === nothing

    b = "abracadabra"
    @test occursin('a', b)
    @test occursin('r', b)
    @test !occursin('z', b)
    @test occursin("abra", b)
    @test occursin("cad", b)
    @test !occursin("cas", b)
end

@testset "Base tests" begin
    include("search.jl")
end