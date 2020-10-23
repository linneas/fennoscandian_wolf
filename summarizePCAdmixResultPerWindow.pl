#!/usr/bin/perl

my $usage = "
# # # # # #
# summarizePCAdmixResultPerWindow.pl
# written by Linnéa Smeds 7 April 2020
# ======================================================
# Goes through the BED output of PCAdmix for multiple
# individuals and summarize the number of \"DOGS\" per
# window. 
# ======================================================
# Usage: perl summarizePCAdmixResultPerWindow.pl listOfInds.txt pathToBed out

";

use strict;
use warnings;
use Getopt::Long;

my $time=time;

my ($INDLIST,$PATH,$COL,$HELP,$OUT);
GetOptions(
  	"indlist=s" => \$INDLIST,
   	"path=s" => \$PATH,
	"h" => \$HELP,
	"out=s" => \$OUT);


#--------------------------------------------------------------------------------
#Checking input, set default if not given
unless(-e $INDLIST) {
	die "Error: File $INDLIST doesn't exist!\n";
}
unless(-e $PATH) {
	die "Error: Path $PATH doesn't exist!\n";
}
if($HELP) {
	die $usage . "\n";
}


#--------------------------------------------------------------------------------
print STDERR "Go through bed files in $PATH for each individual in $INDLIST\n";
unless($OUT) {
	die "Error: Need to provide output file!\n"
}
open(OUT, ">$OUT");

# Save all individuals
my @inds=();
open(IN, $INDLIST);
while(<IN>) {
	chomp($_);
	push(@inds, $_); 
}
close(IN);

# Go through each chromosome
for (my $chr=1; $chr<=38; $chr++) {

	my %hash=();
	my $c=0;

	#Go through each ind
	for my $ind (@inds) {
		my @files=($PATH."chr".$chr."_".$ind."_A.bed.txt",$PATH."chr".$chr."_".$ind."_B.bed.txt");
		for my $file (@files) {
			open(BED, $file);
			while(<BED>) {
				unless(/^Chr/) {
					my @tab=split(/\s+/, $_);

					# The first hap for every chromosome - save windows!
					if($c==0){
						$hash{$tab[1]}{'end'}=$tab[2];
						if($tab[6] eq "DOG") {
							$hash{$tab[1]}{'no'}=1;
						}
						else{
							$hash{$tab[1]}{'no'}=0;
						}
					}
					else {
						if($tab[6] eq "DOG") {
							$hash{$tab[1]}{'no'}++;
						}
					}
				}
			}
			$c++;
		}
	}
	foreach my $key (sort {$a <=> $b} keys(%hash)) {
		print OUT $chr."\t".$key."\t".$hash{$key}{'end'}."\t".$hash{$key}{'no'}."\n";
	}
	print STDERR "Chromosome $chr, went through $c haplotypes!\n";
} 

$time=time-$time;
print STDERR "Done! Took $time seconds\n";
				
