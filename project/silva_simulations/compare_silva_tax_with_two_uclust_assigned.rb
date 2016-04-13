#!/usr/bin/env ruby
require "gg_optparse"
purpose "Compare two different Uclust assignments with each other and the Silva Taxonomy file"
positional :assignments1, :type => :infile
positional :assignments2, :type => :infile
positional :silvatax, :type => :infile
option :outsep, "\t"
switch :table
optparse!

def map2hash(file)
  hsh = {}
  file.each do |line|
    elems = line.chomp.split("\t")
    hsh[elems[0].to_sym] = elems[1]
  end
  return hsh
end

def compare(assignment, goldstandard)
  assignment = assignment.split(";")
  goldstandard = goldstandard.split(";")
  evaluations = []
  noerror = true
  7.times do |i|
    raise if goldstandard[i].nil?
    break if assignment[i].nil?
    if goldstandard[i] == assignment[i] and noerror
      evaluations[i] = :correct
    else
      noerror = false
      evaluations[i] = :wrong
    end
  end
  return evaluations
end

silvamap = map2hash(@silvatax)
a1map = map2hash(@assignments1)
a2map = map2hash(@assignments2)

counts = {:all => 0}
evals = [:correct, :wrong]
7.times do |level|
  counts[level] = {:all => 0}
  ["e1", "e2", "both"].each do |e|
    counts[level][:"#{e}nil"] = 0
  end
  evals.each do |e|
    counts[level][e] = {}
    evals.each do |f|
      counts[level][e][f] = 0
    end
  end
end

(a1map.keys & a2map.keys).each do |key|
  counts[:all] += 1
  s  = silvamap[key]
  e1 = compare(a1map[key], s)
  e2 = compare(a2map[key], s)
  7.times do |level|
    if e1[level].nil?
      counts[level][:e1nil] += 1
    end
    if e2[level].nil?
      counts[level][:e2nil] += 1
    end
    if e1[level].nil? and e2[level].nil?
      counts[level][:bothnil] += 1
    end
    if e1[level] and e2[level]
      counts[level][:all] += 1
      counts[level][e1[level]][e2[level]] += 1
    end
  end
end

def perc(part, all)
  "%.2f" % (part.to_f * 100 / all)
end

ranks = %w{Kingdom Phylum Class Order Family Genus Species}

if @table

  puts ["Rank", "Assigned using both regions",
   "(% all)", "Same and correct assignment", "(% assigned)"].join(@outsep)
  7.times do |level|
    elems = [ranks[level]]
    assigned = counts[level][:all]
    elems << assigned
    elems << perc(assigned, counts[:all])
    correct = counts[level][:correct][:correct]
    elems << correct
    elems << perc(correct, counts[level][:all])
    puts elems.join(@outsep)
  end

else

  7.times do |level|
    all = counts[level][:all]
    puts "#{level}-all\t#{all}"
    ["e1", "e2", "both"].each do |e|
      puts "#{level}-#{e}nil\t#{counts[level][:"#{e}nil"]}"
    end
    evals.each do |e|
      evals.each do |f|
        c = counts[level][e][f]
        out = []
        out << "#{level}-#{e}-#{f}"
        out << c
        out << perc(c, all)
        puts out.join(@outsep)
      end
    end
  end

end
