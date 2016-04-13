#!/usr/bin/env ruby
require "gg_otutable"

# %-PURPOSE-%
purpose="Remove a site in an OTU table"

usage=<<-end
#{purpose}
  Usage: #$0 <otu_table.tsv> <site-name>
end

if ARGV.size != 2
  STDERR.puts usage
  exit 1
end

filename = ARGV[0]
site = ARGV[1]
table = OtuTable.from_tsv(filename)
table.rm_site(site)
puts table.to_tsv
