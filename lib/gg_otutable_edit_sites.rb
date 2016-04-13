#!/usr/bin/env ruby

# %-PURPOSE-%
# Methods which change the sites list of an OtuTable

class OtuTable

  def rm_site(site)
    i = site_number(site)
    @sites.delete_at(i)
    @counts.each {|k,v| v.delete_at(i)}
    self
  end

  def keep_only_sites(sites_to_keep)
    sites_to_keep.map!{|x|x.to_sym}
    sites_to_rm = @sites.dup - sites_to_keep
    sites_to_rm.each do |site|
      rm_site(site)
    end
    self
  end

  def rename_site(old, new)
    i = site_number(old)
    @sites[i]=new.to_sym
    self
  end

  def merge_sites(to_merge, new_site)
    indices = site_numbers(to_merge).sort.reverse
    indices.each {|i| @sites.delete_at(i)}
    @sites << new_site.to_sym
    to_remove = []
    @counts.each do |otu, counts|
      new_count = 0
      indices.each {|i| new_count += counts.delete_at(i)}
      counts << new_count
      to_remove << otu if counts.all? {|c| c==0}
    end
    to_remove.each {|r| @counts.delete(r)}
    self
  end

  def merge_all_sites
    merge_sites(@sites, "Total")
  end

  def reorder_sites(siteslist)
    siteslist = siteslist.map{|s|s.to_sym}
    if @sites.sort != siteslist.sort
      raise "invalid siteslist: #{@sites.inspect} != #{siteslist.inspect}"
    end
    order = siteslist.map{|s|@sites.index(s)}
    @sites = siteslist
    @counts.each do |otu, counts|
      @counts[otu] = counts.values_at(*order)
    end
    self
  end

end
