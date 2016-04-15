if [ "$1" == "" ]; then exit 1; fi
compare_categories.py \
  --method anosim \
  -i ../H2.beta/dm/${1}_dm.txt \
  -m H2.env.new.anosim.map \
  -c BetaGroup \
  -o ${1}_anosim \
  -n 1000
