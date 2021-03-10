# StringSearch

**Work in Progress**

Accelerating exact string search with SIMD instructions written in pure Julia.

# Benchmarks

See benchmark.jl for details.
## Environment

    julia> versioninfo()
    Julia Version 1.6.0-rc1
    Commit a58bdd9010 (2021-02-06 15:49 UTC)
    Platform Info:
    OS: Linux (x86_64-pc-linux-gnu)
    CPU: AMD Ryzen 9 3950X 16-Core Processor
    WORD_SIZE: 64
    LIBM: libopenlibm
    LLVM: libLLVM-11.0.1 (ORCJIT, znver2)
    Environment:
    JULIA_PROJECT = @.

## SSE2

    findfirst for a very short string (11 bytes)
    a = "a" (result: 1:1)
    B  15.058 ns (0 allocations: 0 bytes)
    S  5.530 ns (0 allocations: 0 bytes)
    a = "cad" (result: 5:7)
    B  32.395 ns (2 allocations: 128 bytes)
    S  14.224 ns (0 allocations: 0 bytes)
    a = "dabra" (result: 7:11)
    B  35.424 ns (2 allocations: 128 bytes)
    S  18.681 ns (0 allocations: 0 bytes)

    findfirst for a short string (259 bytes)
    a = "a" (result: 5:5)
    B  14.014 ns (0 allocations: 0 bytes)
    S  5.520 ns (0 allocations: 0 bytes)
    a = "." (result: 81:81)
    B  16.152 ns (0 allocations: 0 bytes)
    S  6.492 ns (0 allocations: 0 bytes)
    a = "be" (result: 115:116)
    B  93.832 ns (2 allocations: 128 bytes)
    S  12.547 ns (0 allocations: 0 bytes)
    a = "language" (result: 49:56)
    B  44.093 ns (2 allocations: 128 bytes)
    S  10.510 ns (0 allocations: 0 bytes)
    a = "code" (result: 188:191)
    B  101.755 ns (2 allocations: 128 bytes)
    S  15.841 ns (0 allocations: 0 bytes)
    a = "Julia" (result: 1:5)
    B  30.550 ns (2 allocations: 128 bytes)
    S  7.210 ns (0 allocations: 0 bytes)
    a = "installing" (result: 235:244)
    B  95.464 ns (2 allocations: 128 bytes)
    S  22.834 ns (0 allocations: 0 bytes)

    countall for a long string (3320882 bytes)
    a = "." (result: 28950)
    B  711.017 μs (1 allocation: 16 bytes)
    S  456.609 μs (1 allocation: 16 bytes)
    a = "if" (result: 7775)
    B  2.659 ms (15553 allocations: 972.02 KiB)
    S  301.667 μs (1 allocation: 16 bytes)
    a = "for" (result: 4496)
    B  2.260 ms (8995 allocations: 562.14 KiB)
    S  291.979 μs (1 allocation: 16 bytes)
    a = "end" (result: 11843)
    B  2.453 ms (23689 allocations: 1.45 MiB)
    S  434.958 μs (1 allocation: 16 bytes)
    a = "function" (result: 4620)
    B  1.461 ms (9243 allocations: 577.64 KiB)
    S  303.120 μs (1 allocation: 16 bytes)
    a = "baremodule" (result: 16)
    B  1.126 ms (34 allocations: 2.12 KiB)
    S  202.240 μs (0 allocations: 0 bytes)
    a = "https://julialang.org/license" (result: 186)
    B  739.852 μs (374 allocations: 23.38 KiB)
    S  221.416 μs (0 allocations: 0 bytes)

## AVX2

    findfirst for a very short string (11 bytes)
    a = "a" (result: 1:1)
    B  13.512 ns (0 allocations: 0 bytes)
    S  5.330 ns (0 allocations: 0 bytes)
    a = "cad" (result: 5:7)
    B  31.307 ns (2 allocations: 128 bytes)
    S  13.090 ns (0 allocations: 0 bytes)
    a = "dabra" (result: 7:11)
    B  34.426 ns (2 allocations: 128 bytes)
    S  16.641 ns (0 allocations: 0 bytes)

    findfirst for a short string (259 bytes)
    a = "a" (result: 5:5)
    B  13.210 ns (0 allocations: 0 bytes)
    S  5.239 ns (0 allocations: 0 bytes)
    a = "." (result: 81:81)
    B  14.034 ns (0 allocations: 0 bytes)
    S  6.121 ns (0 allocations: 0 bytes)
    a = "be" (result: 115:116)
    B  89.950 ns (2 allocations: 128 bytes)
    S  8.986 ns (0 allocations: 0 bytes)
    a = "language" (result: 49:56)
    B  41.632 ns (2 allocations: 128 bytes)
    S  8.274 ns (0 allocations: 0 bytes)
    a = "code" (result: 188:191)
    B  97.560 ns (2 allocations: 128 bytes)
    S  10.591 ns (0 allocations: 0 bytes)
    a = "Julia" (result: 1:5)
    B  29.111 ns (2 allocations: 128 bytes)
    S  6.913 ns (0 allocations: 0 bytes)
    a = "installing" (result: 235:244)
    B  91.522 ns (2 allocations: 128 bytes)
    S  32.989 ns (0 allocations: 0 bytes)

    countall for a long string (3320882 bytes)
    a = "." (result: 28950)
    B  678.747 μs (1 allocation: 16 bytes)
    S  461.769 μs (1 allocation: 16 bytes)
    a = "if" (result: 7775)
    B  2.662 ms (15553 allocations: 972.02 KiB)
    S  224.493 μs (1 allocation: 16 bytes)
    a = "for" (result: 4496)
    B  2.268 ms (8995 allocations: 562.14 KiB)
    S  216.908 μs (1 allocation: 16 bytes)
    a = "end" (result: 11843)
    B  2.457 ms (23689 allocations: 1.45 MiB)
    S  365.688 μs (1 allocation: 16 bytes)
    a = "function" (result: 4620)
    B  1.462 ms (9243 allocations: 577.64 KiB)
    S  222.569 μs (1 allocation: 16 bytes)
    a = "baremodule" (result: 16)
    B  1.126 ms (34 allocations: 2.12 KiB)
    S  117.621 μs (0 allocations: 0 bytes)
    a = "https://julialang.org/license" (result: 186)
    B  739.361 μs (374 allocations: 23.38 KiB)
    S  138.360 μs (0 allocations: 0 bytes)
