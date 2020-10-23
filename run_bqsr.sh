#!/bin/bash -l


GATK="$GATK_HOME/GenomeAnalysisTK.jar"


ref=$1
vcf=$2
vcf2=$3
prefix=$4

echo "Making first recalibration table..."
date
java -Xmx120g -Djava.io.tmpdir="$TMP" -jar "$GATK" -T BaseRecalibrator -l INFO -R "$ref" -I "$prefix.bam" -knownSites "$vcf" -knownSites "$vcf2" -nct 20 -o "$prefix.recal.table.tmp" && mv "$prefix.recal.table.tmp" "$prefix.recal.table"
echo "Done making recalibration table!"

echo "Recalibrating files.."
date
 java -Xmx120g -Djava.io.tmpdir="$TMP" -jar "$GATK" -T PrintReads -R "$ref" -I "$prefix.bam" --BQSR "$prefix.recal.table" -o "$prefix.recal.bam.tmp" && mv "$prefix.recal.bam.tmp" "$prefix.recal.bam" && mv "$prefix.recal.bam.tmp.bai" "$prefix.recal.bam.bai"
echo "Done recalibrating files!"
date

