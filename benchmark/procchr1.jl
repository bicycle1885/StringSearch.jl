# http://hgdownload.soe.ucsc.edu/goldenPath/hg38/chromosomes/chr1.fa.gz

function preprocess(datafile)
    buf = IOBuffer()
    for line in eachline(pipeline(datafile, `gzip -d`))
        startswith(line, '>') && continue
        print(buf, uppercase(line))
    end
    return String(take!(buf))
end

sequence = preprocess("chr1.fa.gz")
mktemp() do path, file
    print(file, sequence)
    run(pipeline(path, `zstd`, "chr1.txt.zst"))
end
