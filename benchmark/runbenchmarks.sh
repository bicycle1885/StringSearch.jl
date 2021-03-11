#!/usr/bin/env bash

set -eu
julia --version
for ext in avx2 noavx2; do
    for dir in forward backward; do
        summary=summary.$dir-$ext.txt
        echo -e "# -$ext -$dir\n" | tee $summary
        julia benchmark.jl -$dir -$ext | tee -a $summary
        echo "" | tee -a $summary
    done
done
cat summary.*.txt >summary.txt
julia -e 'using InteractiveUtils; println(); versioninfo()' >>summary.txt