#!/bin/bash -l

vcf=$1
mac=$2
outpref=$3

vcftools --gzvcf $vcf --out $outpref --mac $mac --recode --recode-INFO-all

