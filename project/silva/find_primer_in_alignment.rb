#!/usr/bin/env ruby
require "gg_optparse"
require "gg_fasta"
require "gg_wildcards"
require "gg_gap"

purpose "Find a primer in a 16s alignment"
positional :primer
positional :infile, :type => :infile, :fileclass => FastaFile
option :max_n_seq, 0, :type => :natural
switch :reverse_primer, :help => "RC the primer and report last coordinate"
switch :exclude_primer, :help => ["Report first coordinate outside the primer",
                                  "i.e. first after the primer for F and",
                                  "first before the primer for R"]
switch :mode, :help => "Only show most frequent coordinate (lowest if multiple)"
verbose_switch
optparse!

undefpos = -1

if @reverse_primer
  @primer = @primer.revcompl(true)
end

regexp = @primer.to_regexp

counts = {undefpos => 0}
until (u = @infile.get).nil? or (@max_n_seq > 0 and u.seqnum >= @max_n_seq)
  if @verbose and (u.seqnum % 1000 == 0)
    STDERR.print "."
  end
  m = (u.seq.ungap =~ regexp)
  if m.nil?
    counts[undefpos]+=1
  else
    if @exclude_primer
      if !@reverse_primer
        m += ($1.length)
      else
        m -= 1
      end
    else
      if @reverse_primer
        m += ($1.length-1)
      end
    end
    m = u.seq.gapped_pos(m)
    counts[m]||=0
    counts[m]+=1
  end
end

if @verbose
  STDERR.print "\n"
end

if @mode
  counts[undefpos]=0
  cmax = counts.max
  counts.each_with_index do |c, pos|
    if c == cmax
      puts pos
      exit 0
    end
  end
else
  counts.keys.sort.each do |pos|
    puts [pos == undefpos ? "not_found" : pos, counts[pos]].join("\t")
  end
end
