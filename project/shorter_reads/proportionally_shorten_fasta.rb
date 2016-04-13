#!/usr/bin/env ruby
require "gg_optparse"
require "gg_fasta"
# %-PURPOSE-%
purpose "Shorten Fasta sequences proportionally to their length"
positional :infile, :type => :infile, :fileclass => FastaFile
positional :proportion, :type => :portion
optparse!

@infile.each do |unit|
  final_length = (unit.length * @proportion).to_i
  unit.seq = unit.seq[0..final_length-1]
  puts unit
end
