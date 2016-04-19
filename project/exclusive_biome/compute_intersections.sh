#!/bin/bash

require_var otutab "OTU table path and filename pfx (wo .biom)"
require_var remap "YAML file with the remapping to OO vs vents"

require_program otutab_biom_to_classic.sh
require_program otutab_remap.rb

otudir=$(dirname $otutab)
otupfx=$(basename $otutab)

cd $otudir

otutab_biom_to_classic.sh $otupfx.biom
classic=$otupfx.classic
require_file $classic

remapped=$otupfx.remapped
otutab_remap.rb $classic $remap > $remapped
require_file $remapped

otutab_intersection_twosites.rb $remapped
