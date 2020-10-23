#!/bin/bash -l

gzvcf=$1
pval=$2
out1=$3
out2=$4


echo "Calc Hardy Weinberg p-values"
date
vcftools --gzvcf $gzvcf --hardy --out $out1

echo "make a list of not wanted sites"
date
awk -v p=$pval '($8<p){print $1"\t"$2}' $out1.hwe >$out1.hwe$pval.notwanted.pos

echo "make a new vcf file"
date
vcftools --gzvcf $gzvcf --exclude-positions $out1.hwe$pval.notwanted.pos --out $out2 --recode --recode-INFO-all
date

