#!/bin/bash -l

gzvcf=$1
chr=$2
positions=$3
other=$4

# Create input files for PCAdmix

for pop in "Wolf" "Dog" "Admix"
do
 vcftools --gzvcf $gzvcf --chr $chr --positions $positions --keep $pop.list $other --IMPUTE --out $pop.$chr
 cat $pop.$chr.impute.hap.indv |cut -f1 -d" " |awk -v head="" '{head=head" "$i"_A "$i"_B"}END{print "I rsID"head}' >$pop.$chr.header
 tail -n+2 $pop.$chr.impute.legend |paste - $pop.$chr.impute.hap -d" " |awk '{for(i=5;i<=NF; i++){if($i==0){$i=$3}else{$i=$4}}; print}' |cut -f1,5- -d" " |awk '{print "M "$0}'|cat $pop.$chr.header - >$pop.$chr.txt
done

tail -n+2 $pop.$chr.impute.legend |awk -v c=$chr '{print c" "$1" 0 "$2}' >chr$chr.map

