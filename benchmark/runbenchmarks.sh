#!/usr/bin/env bash

julia --version
for ext in avx2 no-avx2; do
    for dir in forward backward; do
        julia benchmark.jl -$ext -$dir | tee summary.$ext-$dir.txt
    done
done