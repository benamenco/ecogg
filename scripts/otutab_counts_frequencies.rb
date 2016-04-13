#!/usr/bin/env ruby

format=<<-END
# comment lines starting with #
# tab separated
# first column: OTU ID
# last column: taxonomy
# columns 1..-2: sites or site-groups
# one OTU per line
# several sites are allowed
# using -s they are summed up in a single frequency table
# OTU ID<TAB>SiteA<TAB>[SiteB<TAB>...]taxonomy
OTU1<TAB>0.0<TAB>[4.0<TAB>...]D_0__Bacteria;D_1__Proteobacteria[;etc]
END

outformat=<<-END
Count<TAB>SiteA<TAB>SiteB...
1<TAB>131267<TAB>122525...
2<TAB>1256<TAB>1216...
# lines containing all zeros are not output
END

require "gg_optparse"
purpose "Compute counts frequency table from OTU table"
note "Input format:\n\n#{format}"
note "Output format:\n\n#{outformat}"
switch :sumsites, :help => "Sum up counts for all sites"
option :sumsites_label, "Overall", :short => "l",
  :help => "label to use for column in sumsites option"
option :first_column_id, "Count"
positional :classic_otutable, :type => :infile
optparse!

freq = {}
sites = @sumsites ? [@sumsites_label.to_sym] : nil

@classic_otutable.each do |line|
  elems = line.chomp.split("\t")
  if line[0] == "#"
    if elems.size > 1
      sites = elems[1..-2].map{|x|x.to_sym} if sites.nil?
    end
  else
    counts = elems[1..-2].map {|n| Float(n).round}
    counts = [counts.inject(0){|a,b|a+b}] if @sumsites
    counts.each_with_index do |count, i|
      if count > 0 
        if !freq.has_key?(count)
          freq[count] = {}
          sites.each {|site| freq[count][site] = 0 }
        end
        freq[count][sites[i]] += 1
      end
    end
  end
end
@classic_otutable.close

out = ["##{@first_column_id}"]
sites.each {|site| out << site.to_s}
puts out.join("\t")
freq.keys.sort.each do |count|
  out = [count]
  sites.each {|site| out << freq[count][site]}
  puts out.join("\t")
end
