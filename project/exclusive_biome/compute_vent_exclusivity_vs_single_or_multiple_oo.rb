#!/usr/bin/env ruby
#merge the following tables:
#- Vents w/o Irina2E (HV)
#- OpenOcean
#
#- Gibbons
#- Friedline
#- Sogin ohne FS
#
#For each OTU:
#- is it vent-exclusive?
#- is it open-ocean-exclusive?
#- is it in both?
#- in which sites is it contained => add to metadata

Ranks = %W{kingdom phylum class order family genus rbotu}
Units = %W{Kingdoms Phyla Classes Orders Families Genera rbOTUs}

require "gg_otutable"
require "gg_optparse"
require "gg_logger"
switch :wo_our_open_ocean
switch :only_our_open_ocean
switch :only_friedline, :short => "f"
switch :only_sogin, :short => "s"
switch :only_gibbons, :short => "l"
switch :compare_open_oceans
verbose_switch
positional :outdir
positional :rank, :type => :list, :allowed => Ranks
optparse!

if @wo_our_open_ocean and @only_our_open_ocean
  optparse_die "wo_our_open_ocean incompatible to only_our_open_ocean"
end
if @wo_our_open_ocean and @compare_open_oceans
  optparse_die "wo_our_open_ocean incompatible to compare_open_oceans"
end
if @only_our_open_ocean and @compare_open_oceans
  optparse_die "only_our_open_ocean incompatible to compare_open_oceans"
end

`mkdir -p #@outdir`

# merge NE with Gibbons/Friedline/Sogin
projectdir="/work/gi/coop/perner/mar-16s/"

if @rank != "rbotu"
  ne="#{projectdir}/downstream.W4/H2.vents_vs_ouroo/#{@rank}_table_mc1_w_tax.classic"
  gib="#{projectdir}/downstream.gibbons/G2/pick_otus.G2/#{@rank}_table_mc1_w_tax.classic"
  fri="#{projectdir}/downstream.friedline/F2/pick_otus.F2/#{@rank}_table_mc1_w_tax.classic"
  sog="#{projectdir}/downstream.sogin/S2/pick_otus.S2/#{@rank}_table_mc1_w_tax.classic"
else
  ne="#{projectdir}/downstream.W4/H2.vents_vs_ouroo/otu_table_mc1_w_tax.classic.refbased"
  gib="#{projectdir}/downstream.gibbons/G2/pick_otus.G2/otu_table_mc1_w_tax_newids.classic.refbased"
  fri="#{projectdir}/downstream.friedline/F2/pick_otus.F2/otu_table_mc1_w_tax.newids.classic.refbased"
  sog="#{projectdir}/downstream.sogin/S2/pick_otus.S2/otu_table_mc1_w_tax.newids.classic.refbased"
end

if @only_friedline or @only_sogin or @only_gibbons
  @wo_our_open_ocean = true
end

t_ne = OtuTable.from_tsv(ne)
if @wo_our_open_ocean
  vlog("Do not use our Open Ocean")
  t_ne.rm_site(:OO)
  t_ne.rm_allzero!
end

use_gibbons   = (!@only_our_open_ocean) && (!@only_friedline) && (!@only_sogin)
use_friedline = (!@only_our_open_ocean) && (!@only_sogin    ) && (!@only_gibbons)
use_sogin     = (!@only_our_open_ocean) && (!@only_friedline) && (!@only_gibbons)

taxsrc="/work/gi/databases/qiime-data/silva/Silva119_release/taxonomy/97/taxonomy_97_7_levels.txt"
t_ne.set_alternative_taxonomy_source_for_merging(taxsrc)
if use_gibbons
  vlog("Use Gibbons")
  t_gib = OtuTable.from_tsv(gib)
  t_ne_gib = t_ne + t_gib
  t_ne_gib.set_alternative_taxonomy_source_for_merging(taxsrc)
else
  vlog("Do not use Gibbons")
  t_ne_gib = t_ne
end
if use_friedline
  vlog("Use Friedline")
  t_fri = OtuTable.from_tsv(fri)
  t_ne_gib_fri = t_ne_gib + t_fri
  t_ne_gib_fri.set_alternative_taxonomy_source_for_merging(taxsrc)
else
  vlog("Do not use Friedline")
  t_ne_gib_fri = t_ne_gib
end
if use_sogin
  vlog("Use Sogin")
  t_sog = OtuTable.from_tsv(sog)
  t_sog.rm_site(:FS312)
  t_sog.rm_site(:FS396)
  t_sog.rm_allzero!
  t_ngfs = t_ne_gib_fri + t_sog
else
  vlog("Do not use Sogin")
  t_ngfs = t_ne_gib_fri
end

our_o_sites = [:OO]
gibbons_sites = [:"I1.631407"]
friedline_sites = [:AOT6, :AOT12, :AOT16, :AOT1, :AOT11, :AOT15,
           :AOT3, :AOT14, :AOT4, :AOT8, :AOT9, :AOT13, :AOT2, :AOT7, :AOT10,
           :AOT5]
sogin_sites = [:"115R", :"137", :"138", :"53R", :"55R", :"112R"]
other_o_sites = gibbons_sites + friedline_sites + sogin_sites
o_sites = our_o_sites + other_o_sites
v_sites = [:C, :SP, :L5, :N, :FC, :L2, :L3, :L1, :I2A, :I2B, :I2C, :I2D,
           :WA2, :WA1, :D]

otus = {:o => [], :v => [], :s => []}

if @compare_open_oceans
  vlog("Compare Open Oceans")
  otus[:s_our] = []
  otus[:s_other] = []
  otus[:s_both] = []
  otus[:o_our] = []
  otus[:o_other] = []
  otus[:o_both] = []
end

t_ngfs.otus.each do |otu|
  next if @rank != "rbotu" and otu == :unclassified
  otu_sites = t_ngfs.otu_sites(otu)
  if otu_sites.all?{|site|o_sites.include?(site)}
    otus[:o] << otu
    if @compare_open_oceans
      if otu_sites.all?{|site|our_o_sites.include?(site)}
        otus[:o_our] << otu
      elsif otu_sites.all?{|site|other_o_sites.include?(site)}
        otus[:o_other] << otu
      else
        otus[:o_both] << otu
      end
    end
  elsif otu_sites.all?{|site|v_sites.include?(site)}
    otus[:v] << otu
  else
    otus[:s] << otu
    if @compare_open_oceans
      if otu_sites.all?{|site|v_sites.include?(site) or our_o_sites.include?(site)}
        otus[:s_our] << otu
      elsif otu_sites.all?{|site|v_sites.include?(site) or other_o_sites.include?(site)}
        otus[:s_other] << otu
      else
        otus[:s_both] << otu
      end
    end
  end
  t_ngfs.add_metadata_for_otu(otu, "Sites", otu_sites.join(","))
end

pfx=@rank

n_otus_o = {}
n_seqs_o = {}

t_o = t_ngfs.dup.retain_only_otus!(otus[:o])
n_otus_o[:all] = otus[:o].size
n_seqs_o[:all] = t_o.overall_count

if @compare_open_oceans
  [:our, :other, :both].each do |oo_type|
    fn_o = "#@outdir/#{pfx}.oo_exclusive.#{oo_type}_oo.tsv"
    f_o = File.open(fn_o, "w")
    t_o = t_ngfs.dup.retain_only_otus!(otus[:"o_#{oo_type}"])
    n_otus_o[oo_type] = otus[:"o_#{oo_type}"].size
    n_seqs_o[oo_type] = t_o.overall_count
    f_o.puts t_o.to_tsv(:sorted => true)
    f_o.close
    `otutab_divide_taxonomy_column.rb -a #{fn_o} > #{fn_o}.td`
  end
else
  fn_o = "#@outdir/#{pfx}.oo_exclusive.tsv"
  f_o = File.open(fn_o, "w")
  f_o.puts t_o.to_tsv(:sorted => true)
  f_o.close
  `otutab_divide_taxonomy_column.rb -a #{fn_o} > #{fn_o}.td`
end

fn_v ="#@outdir/#{pfx}.vents_exclusive.tsv"
f_v = File.open(fn_v, "w")
t_v = t_ngfs.dup.retain_only_otus!(otus[:v])
n_otus_v = otus[:v].size
n_seqs_v = t_v.overall_count
f_v.puts t_v.to_tsv(:sorted => true)
f_v.close
`otutab_divide_taxonomy_column.rb -a #{fn_v} > #{fn_v}.td`

n_otus_s = {}
n_seqs_s_v = {}
n_seqs_s_o = {}

t_s = t_ngfs.dup.retain_only_otus!(otus[:s])
n_otus_s[:all] = otus[:s].size
n_seqs_s_v[:all] = t_s.overall_count(v_sites & t_s.sites)
n_seqs_s_o[:all] = t_s.overall_count(o_sites & t_s.sites)

if @compare_open_oceans
  [:our, :other, :both].each do |oo_type|
    fn_s = "#@outdir/#{pfx}.shared.#{oo_type}_oo.tsv"
    f_s = File.open(fn_s, "w")
    t_s = t_ngfs.dup.retain_only_otus!(otus[:"s_#{oo_type}"])
    n_otus_s[oo_type] = otus[:"s_#{oo_type}"].size
    n_seqs_s_v[oo_type] = t_s.overall_count(v_sites & t_s.sites)
    n_seqs_s_o[oo_type] = t_s.overall_count(o_sites & t_s.sites)
    f_s.puts t_s.to_tsv(:sorted => true)
    f_s.close
    `otutab_divide_taxonomy_column.rb -a #{fn_s} > #{fn_s}.td`
  end
else
  fn_s = "#@outdir/#{pfx}.shared.tsv"
  f_s = File.open(fn_s, "w")
  f_s.puts t_s.to_tsv(:sorted => true)
  f_s.close
  `otutab_divide_taxonomy_column.rb -a #{fn_s} > #{fn_s}.td`
end

n_otus_all = n_otus_o[:all] + n_otus_v + n_otus_s[:all]
n_otus_all_v = n_otus_v + n_otus_s[:all]
n_otus_all_o = n_otus_o[:all] + n_otus_s[:all]

n_seqs_all_v = n_seqs_v + n_seqs_s_v[:all]
n_seqs_all_o = n_seqs_o[:all] + n_seqs_s_o[:all]
n_seqs_all = n_seqs_all_v + n_seqs_all_o

def percstr(part, all)
  "%.2f%%" % (part.to_f * 100 / all)
end

f_stats = File.open("#@outdir/#{pfx}.stats", "w")
units=Units[Ranks.index(@rank)]
f_stats.puts "Class\t"+
             "N.#{units}\t(% all)\t(% vents)\t(% oo)\t"+
             "N.counts all\t(% all)\t"+
             "N.counts vents\t(% vents)\t"+
             "N.counts oo\t(% oo)"
oo_type = :all
f_stats.puts "oo_exclusive\t"+
  "#{n_otus_o[oo_type]}\t"+
  "#{percstr(n_otus_o[oo_type],n_otus_all)}\t"+
  "n.a.\t"+
  "#{percstr(n_otus_o[oo_type],n_otus_all_o)}\t"+
  "#{n_seqs_o[oo_type]}\t"+
  "#{percstr(n_seqs_o[oo_type],n_seqs_all)}\t"+
  "n.a.\t"+
  "n.a.\t"+
  "#{n_seqs_o[oo_type]}\t"+
  "#{percstr(n_seqs_o[oo_type],n_seqs_all_o)}"
f_stats.puts "vents_exclusive\t"+
  "#{n_otus_v}\t"+
  "#{percstr(n_otus_v,n_otus_all)}\t"+
  "#{percstr(n_otus_v,n_otus_all_v)}\t"+
  "n.a.\t"+
  "#{n_seqs_v}\t"+
  "#{percstr(n_seqs_v,n_seqs_all)}\t"+
  "#{n_seqs_v}\t"+
  "#{percstr(n_seqs_v,n_seqs_all_v)}\t"+
  "n.a.\t"+
  "n.a."
f_stats.puts "shared\t"+
  "#{n_otus_s[oo_type]}\t#{percstr(n_otus_s[oo_type],n_otus_all)}\t"+
  "#{percstr(n_otus_s[oo_type],n_otus_all_v)}\t"+
  "#{percstr(n_otus_s[oo_type],n_otus_all_o)}\t"+
  "#{n_seqs_s_o[oo_type] + n_seqs_s_v[oo_type]}\t"+
  "#{percstr(n_seqs_s_o[oo_type] + n_seqs_s_v[oo_type],n_seqs_all)}\t"+
  "#{n_seqs_s_v[oo_type]}\t"+
  "#{percstr(n_seqs_s_v[oo_type],n_seqs_all_v)}\t"+
  "#{n_seqs_s_o[oo_type]}\t"+
  "#{percstr(n_seqs_s_o[oo_type],n_seqs_all_o)}"
if @compare_open_oceans
  f_stats.puts
  [:our, :other, :both].each do |oo_type|
    f_stats.puts "oo_exclusive (#{oo_type}_oo)\t"+
      "#{n_otus_o[oo_type]}\t#{percstr(n_otus_o[oo_type],n_otus_all)}\tn.a.\t"+
      "#{percstr(n_otus_o[oo_type],n_otus_all_o)}\t"+
      "#{n_seqs_o[oo_type]}\t"+
      "#{percstr(n_seqs_o[oo_type],n_seqs_all)}\t"+
      "n.a.\t"+
      "n.a.\t"+
      "#{n_seqs_o[oo_type]}\t"+
      "#{percstr(n_seqs_o[oo_type],n_seqs_all_o)}"
  end
  f_stats.puts
  [:our, :other, :both].each do |oo_type|
    f_stats.puts "shared (#{oo_type}_oo)\t"+
      "#{n_otus_s[oo_type]}\t#{percstr(n_otus_s[oo_type],n_otus_all)}\t"+
      "#{percstr(n_otus_s[oo_type],n_otus_all_v)}\t"+
      "#{percstr(n_otus_s[oo_type],n_otus_all_o)}\t"+
      "#{n_seqs_s_o[oo_type] + n_seqs_s_v[oo_type]}\t"+
      "#{percstr(n_seqs_s_o[oo_type] + n_seqs_s_v[oo_type],n_seqs_all)}\t"+
      "#{n_seqs_s_v[oo_type]}\t"+
      "#{percstr(n_seqs_s_v[oo_type],n_seqs_all_v)}\t"+
      "#{n_seqs_s_o[oo_type]}\t"+
      "#{percstr(n_seqs_s_o[oo_type],n_seqs_all_o)}"
  end
end
f_stats.close
