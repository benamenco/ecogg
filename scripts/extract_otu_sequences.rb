#!/usr/bin/env ruby
require "gg_optparse"
require "gg_otumap"
require "gg_fasta"
require "gg_logger"

# %-PURPOSE-%
purpose "Extract all sequences of an OTU from a Fasta file"
option :exclude_sample_regexp
positional :otumap, :type => :infilename
positional :allsequences, :type => :infilename
positional :otuname
switch :idonly
verbose_switch
optparse!

fastaids = OtuMap.scan(@otumap,@otuname)
if fastaids.empty?
  optparse_die "OTU #{@otuname} not found in map #{@otumap}"
end
vlog "OTU consists of #{fastaids.size} sequences"

if @exclude_sample_regexp
  fastaids.reject! do |fastaid|
    fastaid.split("_")[0] =~ /#{@exclude_sample_regexp}/
  end
  vlog "After filtering OTU consists of #{fastaids.size} sequences"
end

if @idonly
  puts fastaids
else
  f = FastaFile.new(@allsequences)
  f.each do |unit|
    if fastaids.include?(unit.fastaid)
      puts unit
    end
  end
end
