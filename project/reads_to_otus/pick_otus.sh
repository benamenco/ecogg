#!/bin/bash

require_var allsamplesfna $allsamplesfna \
  "Concatenated preprocessing.sh output files"
require_var outdir $outdir "Output directory"
require_var silva $silva "Path to Silva database"
require_var NSLOTS $NSLOTS "Number of cluster slots to use"

require_program pick_open_reference_otus.py
require_program uclust
require_program FastTree
require_program pynast

require_file $allsamplesfna
require_file $silva

echo -e “pick_otus:enable_rev_strand_match\tTrue” > pick_otus.params
pick_open_reference_otus.py -i $allsamplesfna -o $outdir -f \
    -m uclust -r $silva -a -O $NSLOTS -p pick_otus.params --min_otu_size 2
