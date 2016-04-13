#!/usr/bin/env ruby
require "gg_otutable"
require "gg_optparse"
purpose "Merge all sites of an OTU table"
positional :otutable, :type => :infile
optparse!
t = OtuTable.from_tsv_file(@otutable)
t.merge_all_sites
puts t.to_tsv
