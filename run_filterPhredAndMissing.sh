#!/bin/bash -l

vcf=$1
GQ=$2
maxmiss=$3
outpref=$4

vcftools --gzvcf $vcf --out $outpref --minGQ $GQ --max-missing $maxmiss --recode --recode-INFO-all

