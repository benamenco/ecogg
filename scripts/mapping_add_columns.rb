#!/usr/bin/env ruby
require "gg_optparse"
require "gg_qiime_mapping"

# %-PURPOSE-%
purpose "Add one or multiple columns to a mapping file"
note "The additional data must be written into an additional file."
note "If the additional file contains data for samples not in the mapping file"
note "they will be ignored. If for some rows in the mapping file there is no"
note "information in the additional files, blank cells will be added."
positional :mapping, :type => :infilename
positional :additional_table, :type => :infilename
option :mapping_key, "SampleID",
  :help => "Mapping file column to use for merging"
option :additional_key, "SampleID",
  :help => "Additional file column to use for merging"
optparse!

m = QiimeMapping.new(@mapping, @mapping_key)
m.import_fields(@additional_table, @additional_key)
puts m
