#!/usr/bin/env ruby

require "gg_optparse"
require "gg_otutable"

# %-PURPOSE-%
purpose "Extract significant correlation results and combine with OTU counts"
positional :correlations, :type => :infile, :help => "Correlation results"
positional :otutable, :type => :infile, :help => "OTU table"
option :alpha, 0.05, :help => "Significance level, max pval_fdr"
optparse!

interesting_columns = ["Test stat.", "pval_fdr"]
header = @correlations.gets.chomp.split("\t")
interesting_columns_n = interesting_columns.map {|str| header.index(str)}
pval_n = header.index("pval_fdr")

data = {}

@correlations.each do |line|
  elems = line.chomp.split("\t")
  pval = Float(elems[pval_n])
  if pval <= @alpha
    data[elems[0].to_sym] = interesting_columns_n.map{|i| elems[i]}
  end
end
@correlations.close

t = OtuTable.from_tsv_file(@otutable)
t.retain_only_otus!(data.keys)
data.each do |otu, metadata|
  interesting_columns.each_with_index do |key, i|
    value = metadata[i]
    t.add_metadata_for_otu(otu, key.to_sym, value)
  end
  t.add_metadata_for_otu(otu, "n_sites", t.n_sites(otu))
end
puts t.to_tsv
