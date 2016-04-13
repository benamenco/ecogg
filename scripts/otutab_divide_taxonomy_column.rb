#!/usr/bin/env ruby
require "gg_optparse"
# %-PURPOSE-%
purpose "Divide taxonomy column into elements"
positional :input, :type => :infile
ranks = [:kingdom, :phylum, :class, :order, :family, :genus, :species]
ranks.each do |rank|
  switch rank, :short => rank[0], :help => "Show #{rank}"
end
switch :all, :short => "a", :help => "Show all ranks"
option :delimiter, "\t", :defstr=>false, :help => "Delimiter (default: TAB)"
option :taxdelim, ";"
option :comment, "#", :help => "First char of header and comments"
option :taxheader, "taxonomy"
switch :remove_unspecific, :help => ["Remove unspecific labels",
                                    "e.g. uncultured, metagenome, "+
                                    "unidentified..."]
option :na, "", :help => "What to write for n.a. levels (default: leave empty)",
  :defstr => false
optparse!

def unspecific?(label)
  %w{uncultured metagenome Incertae\ Sedis unidentified unassigned}.
    each {|u| return true if label =~ /#{Regexp.quote(u)}/i}
  false
end

class String
  def capitalize
    self[0].upcase + self[1..-1]
  end
end

if @all
  ranks.each do |r|
    instance_variable_set("@#{r}", true)
  end
end

if !ranks.any?{|r|instance_variable_get("@#{r}")}
  optparse_die "You must specificy at least one rank\n"+
    "(#{ranks.map{|x|x.to_s}.join(", ")})"
end

taxcol=nil
@input.each do |line|
  elems = line.chomp.split(@delimiter)
  if line[0] == @comment
    if elems.size > 1
      taxcol = elems.index(@taxheader)
      if !taxcol
        raise "Taxonomy column not found\n"+elems.inspect
      end
      elems[taxcol] = []
      ranks.each do |rank|
        if instance_variable_get("@#{rank}")
          elems[taxcol] << rank.to_s.capitalize
        end
      end
      puts elems.flatten.join(@delimiter)
    else
      puts line
    end
  else
    lineage = elems[taxcol].split(@taxdelim).map do |l_elem|
      if l_elem =~ /D_\d__(.*)/
        $1
      else
        l_elem
      end
    end
    elems[taxcol] = []
    ranks.each_with_index do |rank, i|
      if unspecific?(lineage[i])
        break
      end
      if instance_variable_get("@#{rank}")
        elems[taxcol] << lineage[i]
      end
    end
    (ranks.size - elems[taxcol].size).times { elems[taxcol] << @na }
    puts elems.flatten.join(@delimiter)
  end
end
