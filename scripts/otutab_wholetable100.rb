#!/usr/bin/env ruby

require "gg_otutable"

# %-PURPOSE-%
purpose="Compute relative counts to the entire OTU table."

usage=<<-end
#{purpose}
Usage: #$0 <otu_table.tsv>

Each site is scaled to the same total count,
which is 100 / number of sites.
end

if ARGV.size != 1
  STDERR.puts usage
  exit 1
end

otutabfn = ARGV[0]
otutab = OtuTable.from_tsv(otutabfn)
otutab.rescale(100.0/otutab.sites.size, false)
puts otutab.to_tsv rescue Errno::EPIPE
