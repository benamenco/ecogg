#!/usr/bin/env ruby
require "gg_otutable"

# %-PURPOSE-%
purpose="Compute the total count for each OTU/taxon"

usage=<<-end
#{purpose}
  Usage: #$0 <otu|taxa_table.classic>
end

if ARGV.size != 1
  STDERR.puts usage
  exit 1
end

filename = ARGV.shift
table = OtuTable.from_tsv(filename)
table.merge_all_sites
puts table.to_tsv
