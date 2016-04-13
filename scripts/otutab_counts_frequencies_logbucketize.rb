#!/usr/bin/env ruby

require "gg_optparse"

# %-PURPOSE-%
purpose "Consolidate count table in buckets."
note <<-END
The input is a tsv table in this format:

(1) header line: starts with # and contains at least one <TAB>
(2) any other line starting with # is a comment and shall not contain <TAB>s
(3) the header shall be present before any counts line
(4) counts line contain the same number of cells as the header,
    the first column contain the key and is a positive integer
    the subsequent columns contain integer values (not necessarily positive)

Example:

# comment line
#Count<TAB>SiteA<TAB>SiteB
1<TAB>1267162<TAB>0<TAB>

The output is a table in the same format, except that the counts
are summed up in buckets of the key value.

The bucket number is computed as ceil(Log10(key)).
END

positional :tsv, :help => "Input TSV file containing the counts (see above)",
                 :type => :infile
switch :weighted, :help => ["Weigh counts before bucketing",
                     "(i.e. multiply them by their corresponding original key)"]
switch :separate_one, :short => "1"
optparse!

key_header = nil
sites = nil
counts = {}

include Math

@tsv.each do |line|
  elems = line.chomp.split("\t")
  if line[0] == "#"
    if elems.size > 0
      raise "Two header found!" unless sites.nil?
      key_header = elems[0][1..-1]
      sites = elems[1..-1].map{|x|x.to_sym}
    end
  else
    orig_key = Integer(elems[0])
    key = (log(orig_key)/log(10)).ceil
    if !counts.has_key?(key)
      counts[key] = {}
      sites.each {|site| counts[key][site] = 0 }
    end
    elems[1..-1].map{|x|Integer(x)}.each_with_index do |count, i|
      if @weighted
        count *= orig_key
      end
      counts[key][sites[i]] += count
    end
  end
end

if !@separate_one
  sites.each do |site|
    counts[1][site] ||= 0
    counts[1][site] += counts[0][site]
  end
  counts.delete(0)
end

out = ["#" + key_header + " (Min)", key_header + " (Max)"]
out << sites.map{|x|x.to_sym}
puts out.join("\t")
counts.keys.sort.each do |key|
  out = [(key == 0 and @separate_one) ? 1 :
         (key == 1 and !@separate_one) ? 1 : 10**(key-1)+1]
  out << 10**(key)
  sites.each do |site|
    out << counts[key][site]
  end
  puts out.join("\t")
end
