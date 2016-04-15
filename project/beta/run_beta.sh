#!/bin/bash

require_var otutabpfx $otutabpfx "the input OTU table (wo .classic file sfx)"
require_var n $n "the rescaling value (e.g. 10 million)"
require_var NSLOTS $NSLOTS "the number of cluster slots to use"
require_var mapping $mapping "the mapping file"
require_var tree $tree "the phylogenetic tree file"

require_program otutab_rescale.rb
require_program otutab_classic_to_biom.sh
require_program jackknifed_beta_diversity.py
require_program make_2d_plots.py

otutab=${otutabpfx}.classic
require_file $otutab

rescaledpfx=${otutabpfx}.rescaled.$n
rescaled_c=${rescaledpfx}.classic
rescaled_b=${rescaledpfx}.biom
otutab_rescale.rb $otutab $n > $rescaled_c
require_file $rescaled_c
otutab_classic_to_biom.sh $rescaled_c
require_file $rescaled_b

echo "beta_diversity:metrics  weighted_unifrac" > beta.params
echo "make_prefs_file:mapping_headers_to_use  SampleID" >> beta.params

jackknifed_beta_diversity.py -a -O $NSLOTS -f -o jackknifed.beta \
  -p beta.params -i $rescaled_b -m $mapping -t $tree -e $n

make_2d_plots.py -i jackknifed.beta/weighted_unifrac/pcoa -m $mapping \
    -b 'SampleID' -o jackknifed.pcoa.2D_plots/weighted_unifrac/
