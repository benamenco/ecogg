#!/usr/bin/env ruby

#
# LOW QUALITY SCRIPT!
#

format=<<-END
# comment lines starting with #
# tab separated
# first column: OTU ID
# last column: taxonomy
# columns 1..-2: sites or site-groups
# one OTU per line
# two sites
# OTU ID<TAB>SiteA<TAB>SiteB<TAB>taxonomy
OTU1<TAB>0.0<TAB>4.0<TAB>D_0__Bacteria;D_1__Proteobacteria[;etc]
END

if ARGV.size != 1
  STDERR.puts "Usage #$0 <classic_otu_table>"
  STDERR.puts "Assumed format:"
  STDERR.puts format
  STDERR.puts "\nOutput filename is derived from input filename, by removing"
  STDERR.puts "the prefix \"otu\" and substituting it with \"genus\"\n\n"
  STDERR.puts "Output format:"
  STDERR.puts "OTU ID is substituted by Genus"
  exit 1
end

fn=ARGV[0]
fn_bn = File.basename(fn)
raise "Input filename shall start with otu_" if fn_bn[0..3] != "otu_"
ofn = File.join(File.dirname(fn), "genus_" + fn_bn[4..-1])

f=File.open(fn)
of = File.open(ofn, "w")
uncl_of_fn = fn+".unclassified_at_genus_level"
uncl_of = File.open(uncl_of_fn, "w")
uncl_info = {}

info = {}

sum_classified = nil
sites = nil

otus = {}

f.each do |line|
  elems = line.chomp.split("\t")
  if line[0] == "#"
    uncl_of.puts line
    if elems[0] == "#OTU ID"
      elems[0] = "#Genus"
      of.puts elems.join("\t")
      raise if !sites.nil?
      sites = elems[1..-2].dup
      otus = {:unclassified => {}, :classified => {}}
      sites.each do |site|
        otus.keys.each {|k| otus[k][site] = 0}
      end
    else
      of.puts line
    end
  else
    counts = elems[1..-2].map{|n|Float(n)}
    lineage = elems.last.split(";")[0..5]
    genus_string = lineage[5]
    if lineage[5].nil?
      genus = :unclassified
    else
      if genus_string =~ /uncultured/ or genus_string =~ /metagenome/ or
        genus_string =~ /Incertae Sedis/ or genus_string =~ /unidentified/
          genus = :unclassified
      else
        genus_string =~ /D_5__(.*)/
        genus = $1.nil? ? :unclassified : $1.to_sym
      end
    end
    if genus == :unclassified
      uncl_info[elems[0]] = counts.dup
      uncl_info[elems[0]] << elems.last
      lineage = ["n.a."]
    else
      lineage = lineage.join(";")
    end
    counts.each_with_index do |c,i|
      if c > 0
        if genus == :unclassified
          otus[:unclassified][sites[i]] += 1
        else
          otus[:classified][sites[i]] += 1
        end
      end
    end
    if info.has_key?(genus)
      counts.size.times do |i|
        info[genus][i] += counts[i]
      end
      if info[genus][-1] != lineage
        STDERR.puts "WARNING: Lineage inconsistency!"
        STDERR.puts "Previous lineage found for #{genus}:"
        STDERR.puts info[genus][-1]
        STDERR.puts "Lineage found now:"
        STDERR.puts lineage
        STDERR.puts "The previous one will be kept!"
      end
    else
      info[genus] = counts.dup
      info[genus] << lineage
    end
    if genus != :unclassified
      if sum_classified.nil?
        sum_classified = counts.dup
      else
        counts.size.times do |i|
          sum_classified[i] += counts[i]
        end
      end
    end
  end
end
f.close

of.puts(([:unclassified] + info[:unclassified]).join("\t"))
info.keys.sort_by do |genus|
    sum = 0
    sites.size.times do |i|
      sum += info[genus][i]
    end
    -sum
  end.each do |genus|
  next if genus == :unclassified
  of.puts(([genus] + info[genus]).join("\t"))
end
of.close

uncl_info.sort_by do |elems|
    sum = 0
    sites.size.times do |i|
      sum += uncl_info[elems[0]][i]
    end
    -sum
  end.each do |elems|
  uncl_of.puts(elems.join("\t"))
end
uncl_of.close

[ofn, uncl_of_fn].each do |filename|
  `otutab_divide_taxonomy_column.rb -a #{filename} > #{filename}.td`
end

def perc_str(part, all)
  "%.2f%%" % (part.to_f / all.to_f * 100)
end

genera = {}
sites.each {|site| genera[site] = 0}
info.keys.each do |genus|
  next if genus == :unclassified
  sites.size.times do |i|
    genera[sites[i]] += 1 if info[genus][i] > 0
  end
end

statsfn = ofn + ".stats"
f = File.open(statsfn, "w")

total_classified = 0
total_unclassified = 0
total_classified_otus = 0
total_unclassified_otus = 0

f.puts "#Site\tClassified Seqs\t\tUnclassified Seqs\t\tClassified OTUs\t\t\Unclassified OTUs\t\tGenera"
sum_classified.size.times do |i|
  site = sites[i]

  classified = sum_classified[i]
  total_classified += classified
  unclassified = info[:unclassified][i]
  total_unclassified += unclassified
  all = classified + unclassified

  classified_otus = otus[:classified][site]
  total_classified_otus += classified_otus
  unclassified_otus = otus[:unclassified][site]
  total_unclassified_otus += unclassified_otus
  all_otus = classified_otus + unclassified_otus

  f.puts [site, classified, perc_str(classified, all),
        unclassified, perc_str(unclassified, all),
        classified_otus, perc_str(classified_otus, all_otus),
        unclassified_otus, perc_str(unclassified_otus, all_otus),
        genera[site]].join("\t")
end

all = total_classified + total_unclassified
all_otus = total_classified_otus + total_unclassified_otus

site = "#Total"
f.puts [site, total_classified, perc_str(total_classified, all),
        total_unclassified, perc_str(total_unclassified, all),
        total_classified_otus, perc_str(total_classified_otus, all_otus),
        total_unclassified_otus, perc_str(total_unclassified_otus, all_otus),
        genera[site]].join("\t")
