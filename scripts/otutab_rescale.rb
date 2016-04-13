#!/usr/bin/env ruby

require "gg_otutable"
require "gg_optparse"

float = ARGV.delete("-f")

# %-PURPOSE-%
purpose "Proportionally scale each site in otu_table to a total of <n> reads."
switch :float, :defstr => false,
  :help=> "use Float in resulting table (default: Integer)"
positional :otutable, :type => :infile
positional :nreads, :type => :positive_float
optparse!

otutab = OtuTable.from_tsv_file(@otutable)
otutab.rescale(@nreads, !@float)
puts otutab.to_tsv rescue Errno::EPIPE
