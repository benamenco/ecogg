#
# (c) Giorgio Gonnella
#
# %-PURPOSE-%
# Support for Qiime mapping file format
#

require "gg_dsv"

class QiimeMapping

  attr_reader :fieldnames, :keyname

  def initialize(fname, get_sample_key="SampleID")
    @fname = fname
    @data, @fieldnames = read_dsv(@fname, :header => true, :hpfx => "#")
    set_sample_key(get_sample_key)
    validate_fieldnames!
  end

  def has_field?(fieldname)
    @fieldnames.include?(fieldname)
  end

  def set_sample_key(fieldname)
    @key = get_fieldnum(fieldname)
    @keyname = fieldname
  end

  def delete_field(field)
    fieldnum = get_fieldnum(field)
    @fieldnames.delete_at(fieldnum)
    @data.each{|fields|fields.delete_at(fieldnum)}
    set_sample_key(@keyname)
  end

  def delete_sample(sample)
    @data.delete_if{|fields|get_sample_key(fields)==sample}
  end

  def samples
    @data.map{|fields|get_sample_key(fields)}
  end

  def samples_for_field(field)
    fieldnum = get_fieldnum(field)
    retval = []
    @data.each do |fields|
      content = fields[fieldnum]
      if !content.nil? and !content.empty? and content != "NA"
        retval << get_sample_key(fields)
      end
    end
    retval
  end

  def import_fields(tsv_filename, foreign_key = "SampleID")
    ivalues, ifields = read_dsv(tsv_filename,
                                :key => foreign_key,
                                :rmkey => true,
                                :hash => true)
    @fieldnames = merge_fields(@fieldnames,ifields)
    n_ifields=ifields.size
    @data.map! do |fields|
      ifields = ivalues[get_sample_key(fields)]
      ifields ||= Array.new(n_ifields){""}
      merge_fields(fields, ifields)
    end
  end

  def to_s
    (["#"+@fieldnames.join("\t")] +
     @data.map{|fields| fields.join("\t")}).join("\n")
  end

  def validate_fieldnames!
    qmsg="#{@fname} is not a valid Qiime mapping file\n"
    msg="#{qmsg}Header should start with #SampleID"
    raise msg if @fieldnames[0]!="SampleID"
    msg="#{qmsg}Last field should be Description"
    raise msg if @fieldnames[-1]!="Description"
  end

  def inspect
    out = ""
    out << "Valid Qiime mapping\t"
    if @fieldnames[0] == "SampleID" and @fieldnames[-1] == "Description"
      out << "yes\n"
    else
      out << "no\n"
    end
    out << "Number of fields\t#{@fieldnames.size}\n"
    out << "Fields\t#{@fieldnames.inspect}\n"
    out << "Number of samples\t#{@data.size}\n"
    out << "Samples\t#{samples.inspect}\n"
  end

  private

  # merges a mapping fields array with additional fields
  # keeping the Description as rightmost field
  def merge_fields(mfields, ifields)
    mfields[0..-2] + ifields + mfields[-1..-1]
  end

  def get_fieldnum(fieldname)
    fieldnum = @fieldnames.index(fieldname)
    if fieldnum.nil?
      raise "Field '#{fieldname}' not found\nFields: #{@fieldnames.inspect}"
    end
    fieldnum
  end

  def get_sample_key(fields)
    fields[@key]
  end

end
