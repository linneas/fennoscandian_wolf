#!/usr/bin/perl

my $usage = "
# # # # # #
# extractIndFromList.pl
# written by Linnéa Smeds 4 Dec 2019
# ======================================================
# Extracts lines from a file where one or more columns
# match entries from a given list. Suitable for example
# for extracting pairwise comparisons for only certain
# wanted individuals from a big file of many individuals
# (especially when names are unpractical and normal grep
# won't work *like IND1, IND10, IND100 etc).
# ======================================================
# Example: perl extractIndFromList.pl -file=BigTable.txt 
#		-list=listOfInd.txt -col=1,2 -out=ExtractedTable.txt
";

use strict;
use warnings;
use Getopt::Long;


my ($FILE,$LIST,$COL,$HELP,$OUT);
GetOptions(
  	"file=s" => \$FILE,
   	"list=s" => \$LIST,
  	"col=s" => \$COL,
	"h" => \$HELP,
	"out=s" => \$OUT);


#--------------------------------------------------------------------------------
#Checking input, set default if not given
unless(-e $FILE) {
	die "Error: File $FILE doesn't exist!\n";
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
print STDERR "Extract entries in $LIST from file $FILE, looking in columns $COL\n";
if($OUT) {
	open(OUT, ">$OUT");
} 
else{
	print STDERR "Print output to stdout!\n";
}

# Save entries in hash
open(IN, $LIST);
my %entries = ();
while(<IN>) {
		my @tab = split(/\s+/, $_);
		$entries{$tab[0]}=0;
}
close(IN);

# save column numbers in array 
my @col=split(/,/, $COL);

# Open outfile

# Go through file, save lines if matching entries
my $c=0;
open(IN, $FILE);
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
		my @tab = split(/\s+/, $_);
		my $save="yes";
		foreach my $c (@col) {
			unless(exists $entries{$tab[$c-1]}) {
				$save="no";
				last;
			}
		}
		if($save eq "yes") {
			if($OUT) {
			print OUT $_;
		}
			else {
				print $_;
			}
			$c++;
		}
	}
}
close(IN);
close(OUT);		
		
print STDERR "Done, saved $c lines!\n";
