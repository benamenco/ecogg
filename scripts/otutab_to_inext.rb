#!/usr/bin/env ruby

require "gg_optparse"
require "gg_otutable"

# %-PURPOSE-%
purpose "Convert OTU table in the iNEXT input format."
positional "otu_table", :type => :infile
optparse!

puts OtuTable.from_tsv_file(@otu_table).to_inext
