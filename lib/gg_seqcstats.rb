#
# (c) 2013, Giorgio Gonnella, ZBH, Uni-Hamburg
#
# %-PURPOSE-%
# Sequence composition statistics.
#

#
class String

  # Sequence composition statistics.
  module SeqCStats

    # Character distribution; warning:
    # everything which is not a spacing character or ACTGactg is counted
    # as wildcard without any check.
    def char_distri
      distri = {:A => 0, :C => 0, :G => 0, :T => 0, :wildcards => 0}
      each_char do |c|
        case c
        when "A","a" then distri[:A]+=1
        when "C","c" then distri[:C]+=1
        when "G","g" then distri[:G]+=1
        when "T","t" then distri[:T]+=1
        else
          if c !~ /\s/
            distri[:wildcards]+=1
          end
        end
      end
      distri
    end

    # GC content (only ACTGactg are counted).
    def gc
      cd = char_distri
      cg = cd[:C] + cd[:G]
      total = cg + cd[:A] + cd[:T]
      return cg.to_f/total
    end

    # AT content (only ACTGactg are counted).
    def at
      cd = char_distri
      at = cd[:A] + cd[:T]
      total = at + cd[:C] + cd[:G]
      return at.to_f/total
    end

    # GC skew (only ACTGactg are counted).
    def gc_skew
      cd = char_distri
      cmg = cd[:C] - cd[:G]
      cpg = cd[:C] + cd[:G]
      return cmg.to_f/cpg
    end

    # AT skew (only ACTGactg are counted).
    def at_skew
      cd = char_distri
      amt = cd[:A] - cd[:T]
      apt = cd[:A] + cd[:T]
      return amt.to_f/apt
    end

    # Compute the K-mer spectrum of sequence, for a given k.
    # The string is assume to contain ONLY the sequence, no spacing.
    # Wildcards can be optionally be considered.
    #
    # Options:
    #   skip_wild: skip non atcg, default: false
    #   rel:       relative frequencies, default: absolute counts
    #              (note: wild kmers are not counted)
    #   strand:    strand-specific, default: false
    #              (false means k-mer and its RC are counted together)
    def kmer_spectrum(k, options = {})
      spectrum = {}
      raise "k must be a positive integer" if !k.kind_of?(Integer) or k<=0
      dc=self.downcase
      skip=0
      total=0
      0.upto(length-k) do |startpos|
        if skip > 0
          skip-=1
          next
        end
        endpos = startpos + k - 1
        key = dc[startpos..endpos]
        if options[:skip_wild] and key.index(/[^acgt]/)
          # one can skip this and the next k-1 positions
          skip = k-1
          next
        end
        if !options[:strand]
          keyrc = key.revcompl
          if key > keyrc
            key = keyrc
          end
        end
        key = key.to_sym
        spectrum[key]||=0
        spectrum[key]+=1
        total+=1
      end
      if (options[:rel])
        spectrum.keys.each do |key|
          spectrum[key] = spectrum[key].to_f / total
        end
      end
      spectrum
    end
  end

  include SeqCStats
end
