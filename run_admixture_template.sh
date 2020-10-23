#!/bin/bash -l

infile=$1
threads=$2
K=$3

admixture --cv -j$threads $infile $K
