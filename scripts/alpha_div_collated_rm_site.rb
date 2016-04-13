#!/usr/bin/env ruby

require "gg_optparse"

# %-PURPOSE-%
purpose "Remove one site from an alpha_div_collated table"
positional :input_file, :type => :infile
positional :site
optparse!

def output_line(line, keep)
  elems = line.chomp.split("\t")
  puts keep.map{|i| elems[i]}.join("\t")
end

header=@input_file.gets
elems=header.chomp.split("\t")
keep = []
elems.each_with_index do |elem, i|
  if elem != @site
    keep << i
  end
end
output_line(header, keep)
@input_file.each {|line| output_line(line, keep)}
