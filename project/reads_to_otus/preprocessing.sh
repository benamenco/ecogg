#!/bin/bash

require_var trimmomaticdir "path of Trimmomatic"
require_var r1 "forward readset (fq/gz), without .fq.gz"
require_var r2 "reverse readset (fq/gz), without .fq.gz"
require_var outpfx "output path and filename prefix"
require_var phiXindex \
  "bowtie2 index of the phiX genome (bowtie2-build <genome.fas> <index>)"
require_var NCPU "number of threads to use"
require_var mapping "Qiime mapping file"
# sampleid and basecounter are different for each sample
require_var sampleid "SampleID for readset"
require_var samplebasecounter "first seqnum for sample"

require_file $trimmomaticdir/trimmomatic-0.33.jar
require_file $trimmomaticdir/adapters/NexteraPE-PE.fa
require_file $r1.fq.gz
require_file $r2.fq.gz
require_program java
require_program bowtie2
require_program flash
require_program split_libraries_fastq.py

# rm adapters; rm reads < 150 nt after trimming

t1=$outpfx.1.trimmomatic.paired.fq.gz
t2=$outpfx.2.trimmomatic.paired.fq.gz

java -jar $trimmomaticdir/trimmomatic-0.33.jar \
  PE -threads $NCPU -phred33 $r1.fq.gz $r2.fq.gz \
  $t1 $outpfx.1.trimmomatic.unpaired.fq.gz \
  $t2 $outpfx.2.trimmomatic.unpaired.fq.gz \
  ILLUMINACLIP:$trimmomaticdir/adapters/NexteraPE-PE.fa:2:30:10 \
  MINLEN:150

require_file $t1
require_file $t2

# rm reads pairs aligning to PhiX genome

bpfx=$outpfx.wo_phiX.fq
b1=$bpfx.1.gz
b2=$bpfx.2.gz

bowtie2 -p $NCPU -x $phiXindex –un-conc-gz $bpfx.gz -1 $t1 -2 $t2 -S /dev/null

require_file $b1
require_file $b2

# merge read pairs

fpath=$(dirname $outpfx)
fpfx=$(basename $outpfx)
f=$outpfx.extendedFrags.fastq.gz

flash $input_r1 $input_r2 -r 251 -f 460 -s 46 -o $outpfx -d $outpath -z -t $NCPU

require_file $f

# import in Qiime and further quality trimming and filtering;

s=$outpfx.seqs.fna

split_libraries_fastq.py -i $f -m $mapping -o $s \
  --sample_ids $sampleid -s $samplebasecounter -q 0 -n 10 \
  --barcode_type 'not-barcoded'

require_file $s

# $s is the output file; all output files are later merged using cat
