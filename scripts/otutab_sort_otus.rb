#!/usr/bin/env ruby
require "gg_optparse"
require "gg_otutable"

# %-PURPOSE-%
purpose "Sort OTUs in OTU table by total count"
positional :otutable, :type => :infile
optparse!

t = OtuTable.from_tsv_file(@otutable)
puts t.to_tsv(:sorted => true)
