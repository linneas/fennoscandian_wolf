#!/bin/bash -l

plinkpref=$1
fam=$2
cutoff=$3
outpref=$4

plink --bfile $plinkpref --chr-set 38  --keep $fam --rel-cutoff $cutoff --make-bed -out $outpref


