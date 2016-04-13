#!/usr/bin/env ruby

require "gg_otutable"
require "gg_optparse"

float = ARGV.delete("-f")

# %-PURPOSE-%
purpose "Create a random subsample of an OTU table with a total of <n> reads."
note "Only tables with integer counts are supported!"
note "(your responsibility to check, the script does not do it)"
positional :otutable, :type => :infile
positional :nreads, :type => :positive
switch :keep_allzero
optparse!

otutab = OtuTable.from_tsv_file(@otutable)
if @nreads > otutab.overall_count
  STDERR.puts "nreads (#{@nreads}) shall be less than "+
    "the overall count (#{otutab.overall_count})"
end
otutab.random_subsample!(@nreads)
otutab.rm_allzero! unless @keep_allzero
puts otutab.to_tsv rescue Errno::EPIPE
