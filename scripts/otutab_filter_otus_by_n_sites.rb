#!/usr/bin/env ruby
require "gg_otutable"
require "gg_optparse"

# %-PURPOSE-%
purpose "Extract OTUs present in at least n sites"
positional :otutab, :type => :infile,
  :help => "Input file, classic Qiime OTU table"
positional :n_sites, :type => :natural
switch :elim_unclassified,
  :help => "Eliminate OTU with ID \"unclassified\""
optparse!

t = OtuTable.from_tsv_file(@otutab)
otus_to_keep = []
t.otus.each do |otu|
  (otus_to_keep << otu) if t.n_sites(otu) >= @n_sites
end

if @elim_unclassified
 otus_to_keep.delete(:unclassified)
end

def perc_str(part,all)
  "%.2f%%" % ((part.to_f/all.to_f)*100)
end

def compute_stats(t)
  t_count = t.sites.map {|site|t.total_count(site)}.inject(0){|a,b|a+b}
  n_otus = t.otus.size
  return t_count, n_otus
end

t_count_all, n_otus_all = compute_stats(t)
t.retain_only_otus!(otus_to_keep)
t_count, n_otus = compute_stats(t)

STDERR.puts "N.OTUs\t%\tCounts\t%"
STDERR.puts "#{n_otus}\t#{perc_str(n_otus,n_otus_all)}"+
    "\t#{t_count}\t#{perc_str(t_count,t_count_all)}"

puts t.to_tsv
