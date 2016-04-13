#!/usr/bin/env ruby
require "gg_optparse"
require "gg_fasta"
require "gg_logger"
require "gg_needle"
require "gg_stats"

# %-PURPOSE-%
purpose "Compare each sequence of an OTU to a database sequence"
positional :database_sequence, :type => :infilename
positional :otu_sequences, :type => :infilename,
  :outfiles => {:lowidfile => ".low_identity"}
verbose_switch
debug_switch
option :revcompl_threshold, 0.9,
  :help => "if ID < threshold, revcompl is aligned"
option :threshold, 0.97,
  :help => "Alignments with ID < Threshold are written to threshold_file"
optparse!

db_sequence = nil
db_sequence_f = FastaFile.new(@database_sequence)
db_sequence_f.each do |unit|
  if unit.seqnum > 0
    optparse_die "Database sequence fasta file shall contain a single sequence"
  end
  db_sequence = unit
end
db_sequence_f.close
if db_sequence.nil?
  optparse_die "Database sequence fasta file is empty"
end

nal = NeedleAligner.new
nal.format = :fasta

AlignmentInfo = Struct.new(:alignment, :fastaid,
                           :start_gap, :end_gap,
                           :alignment_size, :identities, :gaps,
                           :id_fraction, :gaps_fraction) do
   def inspect
     "sequence: #{self.fastaid}\n"+
     "start_gap: #{self.start_gap}\n"+
     "end_gap: #{self.end_gap}\n"+
     "alignment_size: #{self.alignment_size}\n"+
     "gaps: #{self.gaps_fraction} (#{self.gaps}/#{self.alignment_size})\n"+
     "identities: #{self.id_fraction} "+
       "(#{self.identities}/#{self.alignment_size})\n"
   end
   def to_s
     self.inspect.split("\n").map{|x| "# #{x}"}.join("\n")+"\n"+self.alignment
   end
end

def show_results(distributions, n, n_r, fastaid)
  puts "DB Sequence\t#{fastaid}"
  puts "Number of sequences\t#{n}\tFwd\t#{n-n_r}\tRev\t#{n_r}"
  puts "\tMin\tMax\tAverage\tSt.dev"
  [["Alignment size",:alignment_sizes],
   ["Start gap",:start_gap_sizes],
   ["End gap",:end_gap_sizes],
   ["Gaps",:gaps_fractions],
   ["Identities",:id_fractions]].each do |label, arykey|
     ary = distributions[arykey]
     puts [label, ary.min, ary.max, ary.average, ary.stdev].join("\t")
  end
end

def append_to_results(info, distributions)
  distributions[:alignment_sizes] << info.alignment_size
  distributions[:start_gap_sizes] << info.start_gap
  distributions[:end_gap_sizes]   << info.end_gap
  distributions[:gaps_fractions]  << info.gaps_fraction
  distributions[:id_fractions]    << info.id_fraction
end

def align(nal, db_sequence, unit, revcompl)
  info = AlignmentInfo.new
  info.fastaid = unit.fastaid
  info.alignment = nal.align(db_sequence.seq,
                             revcompl ? unit.seq : unit.seq.revcompl)
  db_aligned, otu_aligned = info.alignment.fasta_seqs
  raise unless db_aligned.size == otu_aligned.size
  otu_aligned =~ /^(-*)[^-]/
  info.start_gap = $1.size
  otu_aligned =~ /[^-](-*)$/
  info.end_gap = $1.size
  otu_aligned = otu_aligned[info.start_gap..-(1+info.end_gap)]
  db_aligned = db_aligned[info.start_gap..-(1+info.end_gap)]
  info.alignment_size = otu_aligned.size
  info.gaps = 0
  info.identities = 0
  info.alignment_size.times do |i|
    if otu_aligned[i] == "-" or db_aligned[i] == "-"
      info.gaps+=1
    elsif otu_aligned[i] == db_aligned[i]
      info.identities+=1
    end
  end
  info.gaps_fraction = info.gaps.to_f / info.alignment_size
  info.id_fraction = info.identities.to_f / info.alignment_size
  return info
end

distributions =
  { :alignment_sizes => [],
    :start_gap_sizes => [],
    :end_gap_sizes => [],
    :gaps_fractions => [],
    :id_fractions => [] }

n = 0
n_r = 0

FastaFile.new(@otu_sequences).each do |unit|
  n += 1
  info = align(nal, db_sequence, unit, false)
  if info.id_fraction < @revcompl_threshold
    info_rc = align(nal, db_sequence, unit, true)
    if info_rc.id_fraction > info.id_fraction
      info = info_rc
      n_r += 1
    end
  end
  append_to_results(info, distributions)
  if info.id_fraction < @threshold
    @lowidfile.puts info.to_s+"\n\n"
    vlog "Low identity found"
    vlog info.to_s
  end
end

show_results(distributions, n, n_r, db_sequence.fastaid)
