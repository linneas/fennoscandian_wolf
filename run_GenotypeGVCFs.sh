#!/bin/bash -l


GATK="$GATK_HOME/GenomeAnalysisTK.jar"


fasta=$1
list=$2
out=$3


echo "Start joint Genotyping..."
date

java -Xmx1000g -Djava.io.tmpdir=$TMP -jar $GATK -T GenotypeGVCFs -R $fasta --variant $list -nt 20 -o $out.tmp && mv $out.tmp $out

echo "Done!"
date


