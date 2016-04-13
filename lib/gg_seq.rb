#
# (c) 2013, Giorgio Gonnella, ZBH, Uni-Hamburg
#
# %-PURPOSE-%
# DNA sequence related extensions to String class.
#

require "gg_string.rb"
require "gg_gap.rb"
require "gg_twobit.rb"
require "gg_seqcstats.rb"
require "gg_wildcards.rb"

#
# DNA sequence related extensions to String class.
# RNA sequences (i.e. U instead of T) are generally not supported.
#
class String

  module DoubleStrand

    # reverse complement sequence
    # setting tolerant anything non-sequence is complemented to itself
    def revcompl(tolerant=false)
      each_char.map{|c|c.wcc(tolerant)}.reverse.join
    end

    WCC = {"a"=>"t","t"=>"a","A"=>"T","T"=>"A",
           "c"=>"g","g"=>"c","C"=>"G","G"=>"C",
           "b"=>"v","B"=>"V","v"=>"b","V"=>"B",
           "h"=>"d","H"=>"D","d"=>"h","D"=>"H",
           "R"=>"Y","Y"=>"R","r"=>"y","y"=>"r",
           "K"=>"M","M"=>"K","k"=>"m","m"=>"k",
           "S"=>"S","s"=>"s","w"=>"w","W"=>"W",
           "n"=>"n","N"=>"N","-"=>"-"}

    # Watson-Crick complement of base (single-character string)
    def wcc(tolerant=false)
      raise "String#wcc: string must be a single character (#{self})" if size != 1
      res = WCC[self]
      if res.nil?
        if tolerant
          res = self
        else
          raise "#{self}: no Watson-Crick complement defined"
        end
      end
      res
    end

  end

  include DoubleStrand
  include SeqCStats

end
