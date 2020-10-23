#!/usr/bin/perl

my $usage = "
# # # # # #
# countGenerationsToFounder.pl
# written by Linnéa Smeds 5 Feb 2020
# ======================================================
# Counts the number of generations to the closest Founder
# (direct offspring to immigrants get the value=1).
# For each individual, the scripts looks back at the
# parents of the parents of the parents until a founder
# (DAM or SIRE = 0) is found.
# ======================================================
# Usage: perl countGenerationsToFounder.pl -ped=ped-file \
		-list=list_of_ind [-out=outfile]
";

use strict;
use warnings;
use Getopt::Long;


my ($PED,$LIST,$COL,$HELP,$OUT);
GetOptions(
  	"ped=s" => \$PED,
   	"list=s" => \$LIST,
	"h" => \$HELP,
	"out=s" => \$OUT);


#--------------------------------------------------------------------------------
#Checking input, set default if not given
unless(-e $PED) {
	die "Error: File $PED doesn't exist!\n";
}
unless(-e $LIST) {
	die "Error: File $LIST doesn't exist!\n";
}
if($HELP) {
	die $usage . "\n";
}
unless($COL) {
	$COL=1;
}


#--------------------------------------------------------------------------------
print STDERR "Extract entries in $LIST from file $PED, looking in columns $COL\n";
if($OUT) {
	open(OUT, ">$OUT");
} 
else{
	print STDERR "Print output to stdout!\n";
}

# Save entries in hash
open(IN, $PED);
my %pedigree = ();
while(<IN>) {
	unless(/#/) {
		my @tab = split(/\s+/, $_);
		$pedigree{$tab[0]}{'sire'}=$tab[1];
		$pedigree{$tab[0]}{'dam'}=$tab[2];
	}
}
close(IN);


# Go through list, check ancestry for each ind
open(IN, $LIST);
while(<IN>){
	if(/^#/){
		if($OUT) {
			print OUT $_;
		}
		else {
			print $_;
		}
	}
	else {
#		print "Looking at line $_\n";
		chomp($_);
		my $ind=$_;
		my $gen=-1;
		my %parhash=();
		$parhash{$ind}=0;
#		print "DEBUG: Looking at $ind,saving to parhash!\n";

		while(!exists($parhash{"0"})){
			my %temphash=();
			foreach my $key (keys %parhash){
#				print "look at $key, check its parents!\n";
				unless(exists($pedigree{$key})) {
					die "No element $key in hash!\n";
				}
				$temphash{$pedigree{$key}{'sire'}}=0;
				$temphash{$pedigree{$key}{'dam'}}=0;
			}
			$gen++;
			%parhash=();
			%parhash=%temphash;
		}
		
		if($OUT) {
			print OUT $ind."\t".$gen."\n";
		}
		else {
			print $ind."\t".$gen."\n";
		}

	}
}
close(IN);
close(OUT);		
		
