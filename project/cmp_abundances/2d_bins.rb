#!/usr/bin/env ruby
require "gg_optparse"
purpose "Take x,y data and output 2d bins"
positional :inputfile, :type => :infile
option :nbins, 10
switch :log
optparse!
values=[]
xmax=0.0
ymax=0.0
xmin=1.0/0.0
ymin=1.0/0.0
@inputfile.each do |line|
  elems=line.chomp.split("\t")
  x=elems[0].to_f
  y=elems[1].to_f
  if @log
    x=(x==0) ? (-1.0/0.0) : Math::log10(x)
    y=(y==0) ? (-1.0/0.0) : Math::log10(y)
  end
  values<<[x,y]
  xmax=x if x>xmax
  xmin=x if x<xmin
  ymax=y if y>ymax
  ymin=y if y<ymin
end
xrange=xmax-xmin
yrange=ymax-ymin
xbinsize=(xrange/@nbins)
ybinsize=(yrange/@nbins)
bincount={}
values.each do |x,y|
  xbin=(x/xbinsize).floor
  ybin=(y/ybinsize).floor
  bincount[xbin]||={}
  bincount[xbin][ybin]||=0
  bincount[xbin][ybin]+=1
end
out = ["",""]
((ymin/ybinsize).floor).upto((ymax/ybinsize).floor).each do |y|
  out << y*ybinsize
end
puts out.join("\t")
out = ["",""]
((ymin/ybinsize).floor).upto((ymax/ybinsize).floor).each do |y|
  out << "--"
end
puts out.join("\t")
((xmin/xbinsize).floor).upto((xmax/xbinsize).floor).each do |x|
  out = [x*xbinsize,"|"]
  ((ymin/ybinsize).floor).upto((ymax/ybinsize).floor).each do |y|
    out << bincount.fetch(x,{}).fetch(y,0)
  end
  puts out.join("\t")
end
