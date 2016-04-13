#!/usr/bin/env ruby
require "gg_optparse"
require "yaml"
positional :infile, :type => :infile
option :xmult1, 10
option :ymult1, 10
option :xmult2, 1
option :ymult2, 1
switch :shared_only
switch :normalize_counts, :short => :i
switch :normalize_sums, :short => :o
optparse!
values=[]
@infile.each {|line| values<<line.chomp.split("\t").map{|x|x.to_f}}
counts={:x0=>0,
        :y0=>0,
        :xGy=>0,
        :yGx=>0,
        :xGGy=>0,
        :yGGx=>0,
        :xEy=>0}

xsums=counts.dup
ysums=counts.dup

if @normalize_counts
  totalx=0.0
  totaly=0.0
  values.each do |x,y|
    totalx+=x
    totaly+=y
  end
else
  totalx=1
  totaly=1
end

if @shared_only
  values.reject!{|x,y|y==0 or x==0}
end

values.each do |x,y|
  if x==0
    raise if y==0
    bin=:x0
  elsif y==0
    raise if x==0
    bin=:y0
  elsif (x/totalx)>(y/totaly)*@ymult1
    bin=:xGGy
  elsif (y/totaly)>(x/totalx)*@xmult1
    bin=:yGGx
  elsif (x/totalx)>(y/totaly)*@ymult2
    bin=:xGy
  elsif (y/totaly)>(x/totalx)*@xmult2
    bin=:yGx
  else
    bin=:xEy
  end
  counts[bin]+=1
  xsums[bin]+=(x/totalx)
  ysums[bin]+=(y/totaly)
end
if @normalize_sums
  xsums_total = xsums.values.inject(0){|a,b|a+b}
  ysums_total = ysums.values.inject(0){|a,b|a+b}
  xsums.each do |k,v|
    xsums[k]=v/xsums_total
  end
  ysums.each do |k,v|
    ysums[k]=v/ysums_total
  end
end
puts ({@_infile => {:counts => counts,
      :xsums => xsums,
      :ysums => ysums}}).to_yaml
