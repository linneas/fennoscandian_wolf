#!/bin/bash -l

PICARD="/path_to_picard/picard.jar"


ind=$1
prefix=$2

echo "Start Mark duplicates..."
date
java -Xmx60g -jar $PICARD MarkDuplicates INPUT=$prefix.bam METRICS_FILE=$ind.metrics TMP_DIR=$SNIC_TMP ASSUME_SORTED=true VALIDATION_STRINGENCY=LENIENT CREATE_INDEX=TRUE OUTPUT=$prefix.md.bam.tmp && mv $prefix.md.bam.tmp $prefix.md.bam && mv $prefix.md.bam.tmp.bai $prefix.md.bam.bai
echo "done" 
date

