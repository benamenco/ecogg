#!/usr/bin/env ruby
require "gg_otutable"

Other="Other"
Unclassified="Unclassified"

handle_other = ARGV.delete("-o")
keep = ARGV.delete("-k")

# %-PURPOSE-%
purpose="In Taxa tables (taxonomy-summarized OTU tables), change names to the lowest rank."

usage=<<-end
#{purpose}
Usage: #$0 [options] <otu_table.tsv>

If the option -k is used, the input OTU name is copied to an extra Taxonomy
column, otherwise it is deleted.

Handling of "#{Other}": by default, the OTUs where the last rank is
"#{Other}" are deleted.

If the option -o is used, these OTUs are kept, and a label is constructed
by joining "#{Other}" to the lowest non-#{Other} rank. An exception is
the #{Unclassified} lineage, for which #{Unclassified} is used instead
of #{Other} #{Unclassified}.
end

if ARGV.size != 1
  STDERR.puts usage
  exit 1
end

otutabfn = ARGV[0]
otutab = OtuTable.from_tsv(otutabfn)

def label_for_other(k)
  lineage = k.to_s.split(";")
  lineage.reverse.each_with_index do |t, i|
    return Unclassified if t == Unclassified and i == lineage.size - 1
    return "#{Other} #{t}" if t != Other
  end
  raise "OTU label error for #{k}"
end

new_counts = {}
otutab.create_taxonomy_column if keep
otutab.counts.each do |k,v|
  new_k = k.to_s.split(";").last
  if new_k == Other
    if handle_other
      new_k = label_for_other(k)
    else
      otutab.counts.delete(k)
      next
    end
  end
  raise "Double count for #{new_k}" if new_counts[new_k.to_sym]
  new_counts[new_k.to_sym] = v
  otutab.taxonomy[new_k.to_sym] = k if keep
  otutab.counts.delete(k)
end

otutab.counts.merge!(new_counts)

puts otutab.to_tsv rescue Errno::EPIPE
