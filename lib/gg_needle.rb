#!/usr/bin/env ruby

require "tempfile"

# %-PURPOSE-%
# Wrapper for EMBOSS needle

class NeedleAligner

  EmbossPath = "/work/gi/software/emboss-6.5.7"
  NeedleCmd ="#{EmbossPath}/emboss/needle"

  attr_accessor :gapopen, :gapextend

  # for DNA the EDNAFULL matrix is used
  # where, for normal nucleotide chars:
  #   match +5.0
  #   mismatch -4.0

  def initialize
    @gapopen = 10.0
    @gapextend = 0.5
    @format = "fasta"
    @transform = nil
    @endweight = "no"
  end

  def disable_affine_gaps(gap_cost = 4.0)
    @gapopen = gap_cost
    @gapextend = gap_cost
  end

  def disable_unpenalized_endgaps
    @endweight = "yes"
  end

  def align(u,v)
    # since <(echo #{u}) <(echo #{v}) is not working:
    u_f = Tempfile.new("u"); u_f.puts u; u_f.close
    v_f = Tempfile.new("v"); v_f.puts v; v_f.close
    alignment =
      `#{NeedleCmd} -asequence #{u_f.path} \
                    -bsequence #{v_f.path} \
                    -aformat3 #{@format} \
                    -gapopen #{@gapopen} \
                    -gapextend #{@gapextend} \
                    -endweight #{@endweight} \
                    -endopen #{@gapopen} \
                    -endextend #{@gapextend} \
                    -outfile /dev/stdout \
                    2> /dev/null
      `
    u_f.unlink
    v_f.unlink
    alignment = @transform.call(alignment) if @transform
    return alignment
  end

  def format=(f)
    case f.to_sym
    when :simplecut
      @format=:simple
      @transform=lambda {|al| cut_simple(al)}
    else
      @format=f
    end
  end

  private

  def cut_simple(text)
    out = []
    state = 0
    text.split("\n").each do |line|
      if line =~ /#[=-]+/
        state += 1
      elsif state == 2
        out << line
      end
    end
    return out.join("\n")
  end

end

class NeedleReadsAligner < NeedleAligner
  def initialize
    super
    disable_affine_gaps
    disable_unpenalized_endgaps
  end
end

