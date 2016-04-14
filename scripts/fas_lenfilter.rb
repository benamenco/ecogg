#!/usr/bin/env ruby
require "gg_fasta"
require "gg_optparse"

#%-PURPOSE-%
purpose "Filter Fasta sequences by length"
positional :input, :help => "Input file"
positional :length, :type => :natural, :help => "Length value (nt)"
switch :keep_small, :help => "Filter out sequence longer than <l>, not shorter"
switch :exact, :help => "Keep only sequences of exact length <l>"
note "Sequences of length <l> are always kept."
optparse!

if @exact and @keep_small
  optparse_die "--exact is not compatible to --keep_small"
end

FastaFile.new(@input).each do |unit|
  keep = (@exact and unit.seq.size == @length) ||
         (!@exact and (@keep_small and unit.seq.size <= @length) ||
                      (!@keep_small and unit.seq.size >= @length))
  if keep
    puts unit
  end
end
