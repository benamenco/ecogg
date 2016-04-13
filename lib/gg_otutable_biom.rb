# %-PURPOSE-%
# Wrapper for the biom utility in context of the OtuTable class

class OtuTable

  def self.from_biom(filename, opts = {})
    classic_fn = self.biom.to_classic(filename, opts)
    self.from_tsv(classic_fn, opts)
  end

  def save_biom(filename, opts = {})
    if !opts[:classic_fn]
      opts[:classic_fn] = get_classic_fn(filename)
      if File.exists?(opts[:classic_fn])
        raise "Filename collision, #{filename} exists"
      end
    end
    save_classic(opts[:classic_fn])
    opts[:has_taxonomy] = !@taxonomy.nil?
    opts[:biom_fn] = filename
    OtuTable.classic_to_biom(opts[:classic_fn], opts)
  end

  def self.compute_summaries(filename)
    OtuTable.check_biom!
    ["otus", "seqs"].each do |stype|
      of = filename + ".#{stype}.summary.txt"
      q = stype == "otus" ? "--qualitative" : ""
      `rm -f #{of} && biom summarize-table #{q} -i #{filename} -o #{of}`
      raise "biom summarize-table failed" unless $?.success?
    end
  end

  # opts:
  # :has_taxonomy => bool, default: true
  # :classic_fn => string, filename for classic table, default: computed
  def self.biom_to_classic(filename, opts = {})
    opts[:has_taxonomy] ||= true
    opts[:classic_fn] ||= get_classic_fn(filename)
    OtuTable.check_biom!
    raise "File #{filename} not found" unless File.exists?(filename)
    tstr = opts[:has_taxonomy] ? "--header-key=taxonomy" : ""
    `biom convert -i #{filename} -o #{opts[:classic_fn]} --to-tsv #{tstr}`
    raise "biom convert failed" unless $?.success?
    return classic_fn
  end

  def self.classic_to_biom(filename, opts = {})
    opts[:has_taxonomy] ||= true
    opts[:biom_fn] ||= get_biom_fn(filename)
    OtuTable.check_biom!
    raise "File #{filename} not found" unless File.exists?(filename)
    tstr = opts[:has_taxonomy] ? "--process-obs-metadata=taxonomy" : ""
    tt = "--table-type=\"OTU table\""
    `biom convert #{tt} -i #{filename} -o #{opts[:biom_fn]} --to-hdf5 #{tstr}`
    raise "biom convert failed" unless $?.success?
    return biom_fn
  end

  private

  def self.check_biom!
    `which biom`
    unless $?.success?
      raise "'biom' not found in path"
    end
  end

  def get_classic_fn(biom_filename)
    if classic_fn.nil?
      if biom_filename =~ /(.*).biom/
        classic_fn = "#$1.classic"
      else
        classic_fn = "#{biom_filename}.classic"
      end
    end
    return classic_fn
  end

  def get_biom_fn(classic_filename)
    if biom_fn.nil?
      if classic_filename =~ /(.*).classic/
        biom_fn = "#$1.biom"
      else
        biom_fn = "#{classic_filename}.biom"
      end
    end
    return biom_fn
  end

end
