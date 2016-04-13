#!/usr/bin/env ruby
require "gg_optparse"
require "gg_otutable"
require "set"

Ranks = %W{kingdom phylum class order family genus otus}
Plurals = %W{kingdoms phyla classes orders families genera otus}

purpose "Compare Tara bacteria with vents bacteria"
switch :stats_by_region, :short => "r"
positional :rank
optparse!

stats = {}
stats[:otus] = Hash.new {0}
stats[:counts] = Hash.new {0}

plural = Plurals[Ranks.index(@rank)]

if @rank != "otus"
  tara_ot = OtuTable.from_tsv("#{@rank}_tara.classic")
else
  tara_ot = OtuTable.from_tsv("miTAG.taxonomic.profiles.release.classic")
end

tara_sites = tara_ot.sites.to_set

by_region = {}
taramap = File.open("Table_W1.tsv")
taramap_header = taramap.readline
taramap.each do |line|
  elems = line.chomp.split("\t")
  site = elems[0]
  if tara_sites.include?(site.to_sym)
    elems[-2] =~ /^\((.*)\)/
    key = $1
    raise if $1.nil?
    by_region[key] ||= Set.new
    by_region[key] << elems[0].to_sym
  end
end
taramap.close

our_ots = {}
our_ots[:ve] = OtuTable.from_tsv("#{@rank}.vents_exclusive.tsv",
                                 :metadata => [:Sites])
our_ots[:bo] = OtuTable.from_tsv("#{@rank}.shared.both_oo.tsv",
                                 :metadata => [:Sites])
our_ots[:ot] = OtuTable.from_tsv("#{@rank}.shared.other_oo.tsv",
                                 :metadata => [:Sites])
our_ots[:ou] = OtuTable.from_tsv("#{@rank}.shared.our_oo.tsv",
                                 :metadata => [:Sites])

desc = {}
desc[:ve] = "in_vents.not_in_our_oo.not_in_other_oo"
desc[:ou] = "in_vents.in_our_oo.not_in_other_oo"
desc[:ot] = "in_vents.not_in_our_oo.in_other_oo"
desc[:bo] = "in_vents.in_our_oo.in_other_oo"

v_sites = [:C, :SP, :L5, :N, :FC, :L2, :L3, :L1, :I2A, :I2B, :I2C, :I2D,
           :WA2, :WA1, :D].to_set

dir="#{@rank}.results"
`mkdir -p #{dir}`

our_ots.each_pair do |ot_key, our_ot|
  otus_tara = []
  otus_nontara = []
  our_ot.otus.each do |otu|
    otu_our_sites = our_ot.otu_sites(otu).to_set
    otu_v_sites = otu_our_sites & v_sites
    if otu_v_sites.empty?
      next
    else
      stats[:otus][:all_in_vents]+=1
      v_count = our_ot.otu_counts_for_sites(otu,v_sites.to_a).inject(0){|a,b|a+b}
      stats[:counts][:all_in_vents]+=v_count
      otu_tara_sites = tara_ot.otu_sites(otu).to_set
      if !otu_tara_sites.empty?
        otus_tara << otu
        otu_tara_regions = []
        by_region.each_pair do |region, region_sites|
          otu_region_sites = (otu_tara_sites & region_sites)
          tara_region_count = 0
          if !otu_region_sites.empty?
            tara_region_count = tara_ot.otu_counts_for_sites(
              otu,otu_region_sites.to_a).inject(0){|a,b|a+b}
            otu_tara_regions << region
            if @stats_by_region
              stats[:otus][:"#{desc[ot_key]}.in_tara_#{region}"]+=1
              stats[:counts][:"#{desc[ot_key]}.in_tara_#{region}"]+=v_count
            end
          end
          our_ot.add_metadata_for_otu(otu, region.to_sym, tara_region_count)
        end
        our_ot.add_metadata_for_otu(otu, :Sites,
                                    (our_ot.metadata[:Sites][otu].split(",") +
                                    otu_tara_regions).join(","))
        if !@stats_by_region
          stats[:otus][:"#{desc[ot_key]}.in_tara"]+=1
          stats[:counts][:"#{desc[ot_key]}.in_tara"]+=v_count
        end
      else
        otus_nontara << otu
        stats[:otus][:"#{desc[ot_key]}.not_in_tara"]+=1
        stats[:counts][:"#{desc[ot_key]}.not_in_tara"]+=v_count
        by_region.keys.each do |region|
          our_ot.add_metadata_for_otu(otu, region.to_sym, 0)
        end
      end
    end
  end

  [true, false].each do |is_tara|
    fn = "#{dir}/#{@rank}.#{desc[ot_key]}.#{is_tara ? "" : "not_" }in_tara.classic"
    f = File.new(fn, "w")
    extracted = our_ot.dup.retain_only_otus!(is_tara ? otus_tara : otus_nontara)
    f.puts extracted.to_tsv(:sorted => true)
    f.close
    `otutab_divide_taxonomy_column.rb -a #{fn} > #{fn}.td.tsv`
  end
end

def perc(part, all)
  "%.1f%%" % (part.to_f * 100 / all)
end

statsfile = File.new("#{dir}/#{@rank}.stats.tsv", "w")
statsfile.puts ["Category", plural[0].upcase + plural[1..-1],
                "% all vent #{plural}",
                "Vent counts", "% all vent counts"].join("\t")
stats[:otus].each_pair do |k,v|
  out = ["# #{k}",v]
  out << perc(v, stats[:otus][:all_in_vents])
  if stats[:counts][k]
    out << stats[:counts][k]
    out << perc(stats[:counts][k], stats[:counts][:all_in_vents])
  end
  statsfile.puts out.join("\t")
end
statsfile.close
