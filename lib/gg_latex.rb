#
# (c) 2013, Giorgio Gonnella, ZBH, Uni-Hamburg
#
# %-PURPOSE-%
# LaTeX-related functionality

class String
  module Latex
    def latex_escape
      ret = self.gsub("_","\\_")
      ret = ret.gsub("%","\\%")
      ret = ret.gsub("$","\\$")
      ret
    end
    def latex_escape!
      replace(latex_escape)
    end
  end
  include Latex
end

