#
# (c) 2013, Giorgio Gonnella, ZBH, Uni-Hamburg
#
#
# %-PURPOSE-%
# Handling of wildcards in sequences.
class String

  Wildcards = {"N" => ["A","C","G","T"],
               "B" => ["C","G","T"],
               "H" => ["A","C","T"],
               "D" => ["A","G","T"],
               "V" => ["A","C","G"],
               "R" => ["A","G"],
               "Y" => ["C","T"],
               "S" => ["C","G"],
               "W" => ["A","T"],
               "K" => ["G","T"],
               "M" => ["A","C"]}

  # does the sequence contain anything except ACTG?
  def wild?
    self =~ /[^ACGTacgt\s]/
  end

  def to_regexp
    cpy = self.dup
    alternatives = cpy.split("|")
    alternatives = alternatives.map do |alt|
      Wildcards.keys.each do |wildcard|
        alt.gsub!(wildcard, "[#{Wildcards[wildcard].join()}]")
      end
      alt
    end
    if alternatives.size == 1
      cpy = alternatives[0]
    else
      cpy = "("+alternatives.join("|")+")"
    end
    Regexp.new(cpy)
  end

  def expand_wildcards
    oseqs=[""]
    each_char do |char|
      char.upcase!
      if %w{A C G T}.include?(char)
        oseqs.map!{|oseq| oseq+char}
      elsif Wildcards.keys.include?(char)
        oseqs_expanded = []
        oseqs.each do |oseq|
          Wildcards[char].each do |echar|
            oseqs_expanded << "#{oseq}#{echar}"
          end
        end
        oseqs = oseqs_expanded
      elsif char !~ /\s/
        raise "Unknown char in sequence: '#{char}'"
      end
    end
    return oseqs
  end

end
