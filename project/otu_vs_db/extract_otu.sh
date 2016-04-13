#!/bin/bash
extract_otu_sequences.rb -v ../downstream.hiseq/pick_otus/final_otu_map.txt \
  -i ../upstream.hiseq/split_libraries/allsamples.fna $1 \
  -e "(^L4-|-H2.2$)" > $1.ids
if [ -e $1.otu.fna ]; then
  echo "Error: file $1.otu.fna exists" > /dev/stderr
  exit 1
else
  fas_subset $1.ids ../upstream.hiseq/split_libraries/allsamples.fna \
    > $1.otu.fna
fi
