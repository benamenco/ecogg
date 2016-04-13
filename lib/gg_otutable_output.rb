#!/usr/bin/env ruby

# %-PURPOSE-%
# Methods to output an OtuTable to file

class OtuTable

  def to_tsv(opts = {})
    opts[:header_first_field] ||= "#OTU ID"
    opts[:sorted] ||= false
    lines = []
    t = @taxonomy ? "taxonomy" : nil
    lines << tsv_line(opts[:header_first_field],
                      @metadata ? metadata.keys : [], @sites, t)
    if opts[:sorted]
      out_order = otus - ["unclassified"]
      out_order = out_order.sort_by {|otu| -otu_total_count(otu)}
      if otus.include?("unclassified")
        out_order.unshift("unclassified")
      end
    else
      out_order = otus
    end
    out_order.each do |otu|
      counts=@counts[otu]
      lines << tsv_line(otu, fetch_metadata(otu), counts, fetch_taxonomy(otu))
    end
    lines.join("\n")
  end

  def to_classic
    to_tsv
  end

  def save_classic(filename)
    f = File.new(filename, "w")
    f.puts(to_classic)
    f.close
  end

  def to_rabund
    str = ""
    @sites.each_with_index do |site, i|
      site_counts = []
      @counts.keys.each do |otu|
        count = @counts[otu][i]
        if count > 0
          site_counts << count
        end
      end
      site_counts.unshift(site_counts.size)
      site_counts.unshift(site)
      str << site_counts.join("\t")+"\n"
    end
    str
  end

  def to_sabund
    str = ""
    @sites.each_with_index do |site, i|
      sabund = []
      @counts.keys.each do |otu|
        count = @counts[otu][i]
        if count > 0
          sabund[count] ||= 0
          sabund[count] += 1
        end
      end
      sabund[0] = sabund.size - 1
      sabund.size.times {|n| sabund[n] = 0 if sabund[n].nil? }
      sabund.unshift(site)
      str << sabund.join("\t")+"\n"
    end
    str
  end

  def to_inext
    str = ""
    @sites.each_with_index do |site, i|
      site_counts = []
      @counts.keys.each do |otu|
        count = @counts[otu][i]
        if count > 0
          site_counts << count
        end
      end
      site_counts.unshift(site)
      str << site_counts.join(" ")+"\n"
    end
    str
  end

  private

  def tsv_line(otu, metadata, counts, taxonomy)
    ([otu]+metadata+counts+[taxonomy]).compact.join("\t")
  end
  def fetch_taxonomy(otu, default = nil)
    @taxonomy ? @taxonomy[otu] : default
  end
  def fetch_metadata(otu, default = [])
    return default if @metadata.nil?
    @metadata.keys.map{|k|@metadata[k][otu]}
  end

end
