#!/usr/bin/env ruby
require "gg_optparse"
require "gg_qiime_mapping"

# %-PURPOSE-%
purpose "Show one or a set of columns from a Qiime mapping file."
note "The first column is by default included also if not specified."
positional :mapping, :type => :infilename, :help => "Qiime mapping file"
allothers :columns, :required => true,
  :type => :list, :help => "Columns name (in header)"
switch :remove_key_column
optparse!

m = QiimeMapping.new(@mapping)
@columns.each do |column|
  if !m.has_field?(column)
    optparse_die "Column not found: #{column}\n"+
                 "Columns: #{m.fieldnames.inspect}"
  end
end
m.fieldnames.dup.each do |m_column|
  next if @columns.include?(m_column) or
    ((m_column == m.keyname) and !@remove_key_column)
  m.delete_field(m_column)
end
puts m
