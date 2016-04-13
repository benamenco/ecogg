#!/usr/bin/env ruby
require "gg_otutable"
t1 = 0.01
t2 = 0.05
if ARGV.size != 1
  STDERR.puts "Usage: #$0 <otu_table_classic>"
  STDERR.puts "Thresholds hardcoded to #{t1*100}% and #{t2*100}%"
  STDERR.puts "Rare: counts for all sites < #{t1*100}%"
  STDERR.puts "Middle: not rare, not frequent"
  STDERR.puts "Frequent: counts for at least one site > #{t2*100}%"
  STDERR.puts "Not-in-Subset: counts of special key not_in_subset"
  exit 1
end
fn=ARGV[0]
t = OtuTable.from_tsv(fn)
s = t.split_by_abundance(t1, t2)
s.keys.each do |freq|
  ofn = fn+".#{freq}"
  f = File.open(ofn, "w")
  f.puts(s[freq].to_tsv)
  f.close
  ofn2 = ofn+".seqs.summary.txt"
  `rm -f #{ofn2}`
  `biom summarize-table -i #{ofn} -o #{ofn2}`
  ofn2 = ofn+".otus.summary.txt"
  `rm -f #{ofn2}`
  `biom summarize-table --qualitative -i #{ofn} -o #{ofn2}`
end
