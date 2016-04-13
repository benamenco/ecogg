#
# (c) 2013, Giorgio Gonnella, ZBH, Uni-Hamburg
#
# %-PURPOSE-%
# Functionality related to Two-bit encoding sequence format.

class String
  # Functionality related to Two-bit encoding sequence format.
  module Twobit
    TwobitErrMsg1 = "String#twobit: invalid character found"

    # Convert DNA characters into twobit encoding;
    # returns a string with the bits; e.g. "AA" => "0000".
    def twobit
      raise TwobitErrMsg1 if self =~ /[^ACGTU\s]/i
      str = dup
      str.gsub!(/A/i,"00")
      str.gsub!(/C/i,"01")
      str.gsub!(/G/i,"10")
      str.gsub!(/T/i,"11")
      str
    end

  end
  include Twobit
end

class Integer
  # Functionality related to Two-bit encoding sequence format.
  module Twobit
    DecodeTwobitErrMsg1 = "Integer#decode_twobit: value larger than 64-bit"
    DecodeTwobitErrMsg2 = "Integer#decode_twobit: negative value"

    # Decode a 64-bit base-10 integer into a DNA sequence string.
    def decode_twobit
      raise DecodeTwobitErrMsg1 if self > (2 ** 64) - 1
      raise DecodeTwobitErrMsg2 if self < 0
      binary = self.to_i.to_s(4)
      out = ""
      binary.split("").each do |encoded|
        out << "acgt"[encoded.to_i].chr
      end
      prefix = "a" * (32 - out.size)
      prefix+out
    end
  end
  include Twobit
end

