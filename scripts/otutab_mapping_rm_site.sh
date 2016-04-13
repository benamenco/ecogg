#!/bin/bash

if [ $# -ne 4 ]; then
  echo "Rm one site from OTU Table and Mapping file" > /dev/stderr
  echo "Usage: $0 <otutable> <map> <site> <outdir>" > /dev/stderr
  exit 1
fi

otutable=$1
map=$2
site=$3
outdir=$4
require_file $otutable
require_file $map

mkdir -p $outdir

out_map=$outdir/map
tmp_otutable=$outdir/otu_table_mc1_w_tax.biom.tmp
out_otutable=$outdir/otu_table_mc1_w_tax.biom

nmatches=$(grep -P  "^${site}\t" $map | wc -l)
if [ $nmatches -eq 0 ]; then
  echo "Site $site not found in map $map" > /dev/stderr
  exit 1
fi
if [ $nmatches -gt 1 ]; then
  echo "Multiple lines for site $site found in map $map" > /dev/stderr
  exit 1
fi
grep -P -v "^${site}\t" $map > $out_map

samples_list=$(mktemp)
tail -n+2 $out_map | cut -d$'\t' -f 1 > $samples_list

filter_samples_from_otu_table.py -v \
  --sample_id_fp $samples_list \
  -i $otutable \
  -o $tmp_otutable

filter_otus_from_otu_table.py -v -n 1 \
  -i $tmp_otutable \
  -o $out_otutable

rm $tmp_otutable

rm $samples_list

