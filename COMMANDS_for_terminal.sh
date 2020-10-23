# BASH COMMANDS FOR THE MANUSCRIPT 
#"Whole-genome analyses show limited signs of dog introgression in the Fennoscandian wolf populations"

# NOTE THAT MOST PROGRAMS ARE RUN AS BATCH JOBS SUBMITTED TO A CLUSTER USING SLURM
# (settings as number of nodes, requested time and memory are customized and needs to be tested/tweaked if run on other systems)


###################### SNP CALLING AND FILTERING ###############################

# Reference fasta:
fasta="reference/Canis_familiaris.CanFam3.1.dna.toplevel.fa"


# MAP & MARK DUPLICATE 
for ind in $(cat all_individuals.txt)
do
 R1="fastq/"$id"_1.fastq.gz"
 R2="fastq/"$id"_2.fastq.gz" 
 bampref="bam/$ind"
 map=$(sbatch -J bwa.$ind -t 1-00:00:00 -p node -n 20 run_bwa_mem.sh $fasta $R1 $R2 $ind $bampref |cut -f4 -d" ")
 sbatch -J mkdup.$ind -d afterok:$map -n 10 -t 1-00:00:00 -p core run_mkdupl.sh $ind $bampref
done

# BASE RECALIBRATE NEW SAMPLES
vcf1="SNPs.Kardos.vcf.gz"
vcf2="dogs.557.publicSamples.ann.chrAll.PASS.vcf.gz"
for ind in $(cat new_individuals.txt)
do
 bampref="bam/$ind.md"
 sbatch -J bqsr.$ind -t 1-00:00:00 -p node -n 20 run_bqsr.sh $fasta $vcf1 $vcf2 $bampref
done

# HAPLOTYPECALLER 
for bam in $(cat all_bamfiles.txt)
do
 ind=`echo $bam |cut -f2 -d"/" |cut -f1 -d"."`
 vcfpref="gvcf/$ind"
 sbatch -J hc.$ind -p node -n20 -t 1-00:00:00 -p core run_haplotypeCaller.sh $fasta $bam $vcfpref.hc 
done

# JOINT GENOTYPING
prefix="AllInd"
out="vcf/$prefix.vcf"
in="$prefix.gvcf.list"
joint=$(sbatch -J JointGenotyping -t 7-00:00:00 -C mem1TB -p node -n20 run_GenotypeGVCFs.sh $fasta $in $out |cut -f4 -d" ")
sbatch -J tabix -d afterok:$joint -t 3-00:00:00 -p core run_zip_and_tabix.sh $out



# EXTRACT ONLY SNPs and USE GATKs HARD FILTER
in="vcf/$prefix.vcf.gz"
outpref="vcf/$prefix"
filt=$(sbatch -J SNPHardFilt.$prefix -t 5-00:00:00 -p core -n10 run_GATK_hard_filter.sh $ref $in $outpref |cut -f4 -d" ")
sbatch -J tabixSNP -d afterok:$filt -t 1-00:00:00 -p core run_zip_and_tabix.sh $outpref.SNPs.vcf
sbatch -J tabixHF -d afterok:$filt -t 1-00:00:00 -p core run_zip_and_tabix.sh $outpref.SNPs.HF.vcf


# SAVE ONLY BIALLELIC
in="vcf/$prefix.SNPs.HF.vcf.gz"
outp="vcf/$prefix.SNPs.HF.Bi"
biall=$(sbatch -J biall -t 2-00:00:00 -p core run_extractBiAllelic.sh $in $outp |cut -f4 -d" ")
sbatch -J tabixBiAll -d afterok:$biall -t 1-00:00:00 -p core run_zip_and_tabix.sh $outp.recode.vcf


# REMOVE LOCI WITH ONLY HET OR HOM CALLS
in="vcf/$prefix.SNPs.HF.Bi.recode.vcf.gz"
outp="vcf/$prefix.SNPs.HF.Bi.HH"
remove="$prefix.OnlyHomOrHet.txt"
rmhomhet=$(sbatch -J rmHomHet -t 2-00:00:00 -p core run_removeOnlyHomOrHet.sh $in $remove $outp |cut -f4 -d" ")
sbatch -J tabixrmHomHet -d afterok:$rmhomhet -t 1-00:00:00 -p core run_zip_and_tabix.sh $outp.recode.vcf


# FILTER FOR COVERAGE
sbatch -J CheckCov -t 10:00:00 -p core $scrdir/run_coverageFromVCF.sh $prefix.vcf.gz $prefix.vcf.idepth
# Check the average mean depth:
awk '(NR>1){n++; sum+=$3}END{mean=sum/n; print mean}' $prefix.vcf.idepth 
#24.7207
maxmeandepth=49.4414
minmeandepth=10
in="../vcf/$prefix.SNPs.HF.Bi.HH.recode.vcf.gz"
outp="../vcf/$prefix.SNPs.HF.Bi.HH.DP"
depth=$(sbatch -J depth -t 2-00:00:00 -p core run_coverageFilter.sh $in $minmeandepth $maxmeandepth $outp |cut -f4 -d" ")
sbatch -J tabixDepth -d afterok:$depth -t 1-00:00:00 -p core $scrdir/run_zip_and_tabix.sh $outp.recode.vcf


# PHREDSCORE AND MISSING DATA
GQ=30
maxmiss=0.95
in="vcf/$prefix.SNPs.HF.Bi.HH.DP.recode.vcf.gz"
outp="vcf/$prefix.SNPs.HF.Bi.HH.DP.GQ.miss"
phred=$(sbatch -J phredFilt -t 10:00:00 -p core run_filterPhredAndMissing.sh $in $GQ $maxmiss $outp |cut -f4 -d" ")
sbatch -J tabixPhred -d afterok:$phred -t 5:00:00 -p core run_zip_and_tabix.sh $outp.recode.vcf

# MINOR ALLELE COUNT
macval=2
in="vcf/$prefix.SNPs.HF.Bi.HH.DP.GQ.miss.recode.vcf.gz"
outp="vcf/$prefixSNPs.HF.Bi.HH.DP.GQ.miss.mac"
mac=$(sbatch -J MAC$macval -t 5:00:00 -p core run_filterMAC.sh $in $macval $outp |cut -f4 -d" ")
sbatch -J tabixMAC$macval -d afterok:$mac -t 5:00:00 -p core run_zip_and_tabix.sh $outp.recode.vcf

# HARDY (excess of heterozygous individuals)
hardy=0.001
in="vcf/$prefix.SNPs.HF.Bi.HH.DP.GQ.miss.mac.recode.vcf.gz"
out1="vcf/$prefixSNPs.HF.Bi.HH.DP.GQ.miss.mac"
out2="vcf/$prefix.final"
har=$(sbatch -J hardy -t 5:00:00 -p core $scrdir/run_filterHardy.sh $in $hardy $out1 $out2 |cut -f4 -d" ")
sbatch -J tabixHardy$hardy -d afterok:$har -t 5:00:00 -p core $scrdir/run_zip_and_tabix.sh $out2.recode.vcf


######################## CONVERT TO PLINK AND LD FILTER ########################

# From vcf to ped
in="vcf/$prefix.final.recode.vcf.gz"
outp="plink/$prefix"
sbatch -J vcf2ped -t 5:00:00 -p core $scrdir/run_vcftools_convertVCFtoPED.sh $in $outp

# ped to bed
plink --file plink/$prefix.chr1-38 --chr-set 38 --make-bed -out plink/$prefix.chr1-38

# LD filter
w=50kb
s=1
r=0.5
plink -bfile plink/$prefix.chr1-38 --indep-pairwise $w $s $r --chr-set 38 --out plink/$prefix.LD.$w.$s.$r.chr1-38
plink -bfile plink/$prefix.chr1-38 --extract plink/$prefix.LD.$w.$s.$r.chr1-38.prune.in --chr-set 38 --make-bed --out  plink/$prefix.LD.$w.$s.$r.chr1-38


################################# RELATEDNESS ##################################

inpref="plink/$prefix.chr1-38"
cutoff=0.05
for pop in $(cat populations.list)
do
 sbatch -J rel -t 5:00 -p core -n1 run_plink_rel-cutoff.sh $inpref $pop.fam $cutoff plink/$pop.chr1-38.cutoff$cutoff
done



######################### PRINCIPAL COMPONENT ANALYSIS #########################

# Extract different subset of individuals 
plink --bfile plink/$prefix.chr1-38 --chr-set 38 --keep subset.fam --make-bed -out plink/subset.chr1-38

sbatch -J pca -t 10:00 -p core -n1 run_plink_pca.sh plink/subset.chr1-38 1 plink/subset.chr1-38



############################## ADMIXTURE ANALYSIS ##############################


filt="LD.50kb.1.0.5"
subpref=$prefix.$filt
in="plink/$subpref.chr1-38.bed"
threads=4
for K in {2..10}
do
 sbatch -J admix.$K -t 2-00:00:00 -p core -n$threads -o admixture.$K.out -e admixture.$K.out run_admixture_template.sh $in $threads $K
done 
 
# Check best K 
for K in {2..10} #{2..6}
do
 grep "CV error" admixture.$K.out
done 



####################### PHASE VARIANTS WITH SHAPEIT4  ##########################

Ne=1500
vcf="vcf/$prefix.final.recode.vcf.gz"
# Run one chromosome at the time.
for chr in 1 {1..38}
do
 genmap="dog_genetic_maps/chr"$chr"_average_canFam3.1.txt"
 outp="shapeit/$prefix.$chr.phased.vcf.gz"
 sbatch -J shapeit.$chr -t 2-00:00:00 -p core -n 4 run_shapeit.sh $vcf $Ne $chr $genmap "-T 4" $outp
done



#################################### PCAdmix ###################################

# Format recombination map files 
for chr in {1..38}
do
 awk '{if(NR==1){print "position COMBINED_rate(cM/Mb) Genetic_Map(cM)"}else{print $2" "$3" "$4}}' dog_genetic_maps/chr"$chr"_average_canFam3.1.txt >genetic_map.chr$chr.txt
done


# Example run (using different number of reference individuals)
fold1="RefSizeTest"
mkdir -p PCAdmix/$fold1
wind=100
posfile=OnlyLDFilteredSites.txt
mixpop="ScandWolves"
for num in 50 40 30 20 10 8 5 
do
 for test in 1 2 3 4 5
 do
  fold2=$num"Wo"$num"Do.test"$test
  mkdir -p PCAdmix/$fold1/$fold2
  cat UnrelatedWolves.notScand.txt |grep -v -f ind.with.10perc.missing.txt |shuf -n $num >PCAdmix/$fold1/$fold2/Wolf.list
  cat 112Dogs.asPure.txt |grep -v -f ind.with.10perc.missing.txt |shuf -n $num >PCAdmix/$fold1/$fold2/Dog.list
  cat $mixpop.txt >PCAdmix/$fold1/$fold2/Admix.list
  cd PCAdmix/$fold1/$fold2/
  chrjobs=""
  for chr in {1..38}
  do
   jobextr=$(sbatch -J createInput.$num.$test.$chr -t 30:00 -p core run_createPCAdmixInput.sh shapeit/$prefix.$chr.phased.vcf.gz $chr $posfile |cut -f4 -d" ")
   jobpcadmix=$(sbatch -J pcadmix.$num.$test.$chr -d afterok:$jobextr -t 1:00:00 -p core run_PCAdmix.sh Wolf.$chr.txt Dog.$chr.txt Admix.$chr.txt chr$chr.map ../../dog_genetic_maps/genetic_map.chr$chr.txt $chr w"$wind"ld0.chr$chr $wind 0 |cut -f4 -d" ")
   chrjobs=$chrjobs":"$jobpcadmix
  done
  echo $chrjobs
  sbatch -J pcadmix.stats.$num.$test -d afterok$chrjobs -t 2:00:00 -p core run_statsForPCAdmix.sh "w$wind.ld0"
  cd ../../..
 done
done


### Check ancestry in the three hybrids and then calculate (certain) switches

# Hybrids as mixpop
mixpop="3Hybrids"
wolfref="UnrelatedWolves.asPure.txt"
dogref="112Dogs.asPure.txt"
fold1="Hybrids"
mkdir -p PCAdmix/$fold1
grep -v -f ind.with.10perc.missing.txt $wolfref >PCAdmix/$fold1/Wolf.list
grep -v -f ind.with.10perc.missing.txt $dogref >PCAdmix/$fold1/Dog.list
cp $mixpop.txt PCAdmix/$fold1/Admix.list

chrjobs=""
cd PCAdmix/$fold1/
for wind in "20" "50" "100" "200"
do
 for chr in  {1..38}
 do
  jobextr=$(sbatch -J vcfExtr.$chr.$mixpop  -t 30:00 -p core run_createPCAdmixInput.sh shapeit/$prefix.$chr.phased.vcf.gz $chr $posfile |cut -f4 -d" ")
  jobpcadmix=$(sbatch -J pcadmix.$chr.$mixpop -d afterok:$jobextr -t 1:00:00 -p core $scrdir/run_PCAdmix.sh Wolf.$chr.txt Dog.$chr.txt Admix.$chr.txt chr$chr.map ../dog_genetic_maps/genetic_map.chr$chr.txt $chr w"$wind"ld0.chr$chr $wind 0 |cut -f4 -d" ")
 chrjobs=$chrjobs":"$jobpcadmix
 done
 echo $chrjobs
 stat=$(sbatch -J pcadmix.stats.$mixpop -d afterok$chrjobs -t 2:00:00 -p core run_statsForPCAdmix.sh "w$wind.ld0" |cut -f4 -d" ")
done
cd ../..

# Calculate number of switches for each individual (and window size)
for wind in "20" "50" "100" "200"
do
 for ind in "V3064" "V3065" "V3069" 
 do
  echo "#CHR SWITCHES UNCERT_NO UNCERT_LEN SAME_NO_DOG SAME_LEN_DOG SAME_NO_WOLF SAME_LEN_WOLF CHR_LEN" |sed 's/ /\t/g' >PCAdmix/$fold1/Summary.$ind.w$wind.txt
  for chr in {1..38}
  do 
   sw=`paste <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_A.bed.txt") <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_B.bed.txt") |tail -n+2 | grep -v "*" |awk '($4!=$8){print}' |awk '{if(NR==1){oldA=$4; oldB=$8}else{if($4==oldA){if($8==oldB){}else{print NR ": switch in B!"; oldB=$8}}else{if($8==oldB){print NR ": switch in A!"; oldA=$4}else{print NR ": Both switched!"; oldA=$4; oldB=$8}}}}' |wc -l `
   unl=`paste <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_A.bed.txt") <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_B.bed.txt") |tail -n+2 |grep "*" |awk -v s=0 '{s+=($3-$2+1)}END{print s}'`
   unn=`paste <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_A.bed.txt") <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_B.bed.txt") |tail -n+2 |grep "*" |wc -l`
   sameldog=`paste <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_A.bed.txt") <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_B.bed.txt") |tail -n+2 |awk '($4==$8 && $4=="DOG"){print}' |grep -v "*" |awk -v s=0 '{s+=($3-$2+1)}END{print s}'`
   samendog=`paste <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_A.bed.txt") <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_B.bed.txt") |tail -n+2 |awk '($4==$8 && $4=="DOG"){print}' |grep -v "*" |wc -l`
   samelwolf=`paste <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_A.bed.txt") <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_B.bed.txt") |tail -n+2 |awk '($4==$8 && $4=="WOLF"){print}' |grep -v "*" |awk -v s=0 '{s+=($3-$2+1)}END{print s}'`
   samenwolf=`paste <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_A.bed.txt") <(cut -f1,2,3,7 "PCAdmix/$fold1/w$wind.ld0/chr"$chr"_"$ind"_B.bed.txt") |tail -n+2 |awk '($4==$8 && $4=="WOLF"){print}' |grep -v "*" |wc -l`
   chrlen=`awk -v c=$chr '($1==c){print $2}' autosome.sizes.txt`
   echo $chr" "$sw" "$unn" "$unl" "$samendog" "$sameldog" "$samenwolf" "$samelwolf" "$chrlen |sed 's/ /\t/g' >>PCAdmix/$fold1/Summary.$ind.w$wind.txt
  done
 done
done

# Summarize switch per Mb and only dog/only wolf frac
for wind in "20" "50" "100" "200"
do
 echo "Wind $wind"
 for ind in "V3064" "V3065" "V3069" 
 do
  awk '(NR>1){swsum+=$2; dogsum+=$6; wolfsum+=$8; chrsum+=$9}END{swpm=swsum/chrsum*1000000; dogfrac=dogsum/chrsum; wolffrac=wolfsum/chrsum; print swpm" "dogfrac" "wolffrac}' PCAdmix/$fold1/Summary.$ind.w$wind.txt
 done
done



########################## ELAI LOCAL ANCESTRY SEGMENTS ########################

# Example with Hybrids as the admixing population

# Hybrids as mixpop
mixpop="3Hybrids"
wolfref="UnrelatedWolves.asPure.txt"
dogref="112Dogs.asPure.txt"
folder="Hybrids"

mkdir -p ELAI/$folder

grep -v -f ind.with.10perc.missing.txt $wolfref |perl ~/private/scripts/misc/extractIndFromList.pl -file AllInd.fam -list /dev/stdin -col=1 >ELAI/$folder/WOLF.fam
grep -v -f ind.with.10perc.missing.txt $dogref |perl ~/private/scripts/misc/extractIndFromList.pl -file AllInd.fam -list /dev/stdin -col=1 >ELAI/$folder/DOG.fam
perl ~/private/scripts/misc/extractIndFromList.pl -file AllInd.fam -list $mixpop.txt -col=1 >ELAI/$folder/ADMIX.fam


# Create BIMBAM files from the plink file - NOTE: ELAI does NOT require LD-filtering
for pop in  "WOLF" "DOG" "ADMIX"
do
 for chr in {1..38}
 do
   plink --bfile plink/AllInd.chr1-38 --chr-set 38 --chr $chr --keep ELAI/$folder/$pop.fam --recode bimbam --out ELAI/$folder/$pop.chr$chr
 done
done

# RUN ELAI
dummy=1000000
mg=100
cd ELAI/$folder
for test in 1 2 3 4 5
do
 settings="EM30C2c10mg$mg"
 chrjobs=""
 for chr in {1..38}
 do
  job=$(sbatch -J ELAI.$test.$chr.$folder -d afterok:$dummy -t 1-00:00:00 -p core run_ELAI.sh WOLF.chr$chr.recode.geno.txt DOG.chr$chr.recode.geno.txt ADMIX.chr$chr.recode.geno.txt ADMIX.chr$chr.recode.pos.txt 30 2 10 $mg $settings.$chr "" |cut -f4 -d" ")
  chrjobs=$chrjobs":"$job
 done
 echo $chrjobs
 dummy=$(sbatch -J ELAI.prep.$test.$folder -d afterany$chrjobs -t 5:00 -p core run_ELAI_AfterDummy.sh "$test.mg$mg" |cut -f4 -d" ")
done
cd ../..

# Summarize ancestry for all chromosomes
mg=100
n=`cat ELAI/$folder/ADMIX.fam |wc -l`
for test in {1..5}
do
 rm -f ELAI/$folder/size.and.frac.test$test.mg$mg.txt
 for chr in {1..38}
 do
  frac=`grep -v "#" ELAI/$folder/output.test$test.mg$mg/EM30C2c10mg$mg.$chr.log.txt |grep '[^ ]' |tail -n$n |tr "\n" " " `
  size=`awk -v c=$chr '($1==c){print $2}' autosome.sizes.txt `
  #echo "size is $size"
  echo $frac""$size |sed 's/ /\t/g' >>ELAI/$folder/size.and.frac.test$test.mg$mg.txt
 done
 max=`echo $n*2 |bc`
 echo $test
 for i in $(eval echo {2..$max..2})
 do
  awk -v i=$i '{fsum+=$i*$NF; totsum+=$NF}END{frac=fsum/totsum; print frac"\t"fsum"\t"totsum}' ELAI/$folder/size.and.frac.test$test.mg$mg.txt
 done
done








