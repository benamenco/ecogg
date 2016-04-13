#!/usr/bin/env ruby
require "gg_otutable"
require "gg_optparse"

# %-PURPOSE-%
purpose "Split OTU table by the n of sites in which each OTU is present"
positional :otutab, :type => :infile,
  :help => "Input file, classic Qiime OTU table"
option :outpfx,
  :help => "Prefix of output files (default: input filename)",
  :defstr => false
note "Output files: <outpfx>.<n>_sites and <outpfx>.split_by_n_sites.stats"
verbose_switch
optparse!

t = OtuTable.from_tsv_file(@otutab)
buckets = Array.new(t.sites.size+1) {[]}
t.rm_allzero!
t.otus.each do |otu|
  n_sites = t.otu_sites(otu).size
  buckets[n_sites] << otu
end

def compute_stats(t)
  t_count = t.sites.map {|site|t.total_count(site)}.inject(0){|a,b|a+b}
  n_otus = t.otus.size
  return t_count, n_otus
end

t_count_all, n_otus_all = compute_stats(t)

if @verbose
  t.name = "Input OTU table"
  puts t.inspect
  t.total_count(site)
end
@outpfx||=@_otutab

def perc_str(part,all)
  "%.2f%%" % ((part.to_f/all.to_f)*100)
end

statsfile = File.new("#@outpfx.split_by_n_sites.stats", "w")
statsfile.puts "# n_sites\tn_otus\t(%)\ttotal_count\t(%)"
buckets.size.times do |n_sites|
  next if n_sites == 0
  puts "\n"+("-"*50)+"\n\n" if @verbose
  if buckets[n_sites].empty?
    puts "No OTUs are present in #{n_sites} sites" if @verbose
    next
  end
  t_bucket = t.dup
  t_bucket.retain_only_otus!(buckets[n_sites])
  if @verbose
    t_bucket.name = "OTUs present in #{n_sites} sites"
    puts t_bucket.inspect
  end
  t_count, n_otus = compute_stats(t_bucket)
  statsfile.puts "#{n_sites}"+
    "\t#{n_otus}\t#{perc_str(n_otus,n_otus_all)}"+
    "\t#{t_count}\t#{perc_str(t_count,t_count_all)}"
  outfile = File.new("#@outpfx.#{n_sites}_sites", "w")
  outfile.puts t_bucket.to_tsv
end

