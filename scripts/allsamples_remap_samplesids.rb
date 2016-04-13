#!/usr/bin/env ruby

require "gg_fasta"
require "gg_optparse"

#%-PURPOSE-%
purpose "Change sequence IDs in Qiime allsamples.fna"
positional :input, :help => "Fasta file, allsamples.fna"
positional :map, :type => :infile, :help => "OldSampleID<TAB>NewSampleID map"
optparse!

map = {}
@map.each do |line|
  elems=line.chomp.split("\t")
  raise unless elems.size == 2
  map[elems[0]] = elems[1]
end

FastaFile.new(@input).each do |unit|
  map.each_pair do |k, v|
    unit.desc.gsub!(/^>#{k}/, ">#{v}")
  end
  puts unit
end
