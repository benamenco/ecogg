#!/bin/bash

source ../scripts/set_env.sh

mkdir -p jobs_out
nslots=128
qsubscript=pick_otus-openref_silva_mos2.qsub
factors="125 250 500"
for factor in $factors; do
  inputfile="allsamples.shortened.0.${factor}.fna"
  echo "# Submit job for file: $inputfile"
  outdir=pick_otus.$inputfile
  qsub $qsubscript $inputfile $outdir $nslots
done
