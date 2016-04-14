#!/usr/bin/env ruby
require "gg_optparse"
require "gg_fasta"
require "gg_gap"
# %-PURPOSE-%
purpose "Remove gap symbols from all sequences in a MultiFasta file"
positional :infile, :type => :infile, :fileclass => FastaFile
optparse!
@infile.each do |u|
  u.seq = u.seq.ungap
  puts u unless u.length == 0
end
