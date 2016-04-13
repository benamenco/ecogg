#!/usr/bin/env ruby
require "gg_otutable"

projectdir="/work/gi/coop/perner/mar-16s/"
ne="#{projectdir}/downstream.W4/H2.vents_vs_ouroo/otu_table_mc1_w_tax.classic"
shared_otus = []
exclusive_otus = []
shared_counts = []
exclusive_counts = []
t = OtuTable.from_tsv(ne)
t.sites.size.times do |i|
  exclusive_otus[i]   = 0
  exclusive_counts[i] = 0
  shared_otus[i]      = 0
  shared_counts[i]    = 0
end
oo_sn = t.site_number(:OO)
v_sites = t.sites - [:OO]
t.otus.each do |otu|
  oo_count = t.counts[otu][oo_sn]
  if oo_count > 0
    t.counts[otu].each_with_index do |c, sn|
      if sn != oo_sn
        if c > 0
          shared_otus[sn] += 1
          shared_counts[sn] += c
        end
      end
    end
  else
    t.counts[otu].each_with_index do |c, sn|
      if c > 0
        exclusive_otus[sn] += 1
        exclusive_counts[sn] += c
      end
    end
  end
end

all_otus = []
all_counts = []
t.sites.size.times do |i|
  all_otus[i] = exclusive_otus[i] + shared_otus[i]
  all_counts[i] = exclusive_counts[i] + shared_counts[i]
end

rel_shared_otus = []
rel_exclusive_otus = []
rel_shared_counts = []
rel_exclusive_counts = []

t.sites.size.times do |i|
  rel_exclusive_counts[i] = "%.1f" % ( exclusive_counts[i].to_f * 100 / all_counts[i].to_f )
  rel_exclusive_otus[i]   = "%.1f" % ( exclusive_otus[i].to_f   * 100 / all_otus[i].to_f   )
  rel_shared_counts[i]    = "%.1f" % ( shared_counts[i].to_f    * 100 / all_counts[i].to_f )
  rel_shared_otus[i]      = "%.1f" % ( shared_otus[i].to_f      * 100 / all_otus[i].to_f   )
end

puts %w{
  #site
  otus_excl
  %\ vent
  otus_excl_count
  %\ vent
  otus_sh
  %\ vent
  otu_sh_count
  %\ vent
}.join("\t")

t.sites.each_with_index do |site, i|
  next if i == oo_sn
  puts [site,
   exclusive_otus[i],
   rel_exclusive_otus[i],
   exclusive_counts[i],
   rel_exclusive_counts[i],
   shared_otus[i],
   rel_shared_otus[i],
   shared_counts[i],
   rel_shared_counts[i],
  ].join("\t")
end
