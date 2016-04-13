#!/usr/bin/env ruby

# %-PURPOSE-%
# Alpha diversity computation from an OtuTable object

class OtuTable
  def n_otus(site)
    i = site_number(site)
    @counts.keys.inject(0) do |count,otu|
      @counts[otu][i] > 0 ? count + 1 : count
    end
  end
  def n_otu_with_count(count,site)
    i = site_number(site)
    @counts.keys.inject(0) do |num,otu|
      @counts[otu][i] == count ? num + 1 : num
    end
  end
  def n_otus_with_count(count,site)
    n_otu_with_count(count,site)
  end
  def n_singletons(site)
    n_otus_with_count(1,site)
  end
  def n_doubletons(site)
    n_otus_with_count(2,site)
  end
  def p_singletons(site)
    n_singletons(site).to_f / n_otus(site)
  end
  def p_doubletons(site)
    n_doubletons(site).to_f / n_otus(site)
  end
  def chao1_classic(site)
    f_1 = n_singletons(site)
    f_2 = n_doubletons(site)
    raise "Chao1 classic undefined, f_2 is 0" if f_2 == 0
    s_obs = n_otus(site)
    s_obs + (f_1.to_f**2)/(2*f_2)
  end
  def chao1_bias_corrected(site)
    f_1 = n_singletons(site)
    f_2 = n_doubletons(site)
    s_obs = n_otus(site)
    s_obs + (f_1*(f_1-1).to_f)/(2*(f_2+1))
  end
  def chao1(site)
    chao1_bias_corrected(site)
  end
  def p_chao1(site)
    n_otus(site).to_f / chao1(site)
  end
  def p_ace(site)
    n_otus(site).to_f / ace(site)
  end
  def u_chao1(site)
    1 - p_chao1(site)
  end
  def u_ace(site)
    1 - p_ace(site)
  end
  def ace(site,maxrare=10)
    i = site_number(site)
    s_rare = 0.0
    f_1 = 0.0
    n_rare = 0.0
    n_rare_w = 0.0
    s_abund = 0.0
    @counts.keys.each do |otu|
      count = @counts[otu][i]
      if count > 0
        if count <= maxrare
          if count == 1
            f_1 += 1
          end
          s_rare += 1
          n_rare += count
          n_rare_w += count*(count-1)
        else
          s_abund += 1
        end
      end
    end
    c_ace = 1 - (f_1/n_rare)
    raise "All rares are singletons, ACE cannot be computed" if c_ace == 0
    y2_ace = ((s_rare/c_ace)*(n_rare_w/(n_rare*(n_rare-1))))-1
    y2_ace = 0 if y2_ace < 0
    s_ace = s_abund + (s_rare/c_ace) + (f_1/c_ace)*(y2_ace)
  end
  def jackknife1(site)
    n_otus(site)+n_singletons(site)
  end
  def jackknife2(data)
    n_otus(site)+2*n_singletons(site)-n_doubletons(site)
  end
  def total_count(site)
    i = site_number(site)
    @counts.keys.inject(0) do |count,otu|
      count + @counts[otu][i]
    end
  end
  def shannon(site,logbase=E)
    i = site_number(site)
    q = total_count(site)
    @counts.keys.inject(0) do |h,otu|
      q_i = @counts[otu][i]
      if q_i > 0
        p_i = (q_i.to_f / q)
        h + (p_i*log(p_i,logbase))
      else
        h
      end
    end * -1
  end
  def shannon_log2(site)
    shannon(site,2)
  end
  def shannon_max(site,logbase=E)
    log(n_otus(site),logbase)
  end
  def heip_e(site,logbase=E)
    # note heip_e is independent from the logbase choice
    # thus changing logbase may only affect rounding
    (logbase**shannon(site,logbase)-1)/(n_otus(site)-1)
  end
  def heip_e_qiime(site,logbase=E)
    (logbase**(shannon(site)-1))/(n_otus(site)-1)
  end
  def pielou_e(site)
    shannon_e(site)
  end
  def shannon_e(site)
    shannon(site)/shannon_max(site)
  end
  def gini_simpson(site)
    1-simpson(site)
  end
  def simpson(site)
    i = site_number(site)
    q = total_count(site)
    @counts.keys.inject(0) do |h,otu|
      q_i = @counts[otu][i]
      p_i = (q_i.to_f / q)
      h + (p_i**2)
    end
  end
  def invsimpson(site)
    1.0/simpson(site)
  end
  def simpson_e(site)
    invsimpson(site)/n_otus(site)
  end
  def simpson_e_qiime(site)
    (1.0/gini_simpson(site))/n_otus(site)
  end
  def self.alpha_indices
    [:n_otus, :shannon_max, :heip_e, :shannon, :total_count, :pielou_e,
     :heip_e_qiime, :simpson, :invsimpson, :simpson_e, :gini_simpson,
     :ace, :chao1, :chao1_classic, :jackknife1, :jackknife2, :shannon_log2,
     :n_singletons, :n_doubletons, :simpson_e_qiime, :p_singletons,
     :p_doubletons, :p_ace, :p_chao1, :u_ace, :u_chao1]
  end
  AlphaIndicesHelpMsg=<<-end
    n_otus           number of OTUs            (S)
    n_singletons     number of singletons      (f_1)
    n_doubletons     number of doubletons      (f_2)
    p_singletons     portion of singletons     (f_1 / S)
    p_doubletons     portion of doubletons     (f_2 / S)
    total_count      number of individuals     (Q)
    shannon          Shannon-Weaver diversity  (H')
    shannon_max      Shannon-Weaver max div    (H'_{max})
    pielou_e         Shannon / Shannon_max     (J')
    shannon_log2     Shannon with logbase 2    (H'_base2)
    heip_e           Heip's evenness           (E_{Heip} = ((e^H')-1)/(S-1))
    heip_e_qiime     Qiime ver. of Heip's E    (           (e^(H'-1))/(S-1))
    ace              ACE estimator             (S_{ace})
    chao1            Chao1 estimator (bias-c.) (S_{chao1})
    chao1_classic    Chao1 estimator (classic) (S_{chao1-classic})
    jackknife1       Jackknife 1st order est   (S_{jackknife1})
    jackknife2       Jackknife 2nd order est   (S_{jackknife2})
    simpson          Simpson's dominance index (D)
    gini_simpson     1 - Simpson               (1 - D)
    invsimpson       1 / Simpson               (1 / D)
    simpson_e        Simpson's evenness index  (E_{Simpson} = 1 / ( D   *S))
    simpson_e_qiime  Qiime ver. of Simpson E   (              1 / ((1-D)*S))
  end
end

