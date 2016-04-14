#!/bin/bash

require_file V3V4.fas
require_file V6.fas
require_variable $silvatax
require_program fas_shorten_proportionally.rb

function assign_and_compare { local pfx=$1
  tax_assignments=uclust_assigned_taxonomy/${pfx}_tax_assignments.txt
  assign_taxonomy.py -i ${pfx}.fas
  require_file $tax_assignments
  eval_assignments=uclust_assigned_taxonomy/${pfx}_tax_assignments.eval
  ./compare_silva_tax_with_uclust_assigned.rb $tax_assignments $silvatax \
    > $eval_assignments
  require_file $eval_assignments
}

ln -s V3V4.fas V3V4.shortened.1.000.fas
for f in 0.125 0.250 0.375 0.500 0.625 0.750 0.875; do
  pfx=V3V4.shortened.$f
  fas_shorten_proportionally.rb V3V4.fas $f > $pfx.fas
  assign_and_compare $pfx
done

assign_and_compare V6.fas

./compare_silva_tax_with_two_uclust_assigned.rb \
  uclust_assigned_taxonomy/V3V4.shortened.1.000_tax_assignments.txt \
  uclust_assigned_taxonomy/V6_tax_assignments.txt \
  $tax_assignments > uclust_assigned_taxonomy/both_V3V4_vs_v6
