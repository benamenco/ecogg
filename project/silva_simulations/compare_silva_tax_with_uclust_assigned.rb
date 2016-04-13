#!/usr/bin/env ruby
require "gg_optparse"
purpose "Compare Uclust assignments with Silva Taxonomy file"
positional :assignments, :type => :infile
positional :silvatax, :type => :infile
optparse!

silva = {}
@silvatax.each do |line|
  elems = line.chomp.split("\t")
  silva[elems[0].to_sym] = elems[1]
end

counts = {:all => 0,
          :correct => 0,
          :undef_D => [0,0,0,0,0,0,0],
          :wrong_D => [0,0,0,0,0,0,0]}

@assignments.each do |line|
  counts[:all] += 1
  elems = line.chomp.split("\t")
  silvatax = silva[elems[0].to_sym]
  assigned = elems[1]
  if silvatax != assigned
    if silvatax =~ /#{Regexp.quote(assigned)};.*/
      assigned = assigned.split(";")
      counts[:undef_D][assigned.size] += 1
    else
      silvatax = silvatax.split(";")
      assigned = assigned.split(";")
      d_found = false
      7.times do |i|
        if silvatax[i] != assigned[i]
          counts[:wrong_D][i] += 1
          d_found = true
          break
        end
      end
      raise if !d_found
    end
  else
    counts[:correct] += 1
  end
end

def perc(part, all)
  "%.2f" % (part.to_f * 100 / all)
end

puts "Complete:\t#{counts[:correct]}\t#{perc(counts[:correct], counts[:all])}"
6.downto(0) do |i|
  puts "Undefined D_#{i}:\t#{counts[:undef_D][i]}\t#{perc(counts[:undef_D][i], counts[:all])}"
  puts "Wrong D_#{i}:\t#{counts[:wrong_D][i]}\t#{perc(counts[:wrong_D][i], counts[:all])}"
end

puts
puts "D_6 correct:\t#{counts[:correct]}\t#{perc(counts[:correct], counts[:all])}"
5.downto(0) do |i|
  w = 0
  u = 0
  (i+1).upto(6) do |j|
    w += counts[:wrong_D][j]
    u += counts[:undef_D][j]
  end
  n = counts[:correct] + u + w
  puts "D_#{i} correct:\t#{n}\t#{perc(n,counts[:all])}"
end

