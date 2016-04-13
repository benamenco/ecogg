#!/usr/bin/env ruby

require "gg_fasta"
require "gg_optparse"

#%-PURPOSE-%
purpose "Compute statistics about a Qiime allsamples.fna file"
positional :input, :help => "Fasta file, allsamples.fna"
option :separator, "_",
  :help => ["String, whose first occurrence separates the sample name from",
           "the rest of the Fasta description line"]
optparse!

counts={}
total = [0,0]
FastaFile.new(@input).each do |unit|
  sampleID=unit.desc[1..-1].split(@separator)[0]
  counts[sampleID]||=[0,0]
  counts[sampleID][0]+=1
  counts[sampleID][1]+=unit.seq.length
  total[0]+=1
  total[1]+=unit.seq.length
end

puts "#sampleID\tsequences\tlength\tav.len"
counts.each_pair do |k,v|
  av = v[1].to_f/v[0]
  puts [k,v[0],v[1],av].join("\t")
end
total_av = total[1].to_f/total[0]
puts ["#total",total[0],total[1],total_av].join("\t")
