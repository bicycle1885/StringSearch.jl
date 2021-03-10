using StringSearch
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
