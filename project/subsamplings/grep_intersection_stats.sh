#!/bin/bash
repetitions=10
column=9
outfile=vent_counts_shared.tsv
if [ "$1" == "-otus" ]; then
  column=7
  outfile=vent_otus_shared.tsv
fi
rm -rf $outfile
while read nreads; do
  for (( i=0; i<repetitions; i++ )); do
    if [ -e ${nreads}_${i}.classic.2.intersection_stats ]; then
      v=`grep -P "^Not-OpenOcean" ${nreads}_${i}.classic.2.intersection_stats | \
        cut -d$'\t' -f $column | grep -P -o "\d+\.\d+"`
      echo -e "$nreads\t$v" >> $outfile
    fi
  done
done < levels
