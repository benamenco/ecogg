#!/usr/bin/env ruby
require "gg_optparse"
require "gg_qiime_mapping"

# %-PURPOSE-%
purpose "Show information about a Qiime mapping file"
positional :mapping, :type => :infilename
optparse!

m = QiimeMapping.new(@mapping)
puts m.inspect
