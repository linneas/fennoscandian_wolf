#!/bin/bash -l

pop1=$1
pop2=$2
admix=$3
pos=$4
EM=$5
upper=$6
lower=$7
mg=$8
outpref=$9
other=$10

/home/software/elai-latest/elai/elai-lin -g $pop1 -p 10 -g $pop2 -p 11 -g $admix -p 1 -pos $pos "$other" -s $EM -C $upper -c $lower -mg $mg -o $outpref

