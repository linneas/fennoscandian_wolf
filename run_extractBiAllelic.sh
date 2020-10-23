#!/bin/bash -l

vcf=$1
outpref=$2

vcftools --gzvcf $vcf --out $outpref --max-alleles 2 --recode --recode-INFO-all

