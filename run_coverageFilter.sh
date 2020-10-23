#!/bin/bash -l

vcf=$1
mindepth=$2
maxdepth=$3
outpref=$4

vcftools --gzvcf $vcf --out $outpref --min-meanDP $mindepth --max-meanDP $maxdepth --recode --recode-INFO-all

