#
# (c) 2014, Giorgio Gonnella, ZBH, Uni Hamburg
#
# %-PURPOSE-%
# Handling of delimiter-separated files
#

require "gg_string"
require "gg_html"
require "gg_latex"

# helper method
def chk_nfields(expected, fields)
  if !expected.nil?
    if expected != fields.size
      msg = "Number of fields is inconsistent!\n"+
             "(expected: #{expected}; found: #{fields.size})\n"
      msg += "Fields: '#{fields.inspect}'"
      raise msg
    end
  end
  return fields.size
end

# Method for reading dsv files
#
# Options:
#   :sep => "\t"               separator (default: \t)
#   :chk_nfields => true       check consistency of number of fields
#   :skip => 0                 number of comment lines before header
#   :header => true            is there a header line?
#   :skip_after => 0           number of lines to skip after header
#   :hpfx => nil               pfx of header to remove (e.g. comment symbol)
#
# yields: array_of_fields, is_header_bool
#
def each_dsv_line(fname, opts = {})
  raise "each_dsv_line: fname is nil!" if fname.nil?
  opts[:sep]         ||= "\t"
  opts[:chk_nfields] = true if opts[:chk_nfields].nil?
  opts[:skip]        ||= 0
  opts[:header] = true if opts[:header].nil?
  opts[:skip_after]  ||= 0
  opts[:hpfx]        ||= nil
  f = File.open(fname)
  nfields = nil
  if opts[:header]
    opts[:skip].times {f.readline}
    header=f.readline
    header.rm_pfx!(opts[:hpfx]) if opts[:hpfx]
    fields = header.chomp.split(opts[:sep], -1)
    yield fields, true
    nfields = fields.size
    opts[:skip_after].times {f.readline}
  end
  f.each do |line|
    fields=line.chomp.split(opts[:sep], -1)
    nfields = chk_nfields(nfields, fields) if opts[:chk_nfields]
    yield fields, false
  end
  f.close
end

# Read entire dsv file and save content in array or hash
# can be called directly or through wrapper methods defined below
#
# see options of each_dsv_line
#
# If used directly, the following options can be set:
#   :key => nil                Save data in associative array or hash
#                              using the specified key.
#                              The key can be specified as field name when
#                              :header is true; otherwise 0-based field number.
#   :hash => nil               If true and :key, return an hash
#   :rmkey => false            remove key from values?
#
# returns:
# if opts[:header], content, fieldnames
# otherwise content
# where content is:
# - an array of fields if !opts[:key]
# - an associative array [[key, field]...] if opts[:key] and !opts[:hash]
# - an hash {key => field, ...} if opts[key] and opts[:hash]
def read_dsv(fname,opts = {})
  if !opts[:key]
    raise "Key must be selected to store data in hash" if opts[:hash]
    raise "rmkey options requires key option" if opts[:rmkey]
  end
  keynum = opts[:key]
  fieldnames = []
  data = opts[:hash] ? {} : []
  each_dsv_line(fname, opts) do |fields, is_header|
    if is_header
      fieldnames = fields
      if keynum.kind_of?(String) # convert it in field number
        keynum = fieldnames.index(opts[:key])
        msg="Field '#{opts[:key]}' not available (#{fname})"
        raise msg if keynum.nil?
      end
    else
      if keynum
        key = opts[:rmkey] ? fields.delete_at(keynum) : fields[keynum]
        if opts[:hash]
          data[key] = fields
        else
          data << [key,fields]
        end
      else
        data << fields
      end
    end
  end
  fieldnames.delete_at(keynum) if opts[:rmkey] and keynum
  if !opts[:header]
    return data
  else
    return data, fieldnames
  end
end

def dsv_to_a(fname, opts = {})
  opts[:key] = nil
  opts[:hash] = false
  opts[:rmkey] = false
  read_dsv(fname, opts)
end

def dsv_to_assoc(fname, key, opts = {})
  opts[:key] = key
  opts[:hash] = false
  opts[:rmkey] = true if opts[:rmkey].nil?
  read_dsv(fname, opts)
end

def dsv_to_h(fname, key, opts = {})
  opts[:key] = key
  opts[:hash] = true
  opts[:rmkey] = true if opts[:rmkey].nil?
  read_dsv(fname, opts)
end

def dsv_to_html(fname, opts = {})
  opts[:wrap] ||= false
  opts[:outfile] ||= STDOUT
  opts[:outfile].puts "<html><head></head><body>" if opts[:wrap]
  opts[:outfile].puts "<table>"
  each_dsv_line(fname,opts) do |fields, is_header|
    opts[:outfile].puts fields.to_html_table_line(is_header)
  end
  opts[:outfile].puts "</table>"
  opts[:outfile].puts "</body></html>" if opts[:wrap]
end

def dsv_to_latex(fname, opts = {})
  opts[:wrap] ||= false
  opts[:outfile] ||= STDOUT
  first_line = true
  opts[:chk_nfields] = true
  if opts[:wrap]
    opts[:outfile].puts "\\documentclass[12pt]{article}"
    opts[:outfile].puts "\\pagestyle{empty}"
    opts[:outfile].puts "\\begin{document}"
  end
  each_dsv_line(fname, opts) do |fields, is_header|
    if first_line
      opts[:outfile].puts "\\begin{tabular}{#{"l"*fields.size}}"
      first_line = false
    end
    fields = fields.map{|f|f.latex_escape}
    if is_header
      fields = fields.map{|f|"\\textbf{#{f}}"}
    end
    opts[:outfile].puts fields.join(" & ")+"\\\\"
  end
  opts[:outfile].puts "\\end{tabular}"
  if opts[:wrap]
    opts[:outfile].puts "\\end{document}"
  end
end

