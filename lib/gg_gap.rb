#
# (c) Giorgio Gonnella
#
# %-PURPOSE-%
# Support for gaps in sequences.
#

class String

  module Gaps

    def gapped_pos(ungapped_pos)
      raise if ungapped_pos < 0
      raise if ungapped_pos >= ungapped_length
      needed_chars = ungapped_pos + 1
      i = 0
      each_char do |char|
        if char != "-"
          needed_chars -= 1
        end
        break if needed_chars == 0
        i += 1
      end
      i
    end

    # array of positions of gap opening
    def gap_openings
      res = indices("-") # do not use lookbehind for 1.8 compatibility
      del = []
      res.each_with_index {|n,i| del << i if res[i-1]==n-1}
      del.each {|i| res[i] = nil}
      res.compact!
      res
    end

    # length of gap opening at position <gap_opening_pos>;
    # if <gap_opening_pos> is not a gap, returns 0
    def gap_length(gap_opening_pos)
      res = self[gap_opening_pos..size-1].index(/[^-]/)
      res.nil? ? size-gap_opening_pos : res
    end

    # remove gaps from sequence
    def ungap
      gsub("-","")
    end

    # length without gaps
    def ungapped_length
      length-scan("-").size
    end

  end

  include Gaps
end
