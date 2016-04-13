#!/usr/bin/env ruby
require "gg_optparse"
require "gg_otutable"

# %-PURPOSE-%
purpose "Reorder sites in an OTU table"
positional :otutable, :type => :infile
positional :order, :type => :infile, :help => "File with sorting order, one site per line"
optparse!
t = OtuTable.from_tsv_file(@otutable)
order = @order.read.split.map{|x|x.to_sym}
t.reorder_sites(order)
puts t.to_tsv
