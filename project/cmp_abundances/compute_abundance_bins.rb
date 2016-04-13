#!/usr/bin/env ruby
require "gg_optparse"

levels = [:genera, :rbotus, :dnotus]
positional :level, :help=> levels.join(" or ")
option :report_limit, 10000000
optparse!
@level=@level.to_sym
optparse_die "unknown level" unless levels.include?(@level)

counts = {}
counts[:shared] = []
counts[:exclusive] = []

fn = {:genera => {}, :rbotus => {}, :dnotus => {}}
fn[:genera][:shared]="../sent/File0085.genus.in_vents.in_one_oo.tsv"
fn[:rbotus][:shared]="../sent/File0084.otus.in_vents.in_one_oo.tsv"
fn[:genera][:exclusive]="../tara/genus.results/genus.in_vents.not_in_our_oo.not_in_other_oo.not_in_tara.classic"
fn[:rbotus][:exclusive]="../tara/otus.results/otus.in_vents.not_in_our_oo.not_in_other_oo.not_in_tara.classic"
fn[:dnotus][:exclusive]="../downstream.W4/H2.vents_vs_ouroo/otu_table_mc1_w_tax.collapsed.classic.denovo.exclusive_Not-OpenOcean"
fn[:dnotus][:shared]="../downstream.W4/H2.vents_vs_ouroo/otu_table_mc1_w_tax.collapsed.classic.denovo.shared"

maxcount = {:shared => 0, :exclusive => 0}
[:shared, :exclusive].each do |set|
  vent_indices = []
  ncounts = 0
  sumcounts = 0
  file = File.open(fn[@level][set])
  file.each do |line|
    elems=line.split("\t")
    if line[0] == "#"
      %W{WA1 WA2 C D FC SP L1 L2 L3 L5 I2A I2B I2C I2D N Not-OpenOcean}.each do |site|
        i = elems.index(site)
        if !i.nil?
          vent_indices << i
        end
      end
    else
      total_count = 0
      vent_indices.each do |i|
        total_count += elems[i].to_f
      end
      if total_count >= @report_limit and set == :exclusive
        puts "# abundant exclusive found (#{total_count}): #{line.chomp}"
      end
      counts[set] << total_count
      if total_count > maxcount[set]
        maxcount[set] = total_count
      end
      ncounts += 1
      sumcounts += total_count
    end
  end
  puts "# #{set} max count: #{maxcount[set]}"
  puts("# #{set} average count: %.2f" % (sumcounts.to_f/ncounts))
  puts "# #{set} total count: #{sumcounts}"
  puts "# #{set} n counts: #{ncounts}"
end

counts[:shared].sort!
counts[:exclusive].sort!

1.upto(7) do |n|
  lower_limit=10**(n-1)
  limit=10**n
  sumcounts = {}
  [:shared, :exclusive].each do |set|
    sumcounts[set] = 0
    counts[set].each do |count|
      break if count >= limit
      sumcounts[set] += count if count >= lower_limit
    end
  end
  puts [limit,sumcounts[:shared],sumcounts[:exclusive],sumcounts[:shared].to_f/(sumcounts[:shared]+sumcounts[:exclusive])].join("\t")
end

limit = maxcount[:exclusive]
all_shared = 0
large_shared = 0
n_all = 0
n_large = 0
counts[:shared].each do |count|
  all_shared+=count
  n_all+=1
  if count > limit
    large_shared+=count
    n_large+=1
  end
end
puts("# shared in units > max exclusive (count): #{large_shared} (%.2f %%)" %
     (large_shared.to_f/all_shared*100))
puts("# shared in units > max exclusive (n): #{n_large} (%.2f %%)" %
     (n_large.to_f/n_all*100))
