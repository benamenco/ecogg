#!/usr/bin/env ruby
require "gg_optparse"
require "gg_fasta"

# %-PURPOSE-%
purpose "Extract the range of each sequence defined by 0-based ruby string coordinates"
positional :from, :type => :integer
positional :to, :type => :integer
positional :infile, :type => :infile, :fileclass => FastaFile
optparse!

@infile.each do |u|
  u.seq = u.seq[@from..@to]
  puts u
end
