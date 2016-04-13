#
# (c) 2013, Giorgio Gonnella, ZBH, Uni Hamburg
#
# %-PURPOSE-%
# Methods to handle Fasta format strings and files
#

require "gg_fastx.rb"

# :nodoc:
class String
  # Handle Fasta format String objects.
  module Fasta
    # ">0\nac\n1aa\na".fasta_seqs => ["ac","aaa"]
    def fasta_seqs
      a = []
      split("\n").each do |l|
        l[0..0] == ">" ? (a<<"") : (a.last<<l.chomp)
      end
      a
    end
    # extract FastaID from description line
    def fastaid
      self[1..-1].split[0]
    end
  end
  include Fasta
end

# :nodoc:
class Array
  module Fasta
    # convert string arrays of sequences into Fasta;
    # descriptions are ordinal numbers from 1, with an optional pfx
    def seqs_to_fasta(dscpfx="")
      str = ""
      each_with_index {|s,i|str << ">#{dscpfx}#{i+1}\n#{s}\n"}
      str
    end
  end
  include Fasta
end

# A FastaUnit consists of sequence number (ordinal number in MultiFasta file),
# description line and sequence
class FastaUnit < FastxUnit
  def initialize(seq,desc,seqnum)
    @seq,@desc,@seqnum=seq,desc,seqnum
    validate!
  end
  def validate!
    raise "Malformed Fasta data: #{self.inspect}" \
      unless desc[0..0]==">"
  end
  def to_s(splitline=0)
    s = (splitline == 0) ? @seq : @seq.chunks(splitline).join("\n")
    @desc+"\n"+s
  end
end

# Support for FastaFiles.
class FastaFile < FastxFile
  # Convert to array of sequences => ["agc","gta",...]
  def to_a
    a = []
    each_line do |l|
      l[0..0] == ">" ? (a<<"") : (a.last<<l.chomp)
    end
    a
  end
  # rewind file
  def rewind
    @nextdesc = nil
    super
  end
  # get next FastaUnit; nil if no more available
  def get
    desc = @nextdesc
    return nil if @nextdesc.nil? and @seqnum >= 0
    seq = ""
    @nextdesc = nil
    while l = gets
      if l[0..0] == ">"
        if @seqnum >= 0
          @nextdesc = l.chomp
          break
        else
          desc = l.chomp
        end
      else
        @seqnum += 1 if seq == ""
        seq << l.chomp
      end
    end
    if @skipwild && seq.wild?
      @seqnum -= 1
      return get
    end
    @unit=FastaUnit.new(seq,desc,@seqnum)
  end
end
