#!/bin/bash -l

vcf=$1
rmsites=$2
outpref=$3

zcat $vcf |grep -v "#" |perl -ane '$homref=0; $het=0; $homalt=0; $missing=0; $other=0; for $f (@F[9..(scalar(@F)-1)]){@t=split(/:/,$f); if($t[0] eq "./.")	{$missing++}elsif($t[0] eq "0/0"){$homref++;}elsif($t[0] eq "0/1"){$het++;}elsif($t[0] eq "1/1"){$homalt++;}else{$other++;}}; if($het==0 || ($homref==0 && $homalt==0)){print $F[0]."\t".$F[1]."\n";}' >$rmsites

vcftools --gzvcf $vcf --out $outpref --exclude-positions $rmsites --recode --recode-INFO-all


