#!/bin/bash -l
gzvcf=$1
outpref=$2

# Extract only known autosomes
vcftools --gzvcf $gzvcf --chr 1 --chr 2 --chr 3 --chr 4 --chr 5 --chr 6 --chr 7 --chr 8 --chr 9 --chr 10 --chr 11 --chr 12 --chr 13 --chr 14 --chr 15 --chr 16 --chr 17 --chr 18 --chr 19 --chr 20 --chr 21 --chr 22 --chr 23 --chr 24 --chr 25 --chr 26 --chr 27 --chr 28 --chr 29 --chr 30 --chr 31 --chr 32 --chr 33 --chr 34 --chr 35 --chr 36 --chr 37 --chr 38 --plink --out $outpref.chr1-38

