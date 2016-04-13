#!/usr/bin/env ruby
require "gg_otutable"
require "gg_array"
require "gg_optparse"

# %-PURPOSE-%
purpose "Compute OTU intersections among sites."
positional :otutable, :type => :infile
option :mincount, 1, :type => :natural, :help => "Minimum count filter"
switch :countonly, :help => "Only compute size of intersections"
switch :taxonomy, :help => "Show taxonomy assignments instead of OTU numbers"
optparse!

otutab = OtuTable.from_tsv_file(@otutable)

otutab.sites.all_splits.each do |in_sites, not_in_sites|
  i = otutab.intersection(in_sites, true, o)
  n_elems = @countonly ? i : i.size
  header = "-- #{n_elems} elements in { #{in_sites.join(', ')} } "
  if not_in_sites.size > 0
    header += "and not in { #{not_in_sites.join(', ')} }"
  end
  puts header
  if !@countonly
    if @taxonomy
      i.map!{|otunr|otutab.fetch_taxonomy(otunr)}
    end
    puts i
    puts
  end
end
