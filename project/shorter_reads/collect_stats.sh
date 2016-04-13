#!/bin/bash
if [ "$1" == "otus" ]; then
  field=6
elif [ "$1" == "otusp" ]; then
  field=7
elif [ "$1" == "counts" ]; then
  field=8
elif [ "$1" == "countsp" ]; then
  field=9
else
  echo "Usage: $0 [otusp|countsp|otus|counts]" > /dev/stderr
  exit 1
fi

basefn=otu_table_mc2.oo_vents.classic.intersection_stats
fnpattern=pick_otus.allsamples.shortened.*.fna/$basefn
for file in $fnpattern; do
  factor=${file%.fna*}
  factor=${factor##*shortened.}
  value=$(grep -P "^V\t" $file | cut -f $field)
  value=${value%\%}
  echo -e "$factor\t$value"
done

