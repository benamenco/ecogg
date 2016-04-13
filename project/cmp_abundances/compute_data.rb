#!/usr/bin/env ruby
require "gg_optparse"

levels = [:genera, :rbotus, :dnotus]
positional :level, :help=> levels.join(" or ")
switch :absolute
switch :write_level, :short => :l
switch :ouronly
optparse!
@level=@level.to_sym
optparse_die "unknown level" unless levels.include?(@level)

data = {}
data[:fn] = {:genera => {}, :rbotus => {}, :dnotus => {}, :stats => {}}
data[:fn][:stats][:our] = "../downstream.W4/H2/pick_otus.H2/otu_table_mc1_w_tax.classic.stats"
data[:fn][:stats][:sogin] = "../downstream.sogin/S2/pick_otus.S2/otu_table_mc1_w_tax.biom.seqs.summary.txt"
data[:fn][:stats][:gibbons] = "../downstream.gibbons/G2/pick_otus.G2/otu_table_mc1_w_tax.biom.seqs.summary.txt"
data[:fn][:stats][:friedline] = "../downstream.friedline/F2/pick_otus.F2/otu_table_mc1_w_tax.biom.seqs.summary.txt"
data[:fn][:stats][:tara] = "../tara/otu_tara.classic.info"
data[:fn][:genera][:shared]="../sent/File0085.genus.in_vents.in_one_oo.tsv"
data[:fn][:genera][:exclusive]="../tara/genus.results/genus.in_vents.not_in_our_oo.not_in_other_oo.not_in_tara.classic"
data[:fn][:rbotus][:shared]="../sent/File0084.otus.in_vents.in_one_oo.tsv"
data[:fn][:rbotus][:exclusive]="../tara/otus.results/otus.in_vents.not_in_our_oo.not_in_other_oo.not_in_tara.classic"
data[:fn][:dnotus][:exclusive]="../downstream.W4/H2.vents_vs_ouroo/otu_table_mc1_w_tax.collapsed.classic.denovo.exclusive_Not-OpenOcean"
data[:fn][:dnotus][:shared]="../downstream.W4/H2.vents_vs_ouroo/otu_table_mc1_w_tax.collapsed.classic.denovo.shared"
data[:sites] = {:v =>
                {:our => %W{WA1 WA2 C D FC SP L1 L2 L3 L5 I2A I2B I2C I2D N},
                 :our2 => %W[Not-OpenOcean]},
                :o =>
                {:our => %W{OO},
                 :our2 => %W[OpenOcean]} }
unless @ouronly
  data[:sites][:o][:sogin] = %W{55R 53R 138 137 112R 115R}
  data[:sites][:o][:gibbons] = %W{I1.631407}
  data[:sites][:o][:friedline] = %W{AOT11 AOT15 AOT14 AOT8 AOT12 AOT16 AOT2 AOT6 AOT10 AOT5 AOT3 AOT13 AOT1 AOT4 AOT7 AOT9 }
  data[:sites][:o][:tara] = %W{NAO MS RS IO SAO SO SPO NPO}
end
data[:total_count_is_total_oo] = [:gibbons, :tara, :friedline]
data[:studies] = [:our, :gibbons, :tara, :friedline, :sogin]
if @level == :dnotus
  data[:studies] = [:our]
end

if @absolute
  total_count = {:v => 1, :o => 1}
else
  total_count = {:v => 0, :o => 0}
  data[:studies].each do |study|
    f = File.open(data[:fn][:stats][study])
    f.each do |line|
      elems=line.strip.chomp.split(/[\t:]/)
      if data[:total_count_is_total_oo].include?(study)
        if elems[0]=="Total count" or elems[0]=="Overall"
          total_count[:o] += elems[1].to_i
          break
        end
      else
        [:v,:o].each do |gr|
          if data[:sites][gr][study] and data[:sites][gr][study].include?(elems[0])
            total_count[gr] += elems[1].to_i
          end
        end
      end
    end
    f.close
  end
end

sites = {}
sites[:v] = data[:sites][:v].values.flatten
sites[:o] = data[:sites][:o].values.flatten

[:shared, :exclusive].each do |set|
  indices = {:v => [], :o => []}
  file = File.open(data[:fn][@level][set])
  file.each do |line|
    elems=line.split("\t")
    if line[0] == "#"
      [:v, :o].each do |grp|
        sites[grp].each do |site|
          if (i = elems.index(site))
            indices[grp] << i
          end
        end
      end
    else
      unit_count = {:v => 0.0, :o => 0.0}
      [:v, :o].each do |grp|
        indices[grp].each do |i|
          unit_count[grp] += elems[i].to_f
        end
        unit_count[grp] = unit_count[grp]/total_count[grp]
      end
      out = [unit_count[:v],unit_count[:o]]
      if @write_level
        out << @level
      end
      puts out.join("\t")
    end
  end
end
