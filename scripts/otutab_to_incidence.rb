#!/usr/bin/env ruby
require "gg_otutable"

# %-PURPOSE-%
purpose="Change abundance to incidence (0 or 1)."

usage=<<-end
#{purpose}
Usage: #$0 [--maxzero <n>] <otu_table.tsv>

Options:
  --maxzero <n>: set to 1 if count > n (default: 0)
end

def set_max_zero
  max_zero = 0
  i = ARGV.index("--maxzero")
  if i
    max_zero = Integer(ARGV[i+1]) rescue max_zero = nil
    ARGV[i]=nil
    ARGV[i+1]=nil
    ARGV.compact!
  end
  max_zero
end

max_zero = set_max_zero()
if ARGV.size != 1 or max_zero.nil?
  STDERR.puts usage
  exit 1
end
otutabfn = ARGV[0]

otutab = OtuTable.from_tsv(otutabfn)
otutab.counts.each do |k,counts_for_k|
  counts_for_k.each_with_index do |c,i|
    counts_for_k[i] = c > max_zero ? 1 : 0
  end
end

puts otutab.to_tsv rescue Errno::EPIPE
