#!/usr/bin/env ruby

require "gg_otutable"

# %-PURPOSE-%
purpose="Remove OTUs with a total count of zero from otu table"

if ARGV.size != 1
  STDERR.puts purpose
  STDERR.puts "Usage: #$0 <otu_table_classic format>"
  exit 1
end

t=OtuTable.from_tsv(ARGV[0])
t.rm_allzero!
puts t.to_tsv
