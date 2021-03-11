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

## Without AVX2 (SSE2)

```
             Query        SS      Base     Ratio    Result

# findfirst for a very short string (11 bytes)
               "c"    6.2 ns   14.1 ns     x2.26       5:5
              "ca"   16.2 ns   28.9 ns     x1.78       5:6
             "cad"   16.5 ns   32.8 ns     x1.99       5:7
            "cada"   19.2 ns   33.5 ns     x1.74       5:8
           "cadab"   17.3 ns   35.0 ns     x2.03       5:9
          "cadabr"   19.2 ns   36.1 ns     x1.87      5:10
         "cadabra"   19.8 ns   36.4 ns     x1.84      5:11

# findfirst for a short string (259 bytes)
               "a"    6.7 ns   14.0 ns     x2.09       5:5
               "."    7.4 ns   15.0 ns     x2.03     81:81
              "be"   15.7 ns   94.9 ns     x6.05   115:116
        "language"   12.3 ns   44.1 ns     x3.58     49:56
            "code"   20.6 ns  103.4 ns     x5.01   188:191
           "Julia"    8.5 ns   31.0 ns     x3.66       1:5
      "installing"   29.8 ns   97.3 ns     x3.27   235:244

# countall for a long string (3320882 bytes)
               "."  491.4 μs  725.9 μs     x1.48     28950
              "if"  359.6 μs    2.7 ms     x7.49      7775
             "for"  344.9 μs    2.3 ms     x6.63      4496
             "end"  517.3 μs    2.5 ms     x4.81     11843
        "function"  359.1 μs    1.5 ms     x4.11      4620
      "baremodule"  258.1 μs    1.1 ms     x4.41        16
"https://julialang.org/license"  276.2 μs  749.8 μs     x2.71       186

# countall for a low-complexity string (248956422 bytes)
               "A"  451.5 ms  967.6 ms     x2.14  67070277
             "AAA"  234.2 ms  870.0 ms     x3.71   8516543
            "TATA"  140.1 ms  514.1 ms     x3.67   1263092
          "GAATTC"  106.7 ms  398.6 ms     x3.74     67141
     "GTTTTCCCCTC"  111.8 ms  241.6 ms     x2.16       131
   "CCCCCCCCCCCCC"  107.3 ms  101.0 ms     x0.94       246
"XXXXXXXXXXXXXXXX"   20.5 ms   27.1 ms     x1.32         0
```

## With AVX2

```
             Query        SS      Base     Ratio    Result

# findfirst for a very short string (11 bytes)
               "c"    6.2 ns   13.5 ns     x2.20       5:5
              "ca"   14.3 ns   27.6 ns     x1.93       5:6
             "cad"   14.1 ns   31.5 ns     x2.24       5:7
            "cada"   16.5 ns   31.7 ns     x1.92       5:8
           "cadab"   16.5 ns   33.4 ns     x2.02       5:9
          "cadabr"   17.0 ns   34.5 ns     x2.03      5:10
         "cadabra"   15.2 ns   35.0 ns     x2.31      5:11

# findfirst for a short string (259 bytes)
               "a"    6.4 ns   13.4 ns     x2.10       5:5
               "."    6.8 ns   14.2 ns     x2.09     81:81
              "be"    9.6 ns   90.7 ns     x9.45   115:116
        "language"    8.8 ns   43.1 ns     x4.90     49:56
            "code"   11.8 ns   97.3 ns     x8.26   188:191
           "Julia"    7.5 ns   29.4 ns     x3.92       1:5
      "installing"   19.3 ns   91.8 ns     x4.76   235:244

# countall for a long string (3320882 bytes)
               "."  466.5 μs  678.4 μs     x1.45     28950
              "if"  215.7 μs    2.5 ms    x11.81      7775
             "for"  198.8 μs    2.2 ms    x10.88      4496
             "end"  341.1 μs    2.4 ms     x6.91     11843
        "function"  207.5 μs    1.4 ms     x6.71      4620
      "baremodule"  103.5 μs    1.1 ms    x10.41        16
"https://julialang.org/license"  126.3 μs  701.1 μs     x5.55       186

# countall for a low-complexity string (248956422 bytes)
               "A"  436.6 ms  922.2 ms     x2.11  67070277
             "AAA"  179.0 ms  838.2 ms     x4.68   8516543
            "TATA"   94.5 ms  497.4 ms     x5.26   1263092
          "GAATTC"   71.7 ms  384.7 ms     x5.36     67141
     "GTTTTCCCCTC"   71.9 ms  232.3 ms     x3.23       131
   "CCCCCCCCCCCCC"   78.5 ms   97.4 ms     x1.24       246
"XXXXXXXXXXXXXXXX"   14.5 ms   28.0 ms     x1.93         0
```