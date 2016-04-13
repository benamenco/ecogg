# %-PURPOSE-%
# OtuTable methods involving intersection of OTUs between sites

class OtuTable

  # find otus present in all <in_sites>;
  # if <only_exclusive> is true, then only
  # otus exclusively present in the sites
  #
  # Options
  # - mincount: minimal count
  # - countonly: how many otus per site
  #
  def intersection(in_sites, only_exclusive, opts = {})
    opts[:mincount] ||= 1
    opts[:countonly] ||= false
    in_sites_indices = site_numbers(in_sites)
    not_in_sites = only_exclusive ? @sites - in_sites : []
    not_in_sites_indices = site_numbers(not_in_sites)
    otus = opts[:countonly] ? 0 : []
    @counts.each do |otu, counts|
      if in_sites_indices.all?{|i| counts[i] >= opts[:mincount]} and
           not_in_sites_indices.all?{|i| counts[i] < opts[:mincount]}
        opts[:countonly] ? (otus += 1) : (otus << otu)
      end
    end
    otus
  end

  def extract_core_otus
    dup.retain_only_otus!(intersection(sites, false))
  end

  def collapse_non_core_otus
    dup.collapse_except_otus!(intersection(sites, false))
  end

  def extract_exclusive_otus(site)
    dup.retain_only_otus!(intersection([site], true))
  end

  def count_exclusive_otus
    exclusive = {}
    sites.each do |site|
      exclusive[site] = intersection([site], true, :countonly => true)
    end
    exclusive
  end
end
