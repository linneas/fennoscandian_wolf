#!/bin/bash -l

GATK="$GATK_HOME/GenomeAnalysisTK.jar"


fasta=$1
bam=$2
oprefix=$3


echo "Run haplotype caller on $bam..."
echo "Reference is $fasta"
date
java -Xmx120g -Djava.io.tmpdir=$SNIC_TMP -jar $GATK -T HaplotypeCaller -R $fasta -I $bam --emitRefConfidence GVCF --variant_index_type LINEAR --variant_index_parameter 128000 -nct 20 -jdk_deflater -jdk_inflater -o $oprefix.g.vcf.tmp.gz && mv $oprefix.g.vcf.tmp.gz $oprefix.g.vcf.gz && mv $oprefix.g.vcf.tmp.gz.tbi $oprefix.g.vcf.gz.tbi

echo "Done!"
date


