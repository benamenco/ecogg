#!/bin/bash

require_var silva $silva "Path to Silva database"
require_var NSLOTS $NSLOTS "Number of cluster slots to use"
require_var wholereads $wholereads "the input readset (whole reads)"
require_var remap $remap "the map of readsets to vents or openocean"
require_program fas_proportionally_shorten.rb

for factor in 0.125 0.250 0.375 0.500 0.625 0.750 0.875; do
  allsamplesfna=shortened.$factor.fna
  fas_shorten_proportionally.rb $wholereads $factor > $allsamplesfna
  require_file $allsamplesfna
  outdir=shortened.$factor.pick_otus
  ../reads_to_otus/pick_otus.sh
  otutab=$outdir/otu_table_mc2_w_tax.biom
  ../exclusive_biome/compute_intersections.sh
done
