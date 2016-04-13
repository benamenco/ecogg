#!/usr/bin/env ruby

# %-PURPOSE-%
# Methods to read in an OTU Table from file

class OtuTable

  def self.from_tsv(filename, opts = {})
    f = File.open(filename)
    t = self.from_tsv_file(f, opts)
    f.close
    t
  end

  # options:
  #   :verbose => true: turn on verbose msgs on stderr
  #   :metadata => []: columns containing metadata
  #   :headeronly
  def self.from_tsv_file(file, opts = {})
    sites = nil
    counts = {}
    taxonomy = nil
    n_otu_lines = 0
    n_allzero = 0
    linenumber = 0
    metadataindices = nil
    metadata = nil

    file.each do |line|
      linenumber += 1
      fields=line.chomp.split("\t")
      if line[0] == "#"
        next if fields.size == 1
        unless sites.nil?
          raise "Only one comment line containing tabs is allowed\n"+
            "Sites list previously found: #{sites.inspect}\n"+
          "Offending line:\n#{line}"
        end
        sites = fields[1..-1].map{|f|f.to_sym}
        if opts[:metadata] and !opts[:metadata].empty?
          opts[:metadata] = opts[:metadata].map{|x|x.to_sym}
          allsites = sites
          sites = sites - opts[:metadata]
          metadatakeys = allsites - sites
          if !metadatakeys.empty?
            metadata = {}
            metadataindices = {}
            metadatakeys.each do |k|
              metadata[k] = {}
              metadataindices[k] = allsites.index(k)
            end
            if opts[:verbose]
              unless metadatakeys.empty?
                STDERR.puts "Metadata columns found: #{metadatakeys.join("\t")}"
              end
              metadatanotfound = opts[:metadata] - metadatakeys
              STDERR.puts "Metadata columns not found: "+
                          "#{metadatanotfound.join("\t")}"
            end
          end
        end
        if sites.last == :taxonomy
          STDERR.puts "Table contains taxonomy as last column" if opts[:verbose]
          taxonomy = {}
          sites.pop
        end
        STDERR.puts "Sites: #{sites.inspect}" if opts[:verbose]
        break if opts[:headeronly]
      else
        otu = fields.shift.to_sym
        if counts.has_key?(otu)
          raise "OTU ID is not unique:\n#{line}"
        end
        if metadata
          metadata.keys.each do |k|
            metadata[k][otu] = fields[metadataindices[k]]
            fields[metadataindices[k]] = nil
          end
          fields.compact!
        end
        if taxonomy
          taxonomy[otu] = fields.pop if fields.size == sites.size + 1
        end
        if fields.size != sites.size
          raise "Wrong number of counts in line #{linenumber}:\n#{line}\n"+
            "expected: #{sites.size}, found: #{fields.size}\n"+
            "sites: #{sites.inspect}\n"+
            "counts found: #{fields.inspect}"
        end
        counts[otu] = fields.map{|f|f.to_f}
        n_otu_lines += 1
        if counts[otu].all?{|c|c == 0}
          n_allzero += 1
        end
        if opts[:verbose] and (n_otu_lines % 10000 == 0)
          STDERR.puts "...#{n_otu_lines} OTUs loaded..."
        end
      end
    end
    if opts[:verbose]
      STDERR.puts "Number of OTUs: #{n_otu_lines}"
      if n_allzero > 0
        STDERR.puts "OTUs where all counts are zero: #{n_allzero}"
      end
    end
    t = self.new(sites, counts, taxonomy, metadata)
    t.name = opts[:name]
    return t
  end

  def self.from_classic(filename, opts = {})
    from_tsv(filename, opts)
  end

end

