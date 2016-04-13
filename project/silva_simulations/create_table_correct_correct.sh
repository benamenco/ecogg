#!/bin/bash
for f in 0.125 0.250 0.375 0.500 0.625 0.750 0.875 1.000; do
  ./compare_silva_tax_with_two_uclust_assigned.rb \
    uclust_assigned_taxonomy/V3V4.shortened.${f}_tax_assignments.txt \
    uclust_assigned_taxonomy/V6.Gibbons_tax_assignments.txt \
    /work/gi/databases/qiime-data/silva/Silva119_release/taxonomy/97/taxonomy_97_7_levels.txt \
    | grep correct-correct > \
      uclust_assigned_taxonomy/V3V4.shortened.${f}_tax_assignments.eval_vs_V6
done
