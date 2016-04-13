#!/usr/bin/env ruby

require "gg_optparse"

format=<<-END
# comment lines starting with #
# tab separated
# first column: OTU ID
END
# %-PURPOSE-%
purpose "Exchange OTU IDs prefixes in classic OTU table"
note "Expected OTU table format:\n#{format}"
positional :otutab, :help => "Classic Qiime OTU table", :type => :infile
positional :pfx1_new, :help => "New value for pfx1"
positional :pfx2_new, :help => "New value for pfx2"
pfx1="New.ReferenceOTU"
pfx2="New.CleanUp.ReferenceOTU"
option :pfx1, pfx1, :short => 1, :help => "OTUs Prefix 1"
option :pfx2, pfx2, :short => 2, :help => "OTUs Prefix 2"
verbose_switch
optparse!

if @verbose
  count_pfx1=0
  count_pfx2=0
end

@otutab.each do |line|
  if line[0] == "#"
    puts line
  else
    elems = line.chomp.split("\t")
    if elems[0] =~ /#{Regexp.quote(@pfx1)}(\d+)/
      elems[0] = "#{@pfx1_new}#$1"
      count_pfx1+=1 if @verbose
    elsif elems[0] =~ /#{Regexp.quote(@pfx2)}(\d+)/
      elems[0] = "#{@pfx2_new}#$1"
      count_pfx2+=1 if @verbose
    end
    puts elems.join("\t")
  end
end

if @verbose
  STDERR.puts "# prefix 1 found #{count_pfx1} times"
  STDERR.puts "# prefix 2 found #{count_pfx2} times"
end
