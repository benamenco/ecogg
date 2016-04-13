#
# (c) Giorgio Gonnella, 2014
#
# %-PURPOSE-%
# Proof-of-concept implementations of statistics methods

# IMPORTANT WARNING:
#
# The stuff here was implemented mainly only to understand it.
# Therefore: some methods are not implemented in a
# robust way (e.g. variance computation, which suffers
# of catastrophic cancellation with floats when computated
# as here).
#
# Besides that, using R can be a much better idea in most cases.
#

class Array

  def sum
    inject(0){|a,b|a+b}.to_f
  end

  def average
    sum / size
  end

  def deviations
    avg = average
    map {|i| i - average}
  end

  def variance(sample = true)
    n = sample ? size - 1 : size
    deviations.map{|d|d**2}.sum / n
  end

  def stdev(sample = true)
    Math::sqrt(variance(sample))
  end

  def each_jackknife_subset(&block)
    size.times do |i|
      subset = []
      subset += self[0..(i-1)] if i > 0
      subset += self[(i+1)..(size - 1)] if i < size - 1
      yield subset
    end
  end

  def percentile_nearest_rank(perc)
    (perc.to_f/100 * size).ceil
  end

  def percentile(perc)
    rank = percentile_nearest_rank(perc)
    rank == 0 ? nil : sort[rank-1]
  end

  def jackknife_distri(&block)
    estimators = []
    each_jackknife_subset do |subset|
      estimators << yield(subset)
    end
    estimators
  end

  def jackknife(&block)
    jackknife_distri(&block).average
  end

  def each_bootstrap_resample(n_resamples,&block)
    n_resamples.times do |i|
      subset = values_at(*Array.new(size) { rand(size) })
      yield subset
    end
  end

  def bootstrap_distri(n_resamples, &block)
    estimators = []
    each_bootstrap_resample(n_resamples) do |resample|
      estimators << yield(resample)
    end
    estimators
  end

  def bootstrap(n_resamples,&block)
    bootstrap_distri(n_resamples, &block).average
  end

  def bootstrap_ci(alpha,n_resamples,ci_method,&block)
    theta = yield(self)
    d = bootstrap_distri(n_resamples, &block)
    perc = alpha.to_f/2
    l = d.percentile(perc)
    h = d.percentile(100-perc)
    m = d.percentile(50)
    a = d.average
    case ci_method
    when :basic
      ci_l = 2*theta-h
      ci_h = 2*theta-l
    when :percentile
      ci_l = l
      ci_h = h
    else
      raise "CI method unknown (#{ci_method})"
    end
    ci_a = [ci_l,ci_h].average
    return [ci_l,m,a,theta,ci_a,ci_h]
  end

end
