#!/usr/bin/env ruby

require "yaml"
require "gg_otutable"

# %-PURPOSE-%
purpose="Remap sites in an OTU table (merge, rename, move, remove)"

usage=<<-end
#{purpose}
Usage: #$0 [-r COUNT] <otu_table.tsv> <sites-map.yaml>

Sites map file format:

---
- site_to_rename: old_site_name
- site_to_keep: site_to_keep
- cumulative_site: [site1, site2]

All other sites are removed.
Sites can only be used once.

Options:
-r COUNT    Rescale to the given number of reads. If n sites are cumulated, each
            site is first rescaled to COUNT/n, then the sites are cumulated.
end

error = false
roptidx = ARGV.index("-r")
ropt = nil
if roptidx
  if ARGV.size > roptidx
    ropt = Integer(ARGV[roptidx+1]) rescue error = true
    2.times { ARGV.delete_at(roptidx) }
  else
    error = true
  end
end

if error or ARGV.size != 2
  STDERR.puts usage
  exit 1
end

def check_sorted_sites_are_unique(needed)
  needed.inject(nil) do |prev, elem|
    if elem == prev
      STDERR.puts "invalid map: site '#{elem}' present multiple times"
      exit 1
    end
    elem
  end
end

otutabfn = ARGV[0]
sitesmapfn = ARGV[1]
otutab = OtuTable.from_tsv(otutabfn)
sitesmap = YAML.load_file(sitesmapfn)
needed = sitesmap.map{|e|e.values[0]}.flatten.sort.map{|s|s.to_sym}
check_sorted_sites_are_unique(needed)
(otutab.sites - needed).each {|s| otutab.rm_site(s)}
sitesorder = []
sitesmap.each do |e|
  raise "invalid map format" if e.size != 1
  k, v = e.keys[0], e.values[0]
  sitesorder << k
  if v.kind_of?(Array)
    if (ropt)
      nreads = ropt.to_f / v.size
      v.each {|site| otutab.rescale_site(site, nreads, false)}
    end
    otutab.merge_sites(v,k)
    #otutab.round_counts_for_site(k)
  elsif k != v
    otutab.rename_site(v,k)
  else
    if !otutab.sites.include?(v.to_sym)
      raise "site does not exist: #{v}\nsites: #{otutab.sites.inspect}"
    end
  end
end
otutab.reorder_sites(sitesorder)
puts otutab.to_tsv rescue Errno::EPIPE
