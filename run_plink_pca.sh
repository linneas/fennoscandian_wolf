#!/bin/bash -l


plinkpref=$1
threads=$2
outpref=$3
plink2 --bfile $plinkpref --pca --chr-set 38 --threads $threads --out $outpref
