#!/bin/bash
set -e

# This script will demonstrate how to call SNAP and samtools to generate the coverage figure
# window size for coverage plot
windowSize=10000
# truncate the coverage plot to the following coverage (must be a power of two)
truncateTo=2
srcDir="/home/dkoslicki/Dropbox/Repositories/MinHash/src/"
dataDir="/home/dkoslicki/Dropbox/Repositories/MinHash/data/SNAP/"
plotDir="/home/dkoslicki/Dropbox/Repositories/MinHash/Paper/Figs/"
paperDir="/home/dkoslicki/Dropbox/Repositories/MinHash/Paper/"

# Make the index, using seed size of 20
snap-aligner index ${dataDir}PRJNA274798.fa ${dataDir} -s 20 -large

# Align the paired reads, only output aligned, allow larger edit distance to get more candidate alignment locations
snap-aligner paired ${dataDir} ${dataDir}4539585.3.sorted.r1.fastq ${dataDir}4539585.3.sorted.r2.fastq -F a -hp -mrl 40 -xf 1.2 -d 28 -o -sam ${dataDir}aligned.sam > ${dataDir}alignment-stats.txt

# Sort the output
samtools sort --output-fmt sam ${dataDir}aligned.sam > ${dataDir}aligned.sorted.sam

# Windowed coverage information, only use MAPQ quality >= 20
samtools depth -q 20 -a --reference ${dataDir}PRJNA274798.fa ${dataDir}aligned.sorted.sam | python ${srcDir}GetCoverage.py $windowSize /dev/fd/0 ${dataDir}coverage_${windowSize}.txt

# Make the plot
python ${srcDir}CoveragePlot.py -i ${dataDir}coverage_${windowSize}.txt -o ${plotDir}CoveragePlot.png -t ${truncateTo}

# Trim the white space in the figure
convert ${plotDir}CoveragePlot.png -trim ${plotDir}CoveragePlot.png

# Save the number of reads that aligned and other stats
sed -n 4p ${dataDir}alignment-stats.txt | cut -d' ' -f6 > ${paperDir}NumReadsAligned.txt
echo $windowSize > ${paperDir}WindowSize.txt
echo truncateTo > ${paperDir}TruncateTo.txt
# Save average coverage
cat ${dataDir}coverage_${windowSize}.txt | cut -f 4 | awk '{sum+=$1}END{print sum / NR}' > ${paperDir}MeanCoverage.txt
