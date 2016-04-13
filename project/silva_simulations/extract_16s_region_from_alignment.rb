#!/usr/bin/env ruby
require "gg_optparse"
require "gg_fasta"
require "gg_wildcards"
require "gg_gap"

purpose "Extract a region of a 16s alignment based on two primers"
positional :f_primer
positional :r_primer
positional :infile, :type => :infile, :fileclass => FastaFile
option :relax, 0, :type => :natural
switch :only_show_range_distri, :short => "d"
option :max_n_seq, 0, :type => :natural
switch :search_primer_in_all
optparse!

optparse_die if (@only_show_range_distri and @search_primer_in_all)

def print_range(u, range)
  u.seq = u.seq[range]
  puts u
end

ranges_distri = {}

rc_r_primer = @r_primer.revcompl
range = nil
while range.nil?
  u = @infile.get
  break if u.nil?
  break if @max_n_seq > 0 and u.seqnum >= @max_n_seq
  m = (u.seq.ungap =~ @f_primer.to_regexp)
  if m.nil?
    if @only_show_range_distri
      ranges_distri[:F_not_found]||=0
      ranges_distri[:F_not_found]+=1
    end
    next
  end
  n = (u.seq.ungap =~ rc_r_primer.to_regexp)
  if n.nil?
    if @only_show_range_distri
      ranges_distri[:R_not_found]||=0
      ranges_distri[:R_not_found]+=1
    end
    next
  end
  m = u.seq.gapped_pos(m)
  n = u.seq.gapped_pos(n+@r_primer.length)
  range = Range.new(m-@relax, n+@relax)
  if @only_show_range_distri
    ranges_distri[range]||=0
    ranges_distri[range]+=1
    range = nil
    next
  end
  if @search_primer_in_all
    print_range(u, range)
    range = nil
  end
end

if @only_show_range_distri
  ranges_distri.keys.each do |range|
    puts [range.inspect, ranges_distri[range]].join("\t")
  end
elsif !@search_primer_in_all
  raise "Primer pair not found" if range.nil?
  @infile.rewind
  @infile.each do |u|
    print_range(u, range)
  end
end
