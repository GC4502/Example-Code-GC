#!/bin/bash
#^^^Shebang line

# Establish default values for variables
v=0;
index=0;
realign=0;
gunzip=0;
h=0;

# Get variables for script

while getopts "a:b:r:o:f:viehz" option
do
	case $option in 
		a) reads1=$OPTARG;;
		b) reads2=$OPTARG;;
		r) ref=$OPTARG;;
		o) output=$OPTARG;;
		f) millsFile=$OPTARG;;
		v) v=1;;
		i) index=1;;
		e) realign=1;;
		z) gunzip=1;;
		h) h=1;;
	esac
done

# Check whether the user needs to know which inputs are used for the script
if [ $h -eq 1 ]
then

	echo "In order to run this script please provide the following inputs:"
	echo "(requires input) -a Your first read file"
	echo "(requires input) -b Your second read file"
	echo "(requires input) -r Your referece genome file"
	echo "(requires input) -o Your desired ouput *.vcf file"
	echo "(requires input) -f Mills file location"
	echo "-e Perform realignment (0 or 1). Default 0."
	echo "-z Zips your ouput *.vcf file as *.vcf.gz (0 or 1). Default 0."
	echo "-v Verbose mode. Prints processes currently being executed (0 or 1). Default 0."
	echo "-i Indexes output BAM file (0 or 1). Default 0."
	echo "-h Prints script inputs and exits the program (0 or 1). Default 0."  
	exit
fi

# Checks whether the input files exist in the current directory. 
# If any of the reads files or the reference file do not exist in the directory, the program exits.
# If the desired output file already exists in the directory, ask the user whether or not to overwrite the file.

if  [ ! -e $reads1 ]
then 

	echo $reads1" was not found in this directory."
	exit

elif [ ! -e $reads2 ]
then

	echo $reads2" was not found in this directory."
	exit

elif [ ! -e $ref ] 
then

	echo $ref" was not found in this directory."
	exit

elif [ -e $output ] || [ -e $output".gz" ]
then

	echo $output" already exists in this directory. Overwrite (y/n)?"
	read answer
	if [ $answer = "y" ]
	then

		rm $output
	elif [ $answer = "n" ]
	then
		
		exit
	fi	
fi

	
# Establish the reference genome to be mapped to 
if [ $v -eq 1 ]
then
	echo "Establishing the reference genome "$ref
fi

~/bin/bwa/bwa index $ref

# Map the sequences to the reference genome
if [ $v -eq 1 ]
then
	echo "Mapping "$reads1" and "$reads2" to "$ref	
fi

~/bin/bwa/bwa mem -R '@RG\tID:a\tSM:b\tLB:c' $ref $reads1 $reads2 > lane.sam
	
# Clean up read pairing information and flags
if [ $v -eq 1 ]
then
	echo "Cleaning up pairing information"
fi

~/bin/samtools-1.10/samtools fixmate -O bam lane.sam lane.bam
	
# Create a dictionary file for the reference file
if [ $v -eq 1 ]
then
	echo "Creating a dictionary file for the reference genome" $ref
fi

java -jar picard.jar CreateSequenceDictionary R=$ref

if [ $v -eq 1 ]
then
	echo "Sorting .bam by coordinate number"
fi

~/bin/samtools-1.10/samtools sort -O bam -o lane_sorted.bam lane.bam

java -jar picard.jar BuildBamIndex I=lane_sorted.bam

if [ $realign -eq 1 ]
then
	
	# Realigning the mapped reads in order to reduce the number of miscalls
	if [ $v -eq 1 ]
	then
	echo "Realigning reads."
	fi	
	
	java -Xmx2g -jar GenomeAnalysisTK.jar -T RealignerTargetCreator -R $ref -I lane_sorted.bam -o lane.intervals --known $millsFile --log_to_file $output"RTC.log"
		
	java -Xmx4g -jar GenomeAnalysisTK.jar -T IndelRealigner -R $ref -I lane_sorted.bam  -targetIntervals lane.intervals -known $millsFile -o lane_realigned.bam --log_to_file $output"IR.log"
	
	if [ $index -eq 1 ]
	then
			
		# If the indexed mode is called for, use samtools to index our mapped reads
		if [ $v -eq 1 ]
		then
		echo "Indexing output"
		fi
		
		~/bin/samtools-1.10/samtools index lane_realigned.bam
	fi

	if [ $gunzip -eq 1 ]
	then
			
		# This block applies to the realigned mapped reads

		# If the compressed mode is called for, output the .vcf file as a compressed .vcf.gz file.
		if [ $v -eq 1 ]
		then
		echo "Output will be compressed as " $output".gz"
		fi
		
		~/bin/bcftools-1.11/bcftools mpileup -Ou -f $ref lane_realigned.bam | bcftools call -vmO z -o $output".gz"
	else
			
		# Else output it as .vcf
		if [ $v -eq 1 ]
		then
		echo "Output will be written as " $output
		fi
		
		~/bin/bcftools-1.11/bcftools mpileup -Ou -f $ref lane_realigned.bam | bcftools call -vmO v -o $output
	fi
	
else
		
	# This block is for non-realigned reads
		
	if [ $gunzip -eq 1 ]
	then			
			
		# Output as .vcf.gz
		if [ $v -eq 1 ]
		then
		echo "Output will be compressed as " $output ".gz"
		fi
		
		~/bin/bcftools-1.11/bcftools mpileup -Ou -f $ref lane.bam | bcftools call -vmO z -o $output".gz"
	else
			
		# Output as .vcf
		if [ $v -eq 1 ]
		then
		echo "Output will be written as " $output
		fi
		
		~/bin/bcftools-1.11/bcftools mpileup -Ou -f $ref lane.bam | bcftools call -vmO v -o $output
	fi
fi

sed '/^#/d' $output | awk '{print $1,$2,length($5)-length($4)+$2,length($5)-length($4)}' | sed 's/chr//' | awk '{if ($4 == 0) {print $0 > "snps.txt";} else {print $0 > "indels.txt";}}'

sed -i '1s/^/Chromosome \t Start \t Stop \t Length\n/' snps.txt
sed -i '1s/^/Chromosome \t Start \t Stop \t Length\n/' indels.txt


