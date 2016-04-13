#!/usr/bin/env ruby

require "gg_otutable"
require "gg_optparse"

# %-PURPOSE-%
purpose="Show info about a classic Qiime OTU table"
positional :otutable, :type => :infile
option :metadata, [], :help => ["If a column contains metadata instead of",
                             "counts, it shall be indicated using this option.",
                             ""]
optparse!

otutab = OtuTable.from_tsv_file(@otutable, :name => @_otutable,
                                :metadata => @metadata)
puts otutab.inspect
