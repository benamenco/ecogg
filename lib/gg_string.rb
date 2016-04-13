#
# (c) 2013, Giorgio Gonnella, ZBH, Uni-Hamburg
#
# %-PURPOSE-%
# General purpose extensions to String class
#

# General purpose extensions to String class
class String
  # position of all instances of a substring
  # modified from:
  #   http://stackoverflow.com/questions/3520208/
  #     get-index-of-string-scan-results-in-ruby?lq=1
  def indices(regex)
    arr = []
    scan(regex){arr << $~.offset(0)[0]}
    return arr
  end
  # split string into chunks of given length
  # (the last chunk may be shorter)
  def chunks(length)
    scan(/.{1,#{length}}/)
  end
  # truncate string to given length
  # inspired by:
  #   activesupport/lib/active_support/core_ext/string/filters.rb, line 38
  def truncate(tr_length,opts={})
    return self if length <= tr_length
    omission = opts[:omission] || "..."
    length_with_room_for_omission = tr_length - omission.length
    stop = rindex(" ",length_with_room_for_omission) ||
                      length_with_room_for_omission
    return self[0..stop]+omission
  end
  # show string in lines of width <width>,
  # printing the <pos>-th character with escape code <ecode> (default: red)
  def show_pos(pos, linewidth=50, ecode="0;31;40")
    if pos >= size || pos < -size
      raise "read has only #{size} characters (pos=#{pos})"
    end
    if pos < 0
      pos = size + pos
    end
    remaining=linewidth
    if pos > 0
      chunks=self[0..pos-1].chunks(linewidth)
      remaining-=chunks.last.size
    else
      chunks = [""]
    end
    if remaining == 0
      chunks << ""
      remaining = linewidth
    end
    chunks.last << "\033[#{ecode}m#{self[pos]}\033[0m"
    remaining -= 1
    if remaining > 0
      chunks.last << self[pos+1..pos+remaining]
      remaining = 0
    end
    if pos+remaining < size-1
      chunks << self[pos+remaining+1..size-1].chunks(linewidth)
    end
    puts chunks
  end

  # remove a prefix, and optionally raise an error if prefix not available
  def rm_pfx!(prefix, raise_if_not = true)
    if self[0..prefix.size-1] != prefix
      raise "'#{prefix}' not a prefix of '#{self}'" if raise_if_not
      return self
    end
    replace(slice(prefix.size..-1))
  end

end
