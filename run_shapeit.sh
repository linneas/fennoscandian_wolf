#!/bin/bash -l

vcf=$1
Ne=$2
chr=$3
map=$4
options=$5
out=$6


shapeit4 --effective-size "${Ne}" --input "${vcf}" --map "${map}" $options --region "${chr}" --output "${out}"


