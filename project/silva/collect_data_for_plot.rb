#!/usr/bin/env ruby
rank=["Kingdom","Phylum","Class","Order","Family","Genus","Species"]

7.times do |i|
  rawdata = `grep D_#{i}\\ correct *shortened*.eval V6.Gibbons*.eval`
  lines=rawdata.chomp.split("\n")
  lines=lines.map do |line|
    elems=line.split("\t")
    if elems[0] =~ /V3V4\.shortened\.(\d\.\d\d\d)_tax_assignments\.eval/
      factor = $1
    else
      factor = 1.125 # (Pseudo-factor for Gibbons)
    end
    [rank[i],factor,elems[2]].join("\t")
  end
  puts lines
end
