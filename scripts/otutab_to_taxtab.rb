#!/usr/bin/env ruby

require "gg_optparse"

Ranks = %W[kingdom phylum class order family genus species]
RankPlurals = %W[Kingdoms Phyla Classes Orders Families Genera Species]
Undefined = %W{uncultured unclassified unknown unidentified metagenome Incertae\ Sedis}


# %-PURPOSE-%
purpose "Summarize OTU table by taxonomy at specified level"
positional :otutab, :type => :infile
positional :rank, :help => "Rank, one of: #{Ranks.join(",")}",
  :type => :list, :allowed => Ranks
option :restrict_to_kingdom, nil
optparse!

def process_header(elems, line, files, sites, totals)
  files[:unclassified].puts line
  if elems[0] == "#OTU ID"
    raise if !sites.empty?
    elems[1..-2].each do |site|
      sites << site
      [:classified, :unclassified].each do |f|
        totals[:otus][f][site] = 0
        totals[:seqs][f][site] = 0
      end
    end
    elems[0] = "##{@rank[0].upcase + @rank[1..-1]}"
    line = elems.join("\t")
  end
  files[:classified].puts line
end

def determine_taxon(elems, rank_idx, counts, output_data)
  lineage = elems.last.split(";")[0..rank_idx]
  taxlabel = lineage[rank_idx]
  if lineage[rank_idx].nil?
    taxon = :unclassified
  else
    Undefined.each do |undefstr|
      if taxlabel =~ /.*#{Regexp.quote(undefstr)}.*/i
        taxon = :unclassified
      end
    end
  end
  if @restrict_to_kingdom
    if lineage[0] !~ /.*#{Regexp.quote(@restrict_to_kingdom)}.*/
      taxon = :unclassified
    end
  end
  if taxon != :unclassified
    taxlabel =~ /D_#{rank_idx}__(.*)/
    taxon = $1.nil? ? :unclassified : $1.to_sym
  end
  if taxon == :unclassified
    output_data[:unclassified][elems[0]] = counts.dup
    output_data[:unclassified][elems[0]] << elems.last
    lineage = ["n.a."]
  end
  lineage = lineage.join(";")
  return taxon, lineage
end

def check_lineage_inconsistency(taxon, lineage, prevlineage)
  if lineage != prevlineage
    STDERR.puts "WARNING: Lineage inconsistency!"
    STDERR.puts "         Previous lineage found for #{taxon}:"
    STDERR.puts "           "+prevlineage
    STDERR.puts "         Lineage found now:"
    STDERR.puts "           "+lineage
    STDERR.puts "         The previous one will be kept!"
  end
end

def process_counts(elems, rank_idx, output_data, sites, totals)
  counts = elems[1..-2].map{|n|Float(n)}
  taxon, lineage = determine_taxon(elems, rank_idx, counts, output_data)
  taxontype = taxon == :unclassified ? taxon : :classified
  counts.each_with_index do |c,i|
    totals[:otus][taxontype][sites[i]] += 1 if c > 0
    totals[:seqs][taxontype][sites[i]] += c
  end
  if output_data[:classified].has_key?(taxon)
    counts.size.times do |i|
      output_data[:classified][taxon][i] += counts[i]
    end
    prevlineage = output_data[:classified][taxon][-1]
    check_lineage_inconsistency(taxon, lineage, prevlineage)
  else
    output_data[:classified][taxon] = counts.dup
    output_data[:classified][taxon] << lineage
  end
end

def puts_output_data(type, files, output_data, sites)
  if type == :classified
    if output_data[type][:unclassified]
      files[type].puts(([:unclassified] +
               output_data[type][:unclassified]).join("\t"))
    end
  end
  taxa = output_data[type].keys
  sorted_taxa = taxa.sort_by do |taxon|
      sum = 0; sites.size.times {|i| sum += output_data[type][taxon][i]}
      -sum
    end
  sorted_taxa.each do |taxon|
    next if taxon == :unclassified
    elems = output_data[type][taxon]
    files[type].puts(([taxon] + elems).join("\t"))
  end
end

def perc_str(part, all)
  "%.2f%%" % (part.to_f / all.to_f * 100)
end

def puts_stats_line(site, data, stats_of, ntaxa)
  line = [site]
  [:seqs, :otus].each do |unit|
    [:classified, :unclassified].each do |status|
      line << data[status][unit]
      line << perc_str(data[status][unit], data[:all][unit])
    end
  end
  line << ntaxa[site]
  stats_of.puts line.join("\t")
end

def compute_ntaxa(sites, output_data)
  ntaxa = {"#Total" => 0}
  sites.each {|site| ntaxa[site] = 0}
  output_data[:classified].keys.each do |taxon|
    next if taxon == :unclassified
    total_added = false
    sites.size.times do |i|
      if output_data[:classified][taxon][i] > 0
        ntaxa[sites[i]] += 1
        unless total_added
          ntaxa["#Total"] += 1
          total_added = true
        end
      end
    end
  end
  return ntaxa
end

def compute_and_output_stats(sites, totals, output_data, stats_of, rank_idx)

  ntaxa = compute_ntaxa(sites, output_data)
  total = {:classified => {:seqs => 0, :otus => 0},
           :unclassified => {:seqs => 0, :otus => 0},
           :all => {:seqs => 0, :otus => 0}}

  stats_of.puts "#Site\t"+
    "Classified Seqs\t\tUnclassified Seqs\t\t"+
    "Classified OTUs\t\tUnclassified OTUs\t\t"+
    "#{RankPlurals[rank_idx]}"

  sites.each_with_index do |site, i|

    this = {:classified => {:seqs => 0, :otus => 0},
           :unclassified => {:seqs => 0, :otus => 0},
           :all => {:seqs => 0, :otus => 0}}

    [:seqs, :otus].each do |unit|
      [:classified, :unclassified].each do |status|
        this[status][unit]   = totals[unit][status][site]
        total[status][unit] += this[status][unit]
        this[:all][unit]    += this[status][unit]
        total[:all][unit]   += this[status][unit]
      end
    end

    puts_stats_line(site, this, stats_of, ntaxa)
  end

  site = "#Total"
  puts_stats_line(site, total, stats_of, ntaxa)
end

def get_outfiles()
  bn = File.basename(@_otutab)
  raise "OTU table filename shall start with otu_" if bn[0..3] != "otu_"
  filenames = {}
  filenames[:classified] =
    File.join(File.dirname(@_otutab), "#{@rank}_#{bn[4..-1]}")
  filenames[:unclassified] = @_otutab + ".unclassified_at_#{@rank}_level"
  filenames[:stats] = filenames[:classified] + ".stats"
  files = {}
  [:classified, :unclassified, :stats].each do |f|
    files[f] = File.open(filenames[f], "w")
  end
  return files, filenames
end

output_data = {:classified => {}, :unclassified => {}}
sites = []
totals = {:seqs => { :classified => {}, :unclassified => {} },
          :otus => { :classified => {}, :unclassified => {} }}
rank_idx = Ranks.index(@rank)
files, filenames = get_outfiles()

@otutab.each do |line|
  elems = line.chomp.split("\t")
  if line[0] == "#"
    process_header(elems, line, files, sites, totals)
  else
    process_counts(elems, rank_idx, output_data, sites, totals)
  end
end

puts_output_data(:classified, files, output_data, sites)
puts_output_data(:unclassified, files, output_data, sites)

compute_and_output_stats(sites, totals, output_data, files[:stats], rank_idx)
[:classified, :unclassified].each do |f|
  files[f].close
  `otutab_divide_taxonomy_column.rb -a #{filenames[f]} > #{filenames[f]}.td`
end
