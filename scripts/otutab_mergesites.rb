#!/usr/bin/env ruby
require "gg_otutable"


# %-PURPOSE-%
purpose="Merge sites in an OTU table."

usage=<<-end
#{purpose}
  Usage: #$0 <otu_table.tsv> <merged-site-name> <site1> <site2> [<site3>]...
end

if ARGV.size < 4
  STDERR.puts usage
  exit 1
end

filename = ARGV.shift
new_site = ARGV.shift
sites = ARGV
table = OtuTable.from_tsv(filename)
table.merge_sites(sites, new_site)
puts table.to_tsv
