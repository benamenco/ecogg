#!/usr/bin/env ruby

include Math
require "gg_otutable.rb"

# %-PURPOSE-%
purpose="Compute alpha diversity for sites in an OTU table."

usage=<<-end

Usage: $0 <index> <table>

<table>: OTU table in a TSV based format, as follows:

# any line starting with # but not #OTU is a comment line
      SiteA  SiteB  SiteC ...
OTU1  count  count  count ...
OTU2  count  count  count ...
...

<index>: one of the following indices:
#{OtuTable::AlphaIndicesHelpMsg}
end

if ARGV.size != 2
  STDERR.puts usage
  exit 1
end

index = ARGV[0].to_sym
filename = ARGV[1]

table = OtuTable.from_tsv(filename)

if OtuTable.alpha_indices.include?(index)
  puts "#site\t#{index}"
  table.sites.each do |site|
    puts "#{site}\t#{table.send(index, site)}"
  end
else
  raise "Index #{index} not available."
end


