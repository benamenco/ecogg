#!/bin/bash
if [ ! -e filtered.fna ]; then
  echo "Filter reads"
  ./filter_reads.rb allsamples.fna "(L4|H2.2)" > filtered.fna
fi
./count_samples_in_fasta.rb filtered.fna > filtered.fna.sample_counts &

for factor in 0.125 0.250 0.500; do
  if [ ! -e shortened.$factor.fna ]; then
    echo "Shorten with factor $factor"
    ./proportionally_shorten_fasta.rb filtered.fna $factor \
      > shortened.$factor.fna &
  fi
done
wait
./submit_pipeline.sh
