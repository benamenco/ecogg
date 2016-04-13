#!/bin/bash

# %-PURPOSE-%
# Convert a classic OTU table into biom

force=false
if [ "$1" == "-f" ]; then force=true; shift; fi

if [ $# -ne 1 ]; then
  echo "Usage: $0 [-f] <classic>" > /dev/stderr
  exit 1
fi

classic=$1
biom=${classic%.classic}.biom

if $force; then rm -f $biom; fi

require_file $classic

biom convert --to-hdf5 \
  -i $classic \
  -o $biom \
  --table-type "OTU table" \
  --process-obs-metadata=taxonomy
