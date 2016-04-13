#!/usr/bin/env ruby

# %-PURPOSE-%
# OtuTable class

require "gg_raise"

class OtuTable

  attr_reader :sites, :counts, :taxonomy, :otus, :metadata

  def initialize(sites, counts, taxonomy = nil, metadata = nil)
    @sites = sites
    @counts = counts
    @taxonomy = taxonomy
    @metadata = metadata
    @metadata_header = []
  end

  def dup
    self.class.new(sites.dup,
                   counts.dup,
                   taxonomy ? taxonomy.dup : nil,
                   metadata ? metadata.dup : nil)
  end

  def create_taxonomy_column
    @taxonomy = {}
  end

  def add_metadata_for_otu(otu, key, value)
    @metadata ||= {}
    @metadata[key] ||= {}
    @metadata[key][otu] = value
  end

  def otus
    @counts.keys
  end

  def suppress_taxonomy!
    @taxonomy = nil
  end

  def suppress_metadata!
    @metadata = nil
  end

  attr_accessor :name

  def total_counts(for_sites = @sites)
    for_sites.map{|site|total_count(site)}
  end

  def overall_count(for_sites = @sites)
    total_counts(for_sites).inject(0){|a,b|a+b}
  end

  def otus_zero_nonzero
    n_otus_nonzero = 0
    n_otus_zero = 0
    otus.each do |otu|
      if @counts[otu].inject(0){|a,b|a+b} == 0
        n_otus_zero += 1
      else
        n_otus_nonzero += 1
      end
    end
    return n_otus_zero, n_otus_nonzero
  end

  def n_otus_zero
    otus_zero_nonzero[0]
  end

  def n_otus_nonzero
    otus_zero_nonzero[1]
  end

  def sites_info_table(n_otus_nonzero = nil)
    if !n_otus_nonzero
      n_otus_zero, n_otus_nonzero = otus_zero_nonzero
    end
    integer_counts=total_counts.all?{|x|x==x.to_i}
    retval = ["Site", "Total Count", "%", "OTUs", "%", "Av.count/OTU"].join("\t")+"\n"
    sites.each do |site|
      out = [site]
      tc_site = total_count(site)
      no_site = n_otus(site)
      out << (integer_counts ? tc_site.to_i : tc_site)
      out << ("%.1f" % (tc_site.to_f*100/overall_count))
      out << n_otus(site)
      out << ("%.1f" % (no_site.to_f*100/n_otus_nonzero))
      out << ("%.2f" % (tc_site.to_f/no_site))
      retval << out.join("\t")+"\n"
    end
    retval << "\n"
    out = ["Overall"]
    out << (integer_counts ? overall_count.to_i : overall_count)
    out << 100.0
    out << n_otus_nonzero
    out << 100.0
    out << ("%.2f" % (overall_count.to_f/n_otus_nonzero))
    retval << out.join("\t")+"\n"
    retval
  end

  def inspect
    tc = total_counts
    tcsum = overall_count
    name = @name
    name ||= object_id
    n_otus_zero, n_otus_nonzero = otus_zero_nonzero
    "OtuTable\t#{name}\n"+
      "N.sites\t#{sites.size}\n"+
      "Av.count/site\t#{("%.2f" % (tcsum.to_f/sites.size))}\n"+
      "Taxonomy?\t#{@taxonomy.nil? ? 'no' : 'yes'}\n"+
      "Metadata\t#{@metadata.nil? ? 'none' :
                              @metadata.keys.join(", ")}\n"+
      "Allzero OTUs\t#{n_otus_zero}\n\n"+
      sites_info_table(n_otus_nonzero)
  end

  def otu_sites(otu, absent_max = 0.0)
    out = []
    if @counts[otu]
      @counts[otu].each_with_index {|c,i| (out << @sites[i]) if c > absent_max }
    end
    out
  end

  def otu_counts_for_sites(otu, sites_list)
    @counts[otu].values_at(*site_numbers(sites_list))
  end

  def n_sites(otu, absent_max = 0.0)
    otu_sites(otu, absent_max).size
  end

  def site_numbers(sites_list)
    sites_list.map{|s| site_number(s)}
  end

  def site_number(site)
    i = sites.index(site.to_sym)
    raise "Site #{site} unknown; sites: #{sites.inspect}" if i.nil?
    i
  end

  def +(other)
    raise unless other.kind_of?(OtuTable)
    if metadata or other.metadata
      STDERR.puts "Warning: Metadata will be lost by + operation!"
    end
    new_sites = @sites.dup
    new_sites += other.sites
    if new_sites.uniq.size != new_sites.size
      raise "site lists collide, cannot sum otu tables"
    end
    new_counts = @counts.dup
    new_taxonomy = @taxonomy ? @taxonomy.dup :
      (other.taxonomy ? other.taxonomy.dup : nil)
    new_counts.keys.each do |otu|
      other_counts = other.counts[otu]
      other_counts ||= (Array.new(other.sites.size) {0.0})
      new_counts[otu] += other_counts
      merge_otu_taxonomy(otu, new_taxonomy, other.taxonomy)
    end
    other.counts.keys.each do |otu|
      next if new_counts[otu]
      new_counts[otu] = (Array.new(sites.size) {0.0}) + other.counts[otu]
      if new_taxonomy
        new_taxonomy[otu] = other.taxonomy[otu]
        new_taxonomy[otu] ||= "Unassigned"
      end
    end
    self.class.new(new_sites,new_counts,new_taxonomy,nil)
  end

  def set_alternative_taxonomy_source_for_merging(source)
    @alttaxsrc = {}
    File.readlines(source).each do |line|
      elems = line.chomp.split("\t")
      raise unless elems.size == 2
      @alttaxsrc[elems[0].to_sym] = elems[1]
    end
  end

  def random_subsample!(subsample_size)
    raise if subsample_size >= overall_count
    to_keep = (0..(overall_count-1)).to_a.sample(subsample_size).sort
    ctabpos = 0
    counts.each do |otu, otu_counts|
      otu_counts.each_with_index do |count, sitenum|
        ctabpos += count
        new_count = 0
        while !to_keep.empty? and to_keep[0] < ctabpos
          to_keep.shift
          new_count += 1
        end
        otu_counts[sitenum] = new_count
      end
    end
    self
  end

  private

  def merge_otu_taxonomy(otu, taxonomy, other_taxonomy)
    return if taxonomy.nil? or other_taxonomy.nil?
    if taxonomy[otu].nil?
      taxonomy[otu] = other_taxonomy[otu]
      taxonomy[otu] ||= "Unassigned"
    else
      if !other_taxonomy[otu].nil? and
        other_taxonomy[otu] != "Unassigned" and
        taxonomy[otu] != other_taxonomy[otu]
        if @alttaxsrc and @alttaxsrc[otu]
          taxonomy[otu] = @alttaxsrc[otu]
        else
          warn("Taxonomy inconsistence",
               "OTU ID", otu,
               "Taxonomy 1 (used)", taxonomy[otu],
               "Taxonomy 2", other_taxonomy[otu])
        end
      end
    end
  end

end

require "gg_otutable_input.rb"
require "gg_otutable_output.rb"
require "gg_otutable_biom.rb"
require "gg_otutable_alpha.rb"
require "gg_otutable_edit_sites.rb"
require "gg_otutable_edit_counts.rb"
require "gg_otutable_edit_otus.rb"
require "gg_otutable_intersections.rb"
