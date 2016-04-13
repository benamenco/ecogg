#!/usr/bin/env ruby
require "gg_optparse"
require "gg_fasta"

# %-PURPOSE-%
purpose "Transform a Fasta file from VAMPS into Qiime allsamples.fna"
positional :infilename, :help => ["Input file, Fasta",
  "Description line format: "+
  "ReadID|Project|Dataset|GASTDistancen_and_taxonomy|Count"]
note "The output contains the same sequences as the input."
note "Each sequence is output <Count> times."
note "The FastaIDs are replaced by <Dataset>_<counter> where"
note "<counter> is an incremental counter by default starting from 1."
option :counterstart, 1, :type => :natural, :help => "First value of counter"
optparse!

f = FastaFile.new(@infilename)
outseqnum=@counterstart-1
f.each do |unit|
  elems=unit.desc[1..-1].split("|")
  read_id=elems[0]
  dataset=elems[2]
  count=Integer(elems[4])
  count.times do
    outseqnum+=1
    outdesc = ">#{dataset}_#{outseqnum} #{read_id}"
    puts outdesc
    puts unit.seq
  end
end
