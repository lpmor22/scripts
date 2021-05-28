#!/bin/bash

# author: Laise de Moraes <laisepaixao@live.com>
# institution: Oswaldo Cruz Foundation, Gonçalo Moniz Institute, Bahia, Brazil
# URL: https://lpmor22.github.io
# date: 27 MAY 2021

if [[ -z "$(which mamba)" ]]; then
	cd
	wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
	bash Miniconda3-latest-Linux-x86_64.sh -bfp miniconda3 && rm Miniconda3-latest-Linux-x86_64.sh
	echo 'export PATH=$HOME/miniconda3/bin:/usr/local/share/rsi/idl/bin:$PATH' >> $HOME/.bashrc
	export PATH=$HOME/miniconda3/bin:/usr/local/share/rsi/idl/bin:$PATH
	conda install -y -c conda-forge mamba
	mamba update -y -n base conda
	if [[ -z "$(which mamba)" ]]
	then
    mamba update -y -n base conda
	mamba --version
	mamba create -y -n phipseq -c conda-forge -c bioconda -c defaults fastqc multiqc kallisto
	pip install click biopython numpy scipy git+https://github.com/lasersonlab/phip-stat.git	
  else
    mamba update -y -n base conda
	mamba --version
  fi
else
  mamba update -y -n base conda
  mamba --version
fi

WORKPATH="/mnt/e/PhiPSeq_LeoPaiva/"
RAWPATH="/mnt/e/PhiPSeq_LeoPaiva/F20FTSUSAT0469-02_PHAyvdR/Reads/Clean/"
PREFIXSAMPLES="SVA"
REFERENCE="/mnt/e/PhiPSeq_LeoPaiva/schistosoma_mansoni.PRJEA36577.WBPS15.mRNA_transcripts.fa.gz"
THREADS="12"

cd "$WORKPATH"

mkdir ANALYSIS FASTQC -v

for i in $(find "$RAWPATH" -type d -name "$PREFIXSAMPLES*" | sort); do cp "$i"/*_1.fq.gz ANALYSIS/"$(basename "$i")"_1.fq.gz -v; cp "$i"/*_2.fq.gz ANALYSIS/"$(basename "$i")"_2.fq.gz -v; done

source activate phipseq

fastqc -t "$THREADS" ANALYSIS/*.fq.gz -o FASTQC

multiqc -s -i PhiPSeq_LeoPaiva -ip FASTQC

cd ANALYSIS

mkdir translated -v

for i in $(find ./ -type f -name "*.fq.gz" | while read o; do basename $o | cut -d. -f1; done); do
	seqkit translate -j "$THREADS" -f 1 "$i".fq.gz > translated/"$i"_1.fa
	seqkit translate -j "$THREADS" -f 2 "$i".fq.gz > translated/"$i"_2.fa
	seqkit translate -j "$THREADS" -f 3 "$i".fq.gz > translated/"$i"_3.fa
	seqkit translate -j "$THREADS" -f -1 "$i".fq.gz > translated/"$i"_-1.fa
	seqkit translate -j "$THREADS" -f -2 "$i".fq.gz > translated/"$i"_-2.fa
	seqkit translate -j "$THREADS" -f -3 "$i".fq.gz > translated/"$i"_-3.fa
done

kallisto index -i "$(basename "$REFERENCE" | rev | cut -c 7- | rev)".idx "$REFERENCE"

mkdir sample_counts -v

for i in $(find ./ -type f -name "*.fq.gz" | while read o; do basename $o | cut -d_ -f1; done | uniq | sort); do
	mkdir sample_counts/"$i" -v
	kallisto quant -i "$(basename "$REFERENCE" | rev | cut -c 7- | rev)".idx -o sample_counts/"$i" --plaintext --fr-stranded -t "$THREADS" "$i"_1.fq.gz "$i"_2.fq.gz
done

cat nohup.out | grep "reads pseudoaligned" > readsPseudoaligned.txt

cat nohup.out | grep "will process pair" > processPair.txt
 
echo "sample\ttotal_reads\treads_pseudoaligned" > mappedReads.tsv

paste processPair.txt readsPseudoaligned.txt | column -s $'\t' -t | sed 's/\[quant\] will process pair 1: //g' | sed 's/_1.fq.gz//g' | sed 's/  \[quant\] processed /\t/g' | sed 's/ reads, /\t/g' | sed 's/ reads pseudoaligned//g' >> mappedReads.tsv
sv
phip merge-kallisto-tpm -i sample_counts -o tpm.tsv #Transcripts Per Million

phip gamma-poisson-model -t 99.9 -i tpm.tsv -o gamma-poisson #Minus log10 p-value