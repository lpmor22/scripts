#!/bin/bash

# author: Laise de Moraes <laisepaixao@live.com>
# institution: Oswaldo Cruz Foundation, Gonçalo Moniz Institute, Bahia, Brazil
# URL: https://lpmor22.github.io
# date: 29 MAY 2021

THREADS="$(lscpu | grep 'CPU(s):' | awk '{print $2}')"

RAWDIR="/path/directory"
HACDEMUXDIR="/path/directory"

SAMPLE=""
SAMPLEID=""
REFSEQ=""
PLOIDY="" #2

source activate minimap2
minimap2 -t $THREADS -ax map-ont $REFSEQ $SAMPLE | samtools sort -@ $THREADS -o $SAMPLEID.sorted.bam -
samtools view -@ $THREADS -h -F 4 -b $SAMPLEID.sorted.bam > $SAMPLEID.sorted.mapped.bam
samtools view -@ $THREADS -bS -f 4 $SAMPLEID.sorted.bam > $SAMPLEID.sorted.unmapped.bam
samtools index -@ $THREADS $SAMPLEID.sorted.mapped.bam
source activate nanopolish
nanopolish index -d $RAWDIR -s $HACDEMUXDIR/sequencing_summary.txt $SAMPLE
mkdir nanopolish
nanopolish_makerange.py $REFSEQ --overlap-length -1 | parallel -P 1 nanopolish variants -t $THREADS -r $SAMPLE -b $SAMPLEID.sorted.mapped.bam -o nanopolish/$SAMPLEID.{#}.vcf -g $REFSEQ -w {1} -p $PLOIDY -v
ls nanopolish/*.vcf > $SAMPLEID.vcflist.txt
nanopolish vcf2fasta --skip-checks -g $REFSEQ -f $SAMPLEID.vcflist.txt > $SAMPLEID.consensus.fasta
source activate minimap2
samtools coverage $SAMPLEID.sorted.mapped.bam > $SAMPLEID.sorted.mapped.coverage
samtools coverage $SAMPLEID.sorted.mapped.bam -A > $SAMPLEID.sorted.mapped.histogram.coverage
