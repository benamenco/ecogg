#!/usr/bin/env ruby
require "gg_optparse"
require "gg_fasta"
# %-PURPOSE-%
purpose "Extract Fasta sequences using a FastaID=>Tax mapping, by a regexp on Tax"
positional :map, :type => :infile
positional :regexp
positional :fasta, :type => :infile, :fileclass => FastaFile
option :delim, "\t"
optparse!

@regexp = Regexp.new(@regexp)

def file_to_hash(file)
  hsh = {}
  file.each do |line|
    elems = line.chomp.split(@delim)
    raise if elems.size != 2
    hsh[elems[0]]=elems[1]
  end
  hsh
end

@map = file_to_hash(@map)

not_found = 0
not_matching = 0
matching = 0
@fasta.each do |u|
  tax = @map[u.fastaid]
  if tax.nil?
    not_found += 1
  else
    if tax =~ @regexp
      puts u
      matching += 1
    else
      not_matching += 1
    end
  end
end

STDERR.puts "# Fasta IDs:          \t#{not_found + not_matching + matching}"
STDERR.puts "# not found in map:   \t#{not_found}"
STDERR.puts "# not matching regexp:\t#{not_matching}"
STDERR.puts "# matching regexp:    \t#{matching}"
