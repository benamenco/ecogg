#!/usr/bin/env ruby

# %-PURPOSE-%
# Methods which change the OTU list in an OtuTable

class OtuTable

  # otu shall be a symbol
  def rm_otu!(otu)
    @counts.delete(otu)
    @taxonomy.delete(otu) if @taxonomy
    self
  end

  def add_otu!(otu, counts, taxonomy = "n.a.")
    @counts[otu] = counts
    @taxonomy[otu] = taxonomy if @taxonomy
    self
  end

  # otu_list shall be an array of symbols
  def rm_otus!(otu_list)
    otu_list.each {|otu| rm_otu!(otu)}
    self
  end

  def taxatable_rm_other!
    to_remove = []
    otus.each do |taxon|
      elems = taxon.to_s.split(";")
      if ["Other","Unassigned","Unclassified"].include?(elems.last)
        to_remove << taxon
      end
    end
    rm_otus!(to_remove)
    self
  end

  def collapse_otus!(otu_list, options = {})
    options[:to] ||= :not_in_subset
    if otus.include?(options[:to])
      collapsed = counts[options[:to]]
    else
      collapsed = Array.new(sites.size) {0.0}
    end
    otu_list.each do |otu|
      otu_counts = counts[otu]
      raise "otu not found: #{otu}" if otu_counts.nil?
      sites.size.times {|i| collapsed[i] += otu_counts[i]}
    end
    rm_otus!(otu_list + [options[:to]])
    add_otu!(options[:to], collapsed)
  end

  def otu_total_count(otu)
    @counts[otu].inject(0.0){|a,b|a+b}
  end

  def filter_otus_by_total_count!
    to_remove = []
    @counts.each do |otu, counts|
      total_count = counts.inject(0.0){|a,b|a+b}
      (to_remove << otu) if yield(total_count)
    end
    rm_otus!(to_remove)
    self
  end

  def filter_otus_by_sites!
    to_remove = []
    @counts.each do |otu, counts|
      (to_remove << otu) if yield(otu_sites(otu))
    end
    rm_otus!(to_remove)
    self
  end

  def filter_otus_by_counts!
    to_remove = []
    @counts.each do |otu, counts|
      (to_remove << otu) if yield(counts)
    end
    rm_otus!(to_remove)
    self
  end

  def filter_otus_by_relative_abundance!
    tc = sites.map{|site|total_count(site)}
    to_remove = []
    @counts.each do |otu, counts|
      abundances = []
      counts.each_with_index{|c, i|abundances << c.to_f / tc[i]}
      (to_remove << otu) if yield(abundances)
    end
    rm_otus!(to_remove)
    self
  end

  def rm_allzero!
    filter_otus_by_total_count!{|tc| tc == 0.0}
  end

  def rm_total_singletons!
    filter_otus_by_total_count!{|tc| tc == 1}
  end

  def extract_total_singletons
    dup.filter_otus_by_total_count!{|tc| tc != 1}
  end

  def extract_non_total_singletons
    dup.filter_otus_by_total_count!{|tc| tc == 1}
  end

  # otu_list shall be an array of symbols
  def retain_only_otus!(otu_list)
    rm_otus!(otus - otu_list)
  end

  def collapse_except_otus!(otu_list)
    collapse_otus!(otus - otu_list)
  end

  # extract OTUs where abundance >= threshold in at least one site
  def extract_frequent(min_abundance)
    t = dup
    t.filter_otus_by_relative_abundance! do |abundances|
      abundances.all?{|a| a < min_abundance}
    end
    t
  end

  # extract OTUs where abundance < threshold in all sites
  def extract_rare(threshold)
    t = dup
    t.filter_otus_by_relative_abundance! do |abundances|
      abundances.any?{|a| a >= threshold}
    end
    t
  end

  def split_by_abundance(rare_threshold, frequent_threshold)
    frequent = extract_frequent(frequent_threshold)
    rare = extract_rare(rare_threshold)
    middle = dup.rm_otus!(rare.otus).rm_otus!(frequent.otus)
    results = {:rare => rare, :frequent => frequent, :middle => middle}
    if otus.include?(:not_in_subset)
      [frequent, rare, middle].each {|t| t.rm_otu!(:not_in_subset)}
      nistax = @taxonomy ? {:not_in_subset => "n.a."} : nil
      nis = self.class.new(sites.dup,
                           {:not_in_subset => counts[:not_in_subset]}, nistax)
      results[:not_in_subset] = nis
    end
    results
  end

end
