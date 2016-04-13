#!/usr/bin/env ruby
require "gg_otutable"
require "gg_optparse"

# %-PURPOSE-%
purpose "In Qiime classic taxa table, filter out Other/Unassigned/Unclassified."
positional :otutable, :type => :infile
optparse!

otutab = OtuTable.from_tsv_file(@otutable)
otutab.taxatable_rm_other!
puts otutab.to_tsv rescue Errno::EPIPE
