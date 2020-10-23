#!/bin/bash -l

settings=$1

mkdir -p $settings

mv chr*bed.txt $settings/

# # # # For plotting
for ind in $(cat Admix.list)
do
 for hap in "A" "B"
 do
  rm -f $ind.$settings.merged.$hap.bed
  for chr in {1..38}
  do 
   awk '(NR>1){if(NR==2){s=$2}else{if($7!=last){print chr"\t"s"\t"e"\t"last; s=$2}}; e=$3; chr=$1; last=$7}END{print chr"\t"s"\t"e"\t"last}' $settings/chr"$chr"_"$ind"_$hap.bed.txt >>$ind.$settings.merged.$hap.bed
  done
 done
done

# Dog stats from the merged files
rm -f $settings.dog.summary
for ind in $(cat Admix.list)
 do
  dogf=`awk '{if($4=="DOG"){dogsum+=$3-$2+1}else if($4=="DOG*"){doguncert+=$3-$2+1}; sum+=$3-$2+1}END{dr=dogsum/sum; dur=doguncert/sum; print dr"\t"dur"\t"sum}' $ind.$settings.merged.*.bed`
  echo $ind" "$dogf | sed 's/ /\t/g'
 done >>$settings.dog.summary

