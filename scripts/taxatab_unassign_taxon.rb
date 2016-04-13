#!/usr/bin/env ruby

require "gg_optparse"
positional :otutable, :type => :infile
positional :taxon

# %-PURPOSE-%
purpose "Moves OTU whose tax contains D_\d__<taxon> to the Unassigned bucket"
note "Unassigned bucket MUST come after any other OTU"
optparse!

elim = []

@otutable.each do |line|
  elems = line.chomp.split("\t")
  if line[0] == "#"
    if elems.size > 1
      (elems.size - 1).times {|i| elim[i] = 0.0}
    end
    puts line
  elsif line =~ /D_\d__#{Regexp.quote(@taxon)}/i
    counts = elems[1..-1].map {|n| Float(n)}
    counts.size.times {|i |elim[i] += counts[i]}
  elsif line =~ /^Unassigned/
    counts = elems[1..-1].map {|n| Float(n)}
    counts.size.times {|i |counts[i] += elim[i]}
    puts ([elems[0]]+counts).join("\t")
  else
    puts line
  end
end
