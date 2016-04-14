#!/bin/bash

require_program otutab_randsub.rb
require_program otutab_merge.rb
require_program otutab_split_singletons.rb
require_program otutab_intersection_twosites.rb

./split_open_ocean_and_vents.rb
vents_otus=otu_table.vents.classic
oo_otus=otu_table.oo.classic
require_file $vents_otus
require_file $oo_otus

repetitions=10
for nreads in 7500000 5000000 2500000 1000000 750000 500000 250000 100000 75000 50000 25000 25000000; do
  for (( i=0; i<repetitions; i++ )); do
    if [ ! -e ${nreads}_${i}.vents.classic ]; then
      echo "# [`date`] Computing otutable ${nreads}_${i}.vents"
      otutab_randsub.rb $vents_otus $nreads > ${nreads}_${i}.vents.classic
      otutab_merge.rb $oo_otus ${nreads}_${i}.vents.classic > \
        ${nreads}_${i}.vents.all_oo.classic
      otutab_split_singletons.rb ${nreads}_${i}.vents.all_oo.classic
      otutab_intersection_twosites.rb ${nreads}_${i}.all_oo.classic.2
    fi
    if [ ! -e ${nreads}_${i}.oo.classic ]; then
      echo "# [`date`] Computing otutable ${nreads}_${i}.oo"
      otutab_randsub.rb $oo_otus $nreads > ${nreads}_${i}.oo.classic
      otutab_merge.rb $vents_otus ${nreads}_${i}.oo.classic > \
        ${nreads}_${i}.oo.all_vents.classic
      otutab_split_singletons.rb ${nreads}_${i}.oo.all_vents.classic
      otutab_intersection_twosites.rb ${nreads}_${i}.classic.all_vents.2
    fi
  done
done
