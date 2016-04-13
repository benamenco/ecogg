#
# (c) 2014, Giorgio Gonnella, ZBH, Uni Hamburg
#
# %-PURPOSE-%
# Arrays-related functionality
#

class Array
  # all possible subarrays
  def all_combinations
    out = []
    1.upto(self.size) {|n| out += combination(n).to_a}
    out
  end
  # all possible subarrays and their complements
  def all_splits
    all_combinations.map{|c|[c,self-c]}.to_enum
  end
end
