# StringSearch

Accelerated exact string search with SIMD instructions written in pure Julia.

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

## With AVX2

### Forward

```
             Query        SS      Base     Ratio    Result

# findfirst/last for a very short string (11 bytes)
               'a'    5.5 ns    9.4 ns     x1.69         1
               'd'    5.5 ns    9.4 ns     x1.69         7
               "c"    6.0 ns   14.8 ns     x2.46       5:5
              "ca"   14.8 ns   35.2 ns     x2.38       5:6
             "cad"   14.8 ns   38.6 ns     x2.60       5:7
            "cada"   17.9 ns   38.9 ns     x2.17       5:8
           "cadab"   18.9 ns   40.9 ns     x2.16       5:9
          "cadabr"   17.9 ns   41.6 ns     x2.33      5:10
         "cadabra"   18.1 ns   41.4 ns     x2.29      5:11
          "namnam"   18.0 ns   34.1 ns     x1.89   nothing

# findfirst/last for a short string (259 bytes)
               'a'    5.5 ns    9.4 ns     x1.69         5
               'G'    7.4 ns   10.7 ns     x1.45       154
               "a"    6.0 ns   14.0 ns     x2.32       5:5
              "be"   10.1 ns  102.0 ns    x10.11   115:116
             "the"   11.1 ns  103.7 ns     x9.35   150:152
            "code"   12.2 ns  109.7 ns     x9.02   188:191
           "Julia"    8.2 ns   36.3 ns     x4.44       1:5
        "language"    9.3 ns   50.0 ns     x5.35     49:56
      "installing"   21.3 ns  101.4 ns     x4.75   235:244
          "Python"   11.4 ns  103.6 ns     x9.06   nothing

# countall for a long string (3320882 bytes)
               '.'  515.0 μs  580.9 μs     x1.13     28950
               '='  659.6 μs  741.5 μs     x1.12     37374
               "."  471.0 μs  709.3 μs     x1.51     28950
              "if"  217.0 μs    2.6 ms    x12.18      7775
             "for"  203.9 μs    2.2 ms    x11.02      4496
          "struct"  214.4 μs    1.5 ms     x6.86       825
        "function"  209.8 μs    1.4 ms     x6.89      4620
      "baremodule"   99.0 μs    1.1 ms    x11.31        16
     "abracadabra"  143.5 μs  765.8 μs     x5.34         0
"https://julialang.org/license"  125.8 μs  734.6 μs     x5.84       186

# countall for a low-complexity string (248956422 bytes)
               'A'  619.2 ms  647.2 ms     x1.05  67070277
               'N'  175.3 ms  181.7 ms     x1.04  18475410
               "A"  429.7 ms  930.5 ms     x2.17  67070277
             "AAA"  183.4 ms  842.9 ms     x4.60   8516543
            "TATA"   97.4 ms  502.4 ms     x5.16   1263092
          "GAATTC"   69.3 ms  388.5 ms     x5.61     67141
       "CGTACGTAC"   79.7 ms  449.5 ms     x5.64        14
     "GTTTTCCCCTC"   74.3 ms  236.0 ms     x3.18       131
   "CCCCCCCCCCCCC"   81.4 ms   98.6 ms     x1.21       246
"XXXXXXXXXXXXXXXX"   13.4 ms   28.5 ms     x2.12         0

```

### Backward

```
             Query        SS      Base     Ratio    Result

# findfirst/last for a very short string (11 bytes)
               'a'    9.8 ns   10.4 ns     x1.06        11
               'd'   10.3 ns   10.6 ns     x1.03         7
               "c"   13.9 ns   15.6 ns     x1.12       5:5
              "ca"   20.1 ns   37.7 ns     x1.88       5:6
             "cad"   18.6 ns   42.0 ns     x2.26       5:7
            "cada"   18.0 ns   41.9 ns     x2.33       5:8
           "cadab"   16.0 ns   41.0 ns     x2.57       5:9
          "cadabr"   14.1 ns   39.8 ns     x2.82      5:10
         "cadabra"   13.9 ns   40.2 ns     x2.89      5:11
          "namnam"   21.4 ns   36.0 ns     x1.68   nothing

# findfirst/last for a short string (259 bytes)
               'a'    9.2 ns    9.7 ns     x1.06       250
               'G'   10.5 ns   10.8 ns     x1.03       154
               "a"   13.9 ns   14.1 ns     x1.02   250:250
              "be"   14.8 ns   37.6 ns     x2.54   253:254
             "the"   16.0 ns   91.6 ns     x5.74   150:152
            "code"   15.1 ns   64.6 ns     x4.28   188:191
           "Julia"   14.8 ns   45.8 ns     x3.09   246:250
        "language"   19.8 ns   98.8 ns     x4.98     49:56
      "installing"   14.8 ns   50.9 ns     x3.43   235:244
          "Python"   17.6 ns  126.4 ns     x7.20   nothing

# countall for a long string (3320882 bytes)
               '.'  560.9 μs  534.0 μs     x0.95     28950
               '='  709.6 μs  674.6 μs     x0.95     37374
               "."  657.8 μs  660.7 μs     x1.00     28950
              "if"  284.3 μs    3.3 ms    x11.60      7775
             "for"  248.5 μs    2.3 ms     x9.09      4496
          "struct"  235.2 μs    1.5 ms     x6.58       825
        "function"  258.7 μs    1.4 ms     x5.44      4620
      "baremodule"  138.1 μs  939.1 μs     x6.80        16
     "abracadabra"  170.0 μs  829.9 μs     x4.88         0
"https://julialang.org/license"  157.4 μs  626.6 μs     x3.98       186

# countall for a low-complexity string (248956422 bytes)
               'A'  659.3 ms  533.0 ms     x0.81  67070277
               'N'  190.7 ms  156.8 ms     x0.82  18475410
               "A"  807.2 ms  812.3 ms     x1.01  67070277
             "AAA"  239.1 ms  928.3 ms     x3.88   8516543
            "TATA"  110.1 ms  559.0 ms     x5.08   1263092
          "GAATTC"   72.7 ms  434.0 ms     x5.97     67141
       "CGTACGTAC"   79.8 ms  452.2 ms     x5.67        14
     "GTTTTCCCCTC"   78.1 ms  188.0 ms     x2.41       131
   "CCCCCCCCCCCCC"   81.5 ms   96.2 ms     x1.18       246
"XXXXXXXXXXXXXXXX"   14.0 ms   31.1 ms     x2.22         0

```

## Without AVX2 (SSE2)

### Forward

```
             Query        SS      Base     Ratio    Result

# findfirst/last for a very short string (11 bytes)
               'a'    5.6 ns    9.4 ns     x1.69         1
               'd'    5.6 ns    9.4 ns     x1.69         7
               "c"    6.1 ns   13.9 ns     x2.30       5:5
              "ca"   15.1 ns   28.7 ns     x1.90       5:6
             "cad"   15.1 ns   32.5 ns     x2.16       5:7
            "cada"   15.8 ns   33.1 ns     x2.10       5:8
           "cadab"   15.6 ns   34.9 ns     x2.24       5:9
          "cadabr"   15.8 ns   35.8 ns     x2.27      5:10
         "cadabra"   15.8 ns   35.8 ns     x2.27      5:11
          "namnam"   15.4 ns   27.7 ns     x1.80   nothing

# findfirst/last for a short string (259 bytes)
               'a'    5.6 ns    9.4 ns     x1.69         5
               'G'    7.5 ns   10.8 ns     x1.44       154
               "a"    6.0 ns   14.0 ns     x2.33       5:5
              "be"   13.2 ns   94.2 ns     x7.12   115:116
             "the"   14.5 ns   95.3 ns     x6.59   150:152
            "code"   16.3 ns  101.9 ns     x6.25   188:191
           "Julia"    8.0 ns   30.6 ns     x3.84       1:5
        "language"    9.9 ns   41.8 ns     x4.21     49:56
      "installing"   23.6 ns   90.9 ns     x3.86   235:244
          "Python"   15.0 ns   91.2 ns     x6.09   nothing

# countall for a long string (3320882 bytes)
               '.'  493.6 μs  556.6 μs     x1.13     28950
               '='  624.3 μs  706.8 μs     x1.13     37374
               "."  451.9 μs  668.7 μs     x1.48     28950
              "if"  257.2 μs    2.5 ms     x9.83      7775
             "for"  244.8 μs    2.1 ms     x8.77      4496
          "struct"  254.2 μs    1.4 ms     x5.51       825
        "function"  257.2 μs    1.4 ms     x5.38      4620
      "baremodule"  157.4 μs    1.1 ms     x6.80        16
     "abracadabra"  198.2 μs  727.3 μs     x3.67         0
"https://julialang.org/license"  179.0 μs  696.7 μs     x3.89       186

# countall for a low-complexity string (248956422 bytes)
               'A'  613.0 ms  640.6 ms     x1.04  67070277
               'N'  168.1 ms  174.9 ms     x1.04  18475410
               "A"  415.1 ms  899.7 ms     x2.17  67070277
             "AAA"  212.4 ms  816.5 ms     x3.84   8516543
            "TATA"  126.0 ms  482.6 ms     x3.83   1263092
          "GAATTC"   95.1 ms  373.9 ms     x3.93     67141
       "CGTACGTAC"  104.0 ms  430.0 ms     x4.14        14
     "GTTTTCCCCTC"   99.3 ms  226.3 ms     x2.28       131
   "CCCCCCCCCCCCC"  102.2 ms   94.3 ms     x0.92       246
"XXXXXXXXXXXXXXXX"   15.6 ms   27.2 ms     x1.75         0
```

### Backrward

```
             Query        SS      Base     Ratio    Result

# findfirst/last for a very short string (11 bytes)
               'a'    9.8 ns   10.4 ns     x1.05        11
               'd'   10.2 ns   10.5 ns     x1.03         7
               "c"   14.0 ns   15.3 ns     x1.10       5:5
              "ca"   19.5 ns   37.8 ns     x1.94       5:6
             "cad"   17.9 ns   40.6 ns     x2.27       5:7
            "cada"   16.5 ns   41.0 ns     x2.49       5:8
           "cadab"   15.1 ns   40.4 ns     x2.67       5:9
          "cadabr"   14.1 ns   39.7 ns     x2.81      5:10
         "cadabra"   13.9 ns   40.1 ns     x2.88      5:11
          "namnam"   18.7 ns   36.0 ns     x1.92   nothing

# findfirst/last for a short string (259 bytes)
               'a'    9.2 ns    9.7 ns     x1.05       250
               'G'   10.4 ns   10.8 ns     x1.04       154
               "a"   14.0 ns   14.3 ns     x1.03   250:250
              "be"   15.3 ns   37.5 ns     x2.44   253:254
             "the"   17.2 ns   91.6 ns     x5.33   150:152
            "code"   16.0 ns   64.2 ns     x4.02   188:191
           "Julia"   15.3 ns   43.5 ns     x2.85   246:250
        "language"   23.3 ns   99.3 ns     x4.27     49:56
      "installing"   15.3 ns   50.2 ns     x3.28   235:244
          "Python"   23.3 ns  125.6 ns     x5.40   nothing

# countall for a long string (3320882 bytes)
               '.'  561.3 μs  533.8 μs     x0.95     28950
               '='  709.8 μs  673.0 μs     x0.95     37374
               "."  659.6 μs  660.4 μs     x1.00     28950
              "if"  344.0 μs    3.3 ms     x9.57      7775
             "for"  313.0 μs    2.3 ms     x7.21      4496
          "struct"  298.4 μs    1.5 ms     x5.19       825
        "function"  319.1 μs    1.4 ms     x4.41      4620
      "baremodule"  207.7 μs  939.1 μs     x4.52        16
     "abracadabra"  243.5 μs  828.8 μs     x3.40         0
"https://julialang.org/license"  226.6 μs  629.9 μs     x2.78       186

# countall for a low-complexity string (248956422 bytes)
               'A'  657.2 ms  532.8 ms     x0.81  67070277
               'N'  190.4 ms  156.5 ms     x0.82  18475410
               "A"  806.6 ms  811.1 ms     x1.01  67070277
             "AAA"  278.2 ms  935.4 ms     x3.36   8516543
            "TATA"  145.9 ms  560.2 ms     x3.84   1263092
          "GAATTC"  103.0 ms  456.1 ms     x4.43     67141
       "CGTACGTAC"  113.1 ms  473.9 ms     x4.19        14
     "GTTTTCCCCTC"  107.9 ms  197.6 ms     x1.83       131
   "CCCCCCCCCCCCC"  112.5 ms  100.6 ms     x0.89       246
"XXXXXXXXXXXXXXXX"   17.9 ms   32.5 ms     x1.82         0
```