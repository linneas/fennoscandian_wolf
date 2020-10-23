#!/bin/bash -l

ancw=$1
ancd=$2
admix=$3
map=$4
genmap=$5
chr=$6
out=$7
wSNP=$8
ldflag=$9

/pathToPCADMIX/PCAdmix3_linux -anc $ancw $ancd -adm $admix -map $map -rho $genmap -ld $ldflag -w $wSNP -bed $chr -lab WOLF DOG ADMIX -o $out

