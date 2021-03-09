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
end
