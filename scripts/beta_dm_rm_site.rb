#!/usr/bin/env ruby
require "gg_optparse"
# %-PURPOSE-%
purpose "Rm site from beta distance matrix"
positional :input, :type => :infile
positional :site
optparse!

header=@input.gets.chomp.split("\t")
column=header.index(@site)
if !column
  STDERR.puts "Site #@site not found\tSites: #{header.inspect}"
  exit 1
end
header.delete_at(column)
puts header.join("\t")
@input.each do |line|
  elems = line.chomp.split("\t")
  elems.delete_at(column)
  puts elems.join("\t") unless elems[0] == @site
end
