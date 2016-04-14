#!/bin/bash
require_var fprimer $fprimer "F primer (or |-separated list)"
require_var rprimer $rprimer "R primer (or |-separated list)"
require_var silvaaln $silvaaln "Silva alignment file"
require_var silvatax $silvatax "Silva taxonomy file"
require_var minlen $minlen "Minimum length to keep"
require_var maxlen $minlen "Maximum length to keep"
require_file $silva
require_program fas_extract_range.rb
require_program fas_ungap.rb
require_program fas_extract_by_taxonomy.rb
require_program fas_lenfilter.rb

# find region corresponding to primers
fpos=$(./find_primer_in_alignment.rb -v -e $f_primer $silvaaln -o)
rpos=$(./find_primer_in_alignment.rb -v -e -r $r_primer $silvaaln -o)

# extract Silva alignment region
outf1=${silva}.pos_${fpos}_to_${rpos}
fas_extract_range.rb $fpos $rpos $silvaaln > $outf1
require_file $outf1

# remove gaps
outf2=${outf1}.ungapped
fas_ungap.rb $outf1 > $outf2
require_file $outf2

# keep Bacteria only
outf3=${outf2}.B
fas_extract_by_taxonomy.rb $silvatax D_0__Bacteria $outf2 > $outf3
require_file $outf3

# length selection
outf4=${outf3}.length_${minlen}_to_${maxlen}
fas_lenfilter.rb $outf3 $minlen | \
    fas_lenfilter.rb -k /dev/stdin $maxlen > $outf4
require_file $outf4
