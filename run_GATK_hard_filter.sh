#!/bin/bash -l

GATK="$GATK_HOME/GenomeAnalysisTK.jar"

ref=$1
vcf=$2
pref=$3

date
echo "Extract SNPs..."
java -Xmx60g -jar $GATK -T SelectVariants -R $ref -V $vcf -selectType SNP -o $pref.SNPs.vcf

date
echo "Apply filters..."
java -Xmx60g -jar $GATK -T VariantFiltration -R $ref -V $pref.SNPs.vcf --filterExpression "QD < 2.0 || FS > 60.0 || MQ < 40.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0" -o $pref.SNPs.HF.vcf.tmp
echo "Done!"
date

