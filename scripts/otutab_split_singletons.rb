#!/usr/bin/env ruby

require "gg_otutable"
require "gg_optparse"

# %-PURPOSE-%
purpose "Split OTU table into singletons and non-singletons"
note "Input/output format: Qiime OTU table"
note "Output files: <input>.1 (singletons) and <input>.2 (non-singletons)"
positional :input, :type => :infile,
  :outfiles => {:singletons => ".1", :multitons => ".2"}
force_switch
verbose_switch
optparse!

t=OtuTable.from_tsv_file(@input)
t_singletons = t.extract_total_singletons
t_multitons = t.extract_non_total_singletons
@singletons.puts(t_singletons.to_tsv)
@multitons.puts(t_multitons.to_tsv)
if @verbose
  t_singletons.name = "Singletons"
  STDERR.puts t_singletons.inspect
  STDERR.puts
  t_multitons.name = "Non-Singletons"
  STDERR.puts t_multitons.inspect
end
