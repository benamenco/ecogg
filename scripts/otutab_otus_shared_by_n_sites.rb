#!/usr/bin/env ruby
require "gg_otutable"

# %-PURPOSE-%
purpose="Output sites list of OTUs with count > 0 in exactly <n> sites"

if ARGV.size != 2
  STDERR.puts purpose
  STDERR.puts "Usage #$0 <otu|taxa_table.classic> <n>"
  STDERR.puts "If input is a taxa table, \"Other\" buckets are ignored."
  STDERR.puts "Output:"
  STDERR.puts "<otu|taxa>\tsite[\tsite...]"
  exit 1
end

t = OtuTable.from_tsv(ARGV[0])
n_samples = Integer(ARGV[1])
raise "n must be >= 1" if n_samples <= 0
t.taxatable_rm_other!
t.otus.each do |otu|
  otu_sites = t.otu_sites(otu)
  if otu_sites.size == n_samples
    otu_sites.unshift(otu.to_s)
    puts otu_sites.join("\t")
  end
end
