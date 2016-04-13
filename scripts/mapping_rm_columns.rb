#!/usr/bin/env ruby
require "gg_optparse"
require "gg_qiime_mapping"

# %-PURPOSE-%
purpose "Remove a column from a Qiime mapping file"
positional :mapping, :type => :infilename
allothers :columns, :required => true
optparse!

m = QiimeMapping.new(@mapping)
@more_columns.each do |column|
  if !m.has_field?(column)
    optparse_die "Column not found: #{column}\n"+
                 "Columns: #{m.fieldnames.inspect}"
  end
  m.delete_field(column)
end
puts m
