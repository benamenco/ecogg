#!/bin/bash
repetitions=10
while read nreads; do
  for (( i=0; i<repetitions; i++ )); do
    if [ ! -e ${nreads}_${i}.classic ]; then
      echo "# [`date`] Computing otutable ${nreads}_${i}"
      otutab_randsub.rb otu_table.oo.classic $nreads > \
        ${nreads}_${i}.oo.classic
      otutab_merge.rb otu_table.vents.classic ${nreads}_${i}.oo.classic > \
        ${nreads}_${i}.classic
      otutab_split_singletons.rb ${nreads}_${i}.classic
      twosites_otutab_compute_intersections.rb ${nreads}_${i}.classic.2
    fi
  done
done < levels
