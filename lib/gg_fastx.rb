#
# (c) 2013, Giorgio Gonnella, ZBH, Uni Hamburg
#
# %-PURPOSE-%
# Generic support for Fasta/Fastx format
#

require "gg_seq.rb"

class String
  # extract FastaID from description line
  def fastaid
    self[1..-1].split[0]
  end
end

class FastxUnit
  attr_accessor :seq,:desc,:seqnum
  def fastaid; desc.fastaid; end
  def wild?; seq.wild?; end
  def twobit; seq.twobit; end
  def length; seq.length; end
end

class FastxFile < File
  attr_reader :seqnum
  def skipwild
    @skipwild = true
  end
  def initialize(fname)
    @seqnum = -1
    super(fname,"r")
  end
  def each
    while unit = get
      yield unit
    end
  end
  def to_hash
    hsh=Hash.new
    each{|u|hsh[u.fastaid.to_sym]=u.seq}
    return hsh
  end
  def search(fastaid)
    while unit = get
      return unit if unit.fastaid == fastaid
    end
    return nil
  end
  def self.search(fastaid,fname)
    u=nil
    open(fname){|f| u = f.search(fastaid)}
    raise "Read #{fastaid} not found in #{fname}" if u.nil?
    return u
  end
  def rewind
    @seqnum = -1
    super
  end
  def get_by_seqnum(seqnum)
    rewind if @seqnum > seqnum
    while @seqnum < seqnum
      get
      return nil if @unit.nil?
    end
    return @unit
  end
end
