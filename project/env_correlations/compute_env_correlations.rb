#!/usr/bin/env ruby
require "gg_optparse"
require "gg_otutable"
require "gg_logger"
require "gg_qiime_mapping"

# %-PURPOSE-%
purpose "Run observation_metadata_correlation on an appropriate subset of an OTU table"
positional :otu_table, :type => :infilename
positional :mapping, :type => :infilename
positional :parameter
positional :outpfx
switch :force_recomputing_otu_table_subset
switch :subset_only
switch :only_show_commands
option :min_sites, 4
option :min_sites_fraction, 0.25
option :correlation_test, "spearman"
verbose_switch
optparse!

m = QiimeMapping.new(@mapping)
unless m.has_field?(@parameter)
  optparse_die "Parameter #{@parameter} not found "+
    "in mapping and not env_data_table specified\n"+
    "Fields found: "+m.fieldnames.inspect
end

raise "Otu table filename must end in .classic" \
  if @_otu_table !~ /.*\.classic/

otu_table_for_parameter = File.join(File.dirname(@_otu_table),
                          @parameter+"."+File.basename(@_otu_table))
vlog "OTU Table filename (classic): #{otu_table_for_parameter}"
biom_otu_table_for_parameter = File.join(File.dirname(@_otu_table),
                                         @parameter+"."+
                                         File.basename(@_otu_table, ".classic")+
                                         ".biom")
vlog "OTU Table filename (biom): #{biom_otu_table_for_parameter}"

if File.exists?(otu_table_for_parameter) and \
  !@force_recomputing_otu_table_subset
    vlog "OTU Table found: #{otu_table_for_parameter}"
else
  samples_to_extract = m.samples_for_field(@parameter)
  min_sites = (@min_sites_fraction * samples_to_extract.size).to_i
  if min_sites < @min_sites
    min_sites = @min_sites
  end
  vlog "Total sites for parameter: #{samples_to_extract.size}"
  if samples_to_extract.size < min_sites
    vlog "Total number of sites too small, minimum #{min_sites}"
    exit
  end
  vlog "Min sites required for an OTU: #{min_sites}"
  t = OtuTable.from_tsv(@otu_table)
  t.keep_only_sites(samples_to_extract)
  vlog "N.OTUs before filtering: #{t.otus.size}"
  t.rm_allzero!
  vlog "N.OTUs after rm_allzero: #{t.otus.size}"
  raise if t.otus.size == 0
  t.filter_otus_by_sites! do |sites|
    sites.size < min_sites
  end
  vlog "N.OTUs after filtering: #{t.otus.size}"
  raise if t.otus.size == 0
  f = File.open(otu_table_for_parameter,"w")
  f.puts t.to_tsv
  f.close
  vlog "OTU Table written: #{otu_table_for_parameter}"
end

if !File.exists?(biom_otu_table_for_parameter) or \
  @force_recomputing_otu_table_subset
  `otutab_classic_to_biom.sh -f #{otu_table_for_parameter}`
end

exit if @subset_only

def run(cmd)
  if @only_show_commands
    puts cmd
  else
    `#{cmd}`
  end
end

outfile_raw = "#{@outpfx}.#{@parameter}.#@correlation_test.raw.tsv"
outfile_uns = "#{@outpfx}.#{@parameter}.#@correlation_test.tsv.unsorted"
outfile_sig = "#{@outpfx}.#{@parameter}.#@correlation_test.tsv.tax"
outfile_std = "#{@outpfx}.#{@parameter}.#@correlation_test.tsv"

cmd = "observation_metadata_correlation.py"
cmd += " -i #{biom_otu_table_for_parameter}"
cmd += " -m #{@mapping}"
cmd += " -o #{outfile_raw}"
cmd += " -c #{@parameter}"
cmd += " -s #{@correlation_test}"

run(cmd)

cmd = "otutab_significant_correlations.rb"
cmd += " #{outfile_raw}"
cmd += " #{otu_table_for_parameter}"
cmd += " > #{outfile_uns}"

run(cmd)

cmd = "head -n 1 #{outfile_uns} > #{outfile_sig}"

run(cmd)

cmd = "tail -n+2 #{outfile_uns} | "
cmd += "sort -t$'\\t' -r -n -k2 >> "
cmd += "#{outfile_sig}"

run(cmd)

cmd = "rm #{outfile_uns}"

run(cmd)

cmd = "otutab_divide_taxonomy_column.rb -a #{outfile_sig} > #{outfile_std}"

run(cmd)

cmd = "rm #{outfile_sig}"

run(cmd)
