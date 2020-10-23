#!/usr/bin/perl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# addRecRateToSNPs.pl
# written by Linnéa Smeds	                15 Jan 2020
# ---------------------------------------------------------
# DESCRIPTION:
# Takes a list of SNPs and a file with recombination rates
# and certain positions, that should be seen as starting
# positions for a window with a fixed rate. Returns a list
# with SNPs and their rec rate depending on what window they 
# fall into.
# NOTE: Any position falling outside of the windows is given
# a recombination rate of 0. 
# NOTE2: Both list should be sorted and chromosome specific.
# NOTE3: NO headers are allowed!
# ---------------------------------------------------------
# Example perl addRecRateToSNPs.pl mySNPs.txt myRecRates.txt >SNPsWithRates.txt

use strict;
use warnings;

# Input parameters
my $SNPs = $ARGV[0];
my $RATES = $ARGV[1];


# SAVE THE WINDOWS
my @start = (0);
my @rate = (0); 
open(IN, $RATES);
while(<IN>){
	my @a = split(/\s+/, $_);
#	print "DEBUG add ".$a[0]." to start and ".$a[1]." to rate\n";
	push @start, $a[0];
	push @rate, $a[1];
}
close(IN);


# GO THROUGH THE SNPs
open(IN, $SNPs);
while(<IN>) {
	my @t=split(/\s+/, $_);
	my $r="n";
	
	# first check if snp is outside of array (higher than last pos)
	if($t[0]>$start[-1]) {
		$r=$rate[-1];
	}
	else {
		for(my $i=0; $i<scalar(@start); $i++) {
			if($start[$i]>$t[0]){
				my $ii=$i-1;
				$r=$rate[$ii];
				last;
			}
		}
	}
	print $t[0]."\t".$r."\n";
}
close(IN);

