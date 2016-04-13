#
# (c) 2013, Giorgio Gonnella, ZBH, Uni-Hamburg
#
# %-PURPOSE-%
# HTML-related functionality

class String
  # HTML-related functionality
  module HTML
    def html_escape
      ret = self.gsub("<","&lt;")
      ret = ret.gsub(">","&gt;")
      ret
    end
    def html_escape!
      replace(html_escape)
    end
    def html_tag(content = nil)
      xml_tag(content)
    end
    def xml_tag(content = nil)
      content ? "<#{self}>#{content}</#{self}>" : "<#{self}/>"
    end
  end
  include HTML
end

class Array
  def to_html_table_line(header = false, escape = true)
    itag = header ? "th" : "td"
    "tr".html_tag(map{|f|itag.html_tag(escape ? f.to_s.html_escape : f.to_s)}.join)
  end
end
