#!/usr/bin/env ruby

require "gg_optparse"
option :outsep, "\t"
optparse!

vents = %W{WA1 WA2 C D FC SP L1 L2 L3 L5 I2A I2B I2C I2D N}
ranks = %W{phylum class order family genus}

def filename(rank)
  "H2.vents_vs_ouroo/#{rank}_table_mc1_w_tax.classic.stats"
end

ranks.each do |rank|
  f = File.open(filename(rank))
  classified = 0
  unclassified = 0
  f.each do |line|
    elems = line.chomp.split("\t")
    if vents.include?(elems[0])
      classified += elems[1].to_f
      unclassified += elems[3].to_f
    end
  end
  percent = ("%.1f%%" % (classified * 100 / (classified + unclassified)))
  puts [rank, percent].join(@outsep)
  f.close
end
