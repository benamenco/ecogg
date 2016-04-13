#!/usr/bin/env ruby
require "gg_optparse"
purpose "Convert Sunagawa et al OTU table into Qiime format"
positional :tara_otutab, :type => :infile
optparse!

header = @tara_otutab.readline.chomp.split("\t")
# Domain\tPhylum\tClass\tOrder\tFamily\tGenus\tOTU.rep\tTARA*
raise unless header[0]=="Domain"

unclassified = @tara_otutab.readline.chomp.split("\t")
raise unless unclassified[0]=="undef"

header << "taxonomy"
header[6] = "#OTU ID"
puts header[6..-1].join("\t")

# D_0__Bacteria; D_1__..
def taxstring(taxelems)
  str = ""
  taxelems.each_with_index do |x, i|
    break if x.empty?
    str << "; " if !str.empty?
    str << "D_#{i}__#{x}"
  end
  str
end

@tara_otutab.each do |line|
  elems = line.chomp.split("\t")
  elems << taxstring(elems[0..5])
  puts elems[6..-1].join("\t")
end

