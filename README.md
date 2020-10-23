## Scripts connected to the paper: 
## Whole‐genome analyses provide no evidence for dog introgression in Fennoscandian wolf populations 
(doi:10.1111/eva.13151)

All bash commands are found in the file COMMANDS_for_terminal.sh.
Most software have been run as batch jobs submitted to a cluster using slurm. These are named run_someName.sh.

The following four perl scripts were written to facilitate the project:

### addRecRateToSNPs.pl
Takes a list of SNPs and a file with recombination rates and certain positions, that should be seen as starting positions for a window with a fixed rate. Returns a list with SNPs and their rec rate depending on what window they fall into.

### countGenerationsToFounder.pl
Counts the number of generations to the closest Founder (direct offspring to immigrants get the value=1). For each individual in a list, the scripts looks back at the parents of the parents of the parents until a founder (DAM or SIRE = 0) is found.

### extractIndFromList.pl
Extracts lines from a file where one or more columns match entries from a given list. Suitable for example for extracting pairwise comparisons for only certain wanted individuals from a big file of many individuals (especially when names are unpractical and normal grep won't work *like IND1, IND10, IND100 etc).

### summarizePCAdmixResultPerWindow.pl
Goes through the BED output of PCAdmix for multiple individuals and summarize the number of "DOGS" per window. 
