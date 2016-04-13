#!/usr/bin/env ruby

singletons=ARGV.delete("-s")

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
  STDERR.puts "Usage #$0 [-s] <classic_otu_table>"
  STDERR.puts "-s: divide exclusive in singletons and not"
  STDERR.puts "Assumed format:"
  STDERR.puts format
  exit 1
end

fn=ARGV[0]
f=File.open(fn)

of_12_fn=fn+".shared"
of_12=File.open(of_12_fn, "w")
count_12_1 = 0
count_12_2 = 0
lines_12 = 0

of_1 = nil
of_1_fn = nil
site_1 = nil
count_1 = 0
lines_1 = 0
singletons_1 = 0

of_2 = nil
of_2_fn = nil
site_2 = nil
count_2 = 0
lines_2 = 0
singletons_2 = 0

of_unclassified = nil
count_unclassified_1 = 0
count_unclassified_2 = 0
has_unclassified = false

all_zero = 0

header = nil

f.each do |line|
  elems = line.chomp.split("\t")
  if line[0] != "#"
    if elems.size != 3 and elems.size != 4
      raise "unexpected nof columns (#{elems.size}) of line: #{line}"
    end
    counts = elems[1..2].map{|n|Float(n)}
    if counts.all?{|n|n==0}
      all_zero += 1
      next
    end
    if elems[0] == "unclassified"
      raise if has_unclassified
      has_unclassified = true
      of_unclassified = File.open(fn+".unclassified", "w")
      of_unclassified.puts header
      of_unclassified.puts line
      of_unclassified.close
      count_unclassified_1 = counts[0]
      count_unclassified_2 = counts[1]
    elsif counts.all?{|n|n>0}
      of_12.puts line
      lines_12 += 1
      count_12_1 += counts[0]
      count_12_2 += counts[1]
    elsif counts[0] == 0
      of_2.puts line
      if counts[1] == 1 and singletons
        singletons_2 += 1
      else
        lines_2 += 1
        count_2 += counts[1]
      end
    else
      raise if counts[1] != 0
      of_1.puts line
      if counts[0] == 1 and singletons
        singletons_1 += 1
      else
        lines_1 += 1
        count_1 += counts[0]
      end
    end
  elsif elems.size > 1
    site_1 = elems[1]
    site_2 = elems[2]
    of_1_fn = fn+".exclusive_#{site_1}"
    of_2_fn = fn+".exclusive_#{site_2}"
    of_1=File.open(of_1_fn, "w")
    of_2=File.open(of_2_fn, "w")
    header = line
    of_1.puts line
    of_2.puts line
    of_12.puts line
  end
end

of_stats = File.open(fn+".intersection_stats", "w")

def percstr(part, all)
  "%.2f%%" % (part.to_f / all.to_f * 100)
end

out = ["Site"]
if has_unclassified
  out += ["Count unclassified", "%count"]
  pfx = "Genera"
else
  pfx = "OTUs"
end
if singletons
  out += ["#{pfx} singletons", "%#{pfx}", "%count"]
  sfx = " (c>1)"
else
  sfx = ""
end
out += ["#{pfx} exclusive#{sfx}", "%#{pfx}", "Count exclusive#{sfx}", "%count"]
out += ["%classified_count"] if has_unclassified
out += ["#{pfx} shared", "%#{pfx}", "Count shared", "%count"]
out += ["%classified_count"] if has_unclassified
of_stats.puts out.join("\t")

all_1_units = singletons_1 + lines_1 + lines_12
all_1_count_cl = singletons_1 + count_1 + count_12_1
all_1_count = count_unclassified_1 + all_1_count_cl
out = [site_1]
out += [count_unclassified_1, percstr(count_unclassified_1, all_1_count)] if has_unclassified
out += [singletons_1, percstr(singletons_1, all_1_units),
        percstr(singletons_1, all_1_count)] if singletons
out += [lines_1, percstr(lines_1, all_1_units),
        count_1, percstr(count_1, all_1_count)]
out += [percstr(count_1, all_1_count_cl)] if has_unclassified
out += [lines_12, percstr(lines_12, all_1_units),
        count_12_1, percstr(count_12_1, all_1_count)]
out += [percstr(count_12_1, all_1_count_cl)] if has_unclassified
of_stats.puts out.join("\t")

all_2_units = singletons_2 + lines_2 + lines_12
all_2_count_cl = singletons_2 + count_2 + count_12_2
all_2_count = count_unclassified_2 + all_2_count_cl
out = [site_2]
out += [count_unclassified_2, percstr(count_unclassified_2, all_2_count)] if has_unclassified
out += [singletons_2, percstr(singletons_2, all_2_units),
        percstr(singletons_2, all_2_count)] if singletons
out += [lines_2, percstr(lines_2, all_2_units),
        count_2, percstr(count_2, all_2_count)]
out += [percstr(count_2, all_2_count_cl)] if has_unclassified
out += [lines_12, percstr(lines_12, all_2_units),
        count_12_2, percstr(count_12_2, all_2_count)]
out += [percstr(count_12_2, all_2_count_cl)] if has_unclassified
of_stats.puts out.join("\t")

if all_zero > 0
  of_stats.puts "# #{all_zero} #{pfx} with overall count = 0 were removed"
end

of_1.close unless of_1.nil?
of_2.close unless of_2.nil?
of_12.close unless of_2.nil?

[of_1_fn, of_2_fn, of_12_fn].each do |filename|
  next unless File.exists?(filename)
  `otutab_sort_otus.rb #{filename} > #{filename}.cs`
  `otutab_divide_taxonomy_column.rb -a #{filename}.cs > #{filename}.cs.td`
end
