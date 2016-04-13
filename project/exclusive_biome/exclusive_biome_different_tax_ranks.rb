#!/usr/bin/env ruby

require "gg_optparse"
option :outsep, "\t"
optparse!

Fileprefix = %W{phylum class order family genus}
Dirsuffix  = %W{phylum class order family genus}

text = {
    "friedline" => "Eastern Atlantic study",
    "sogin"     => "Northern Atlantic study",
    "gibbons"   => "Western English Channel study",
    "tara"      => "TARA study",
    "ouroo"       => "our open ocean deep-sea southern Atlantic sample"
  }

vents = %W{WA1 WA2 C D FC SP L1 L2 L3 L5 I2A I2B I2C I2D N}
classified_percent = {}
Fileprefix.each do |rank|
  f = File.open("H2.vents_vs_ouroo/#{rank}_table_mc1_w_tax.classic.stats")
  classified = 0
  unclassified = 0
  f.each do |line|
    elems = line.chomp.split("\t")
    if vents.include?(elems[0])
      classified += elems[1].to_f
      unclassified += elems[3].to_f
    end
  end
  percent = ("%.1f%%" % (classified * 100 /
                         (classified + unclassified)))
  classified_percent[rank] = percent
  f.close
end

elems = [""]
Fileprefix.each do |rank|
  elems << rank
end
puts elems.join(@outsep)
elems = [""]
Fileprefix.each do |rank|
  elems << classified_percent[rank]
end
puts elems.join(@outsep)

text.keys.each do |study|
  elems = [text[study]]
  Fileprefix.size.times do |i|
    if study == "tara"
      filename = "../tara/#{Fileprefix[i]}.results/#{Fileprefix[i]}.stats.tsv"
      next unless File.exists?(filename)
      value = `grep -P "not_in_tara" #{filename} | sed s/%//g | sumfield 5`
      elems << ("%.1f%%" % value.to_f)
    else
      filename = "H2.vents_vs_#{study}.#{Dirsuffix[i]}/#{Fileprefix[i]}.stats"
      next unless File.exists?(filename)
      line = `grep -P "^vents_exclusive\\t" #{filename}`
      elems << ("%.1f%%" % line.chomp.split("\t")[8].to_f)
    end
  end
  puts elems.join(@outsep)
end
