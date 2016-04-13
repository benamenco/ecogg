#!/bin/bash

if [ $# -lt 4 ]; then
  echo "Extract selected sites from OTU Table and Mapping file" > /dev/stderr
  echo "Usage: $0 <otutable> <map> <outdir> <site1> [<site2>...]" > /dev/stderr
  exit 1
fi

otutable=$1
shift
map=$1
shift
outdir=$1
shift
sites=$*

require_program filter_samples_from_otu_table.py

require_file $otutable
require_file $map

mkdir -p $outdir

out_map=$outdir/map
out_otutable=$outdir/otu_table_mc1_w_tax.biom

grep -P "^#" $map > $out_map

samples_list=$(mktemp)
for site in $sites; do
  grep -P "^$site\t" $map >> $out_map
  echo $site >> $samples_list
done

filter_samples_from_otu_table.py -v \
  --sample_id_fp $samples_list \
  -i $otutable \
  -o $out_otutable

rm $samples_list
