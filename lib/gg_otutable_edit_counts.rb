#!/usr/bin/env ruby

# %-PURPOSE-%
# Methods to edit the counts in an OtuTable

class OtuTable

  def round_counts_for_site(site)
    i = site_number(site)
    @counts.each do |otu, counts|
      counts[i] = counts[i].round
    end
    self
  end

  def rescale_site(site, nreads, shall_round)
    i = site_number(site)
    multfactor = nreads / total_count(site).to_f
    @counts.each do |otu, counts|
      counts[i] *= multfactor
      counts[i] = counts[i].round if shall_round
    end
    self
  end

  def rescale(nreads, shall_round)
    @sites.each {|s| rescale_site(s,nreads,shall_round)}
    self
  end

end
