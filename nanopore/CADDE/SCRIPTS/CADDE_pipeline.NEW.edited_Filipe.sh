csv="$1"	
fastq="$2"
fast5="$3"

library=`echo "$csv" | sed -e 's/\.csv//g' -e 's/.*\///g'`

cd ~/Desktop/LIBRARIES/"$library"

sum=$(find -name "sequencing_summary*" | sed 's/\.//')

summary=$(echo "~/Desktop/LIBRARIES/""$library""$sum")


source activate artic-ncov2019
##source activate artic-ncov2019-medaka

guppy_barcoder --require_barcodes_both_ends -i "$fastq" -s ANALYSIS --arrangements_files "barcode_arrs_nb12.cfg barcode_arrs_nb24.cfg" -t 8 -r

cd ANALYSIS

artic gather --prefix "$library" --directory "$fastq" --fast5-directory "$fast5"

echo "Sample@Nb of reads mapped@Average depth coverage@Bases covered >10x@Bases covered >25x@Reference covered (%)" | tr '@' '\t' > "$library".stats.txt

for i in `cat "$csv"`

	do

		sample=`echo "$i" | awk -F"," '{print $1}' | sed '/^$/d'`
		barcode=`echo "$i"| awk -F"," '{print $2}' | sed '/^$/d'` ; barcodeNB=`echo "$barcode"| sed -e 's/BC//g'` ; mv barcode"$barcodeNB" BC"$barcodeNB"
		pathref=`echo "$i" | awk -F"," '{print $3}' | sed '/^$/d'`
		ref=`echo "$pathref" | sed -e 's/\/.*//g'`
		min=`awk -F"\t" '{if (($4 !~ /LEFT_alt[0-9]*$/) && ($4 !~ /RIGHT_alt[0-9]*$/)) {print $0}}' ~/Desktop/PRIMER_SCHEMES/"$pathref"/"$ref".scheme.bed | awk -F"\t" '{print $2,$3}' | tr '\n' ' ' | awk '{for (i=1;i<=(NF/2);i=i+2) {print $(i*2+1)-$(i*2)}}' | sort -n | awk 'NR==1{print}' | awk '{print $1}'`
		max=`awk -F"\t" '{if (($4 !~ /LEFT_alt[0-9]*$/) && ($4 !~ /RIGHT_alt[0-9]*$/)) {print $0}}' ~/Desktop/PRIMER_SCHEMES/"$pathref"/"$ref".scheme.bed | awk -F"\t" '{print $2,$3}' | tr '\n' ' ' | awk '{for (i=1;i<=(NF/2);i=i+2) {print $(i*2+1)-$(i*2)}}' | sort -nr | awk 'NR==1{print}' | awk '{print $1+200}'`

		artic guppyplex --min-length "$min" --max-length "$max" --directory "$barcode" --prefix "$library" ; mv "$library"_"$barcode".fastq "$barcode"_"$library".fastq

		if [ `echo "$barcode" | awk '{if ($0 ~ /-/) {print "yes"} else {print "no"}}'` == "yes" ] ; then for i in `echo "$barcode" | tr '-' '\n'` ; do cat "$i"_"$library".fastq ; done > "$barcode"_"$library".fastq ; fi

		artic minion --normalise 200 --threads 8 --scheme-directory ~/Desktop/PRIMER_SCHEMES --read-file "$barcode"_"$library".fastq --fast5-directory "$fast5" --sequencing-summary "$summary" "$pathref" "$sample"
		##artic minion --medaka --normalise 200 --threads 8 --scheme-directory ~/Desktop/PRIMER_SCHEMES --read-file "$barcode"_"$library".fastq "$pathref" "$sample"

		~/Desktop/SCRIPTS/stats.sh "$sample" "$library" "$pathref"

        done 

cat *.consensus.fasta > "$library".consensus.fasta

cd ..

mkdir CONSENSUS

cp ANALYSIS/"$library".consensus.fasta CONSENSUS/
cp ANALYSIS/"$library".stats.txt CONSENSUS/

echo "########################"
echo "####### Finish!! #######"
echo "########################"
