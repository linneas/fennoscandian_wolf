#!/bin/bash -l

vcf=$1
out=$2

vcftools --gzvcf $vcf --stdout --depth >$out

