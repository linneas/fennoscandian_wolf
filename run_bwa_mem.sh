#!/bin/bash -l

ref=$1
fq1=$2
fq2=$3
ind=$4
pref=$5

echo "Start mapping with bwa mem..."
date
bwa mem -R "@RG\tID:$ind\tSM:$ind\tLB:$ind\tPL:Illumina" -t 20 -M $ref $fq1 $fq2 |samtools sort -m 6G -@20 -T $TMP/$id - >$pref.bam.tmp && mv $pref.bam.tmp $pref.bam
echo  "Done!"
date
