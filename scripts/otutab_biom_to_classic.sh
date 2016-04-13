#!/bin/bash

# %-PURPOSE-%
# Convert a biom OTU table into classic format

force=false
if [ "$1" == "-f" ]; then force=true; shift; fi

if [ $# -ne 1 ]; then
  echo "Usage: $0 [-f] <biom>" > /dev/stderr
  exit 1
fi

biom=$1
classic=${biom%.biom}.classic

if $force; then rm -f $classic; fi

require_file $biom

biom convert -i $biom -o $classic \
  --table-type "OTU table" --to-tsv --header-key=taxonomy

