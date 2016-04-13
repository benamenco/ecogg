#!/usr/bin/env ruby
require "gg_otutable"

# %-PURPOSE-%
purpose="Merge multiple OTU/taxa tables"

usage=<<-end
#{purpose}
  Usage: #$0 <otu|taxa_table.classic.1> <otu|taxa_table.classic.2> [<otu|taxa_table.classic.3>...]+
end

if ARGV.size < 2
  STDERR.puts usage
  exit 1
end

t = OtuTable.from_tsv(ARGV.shift)
while !(next_t = ARGV.shift).nil?
  t += OtuTable.from_tsv(next_t)
end
puts t.to_tsv
