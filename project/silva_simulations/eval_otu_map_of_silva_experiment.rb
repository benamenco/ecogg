#!/usr/bin/env ruby
require "gg_optparse"
purpose "Evaluate results of OTU picking using subregion of Silva Ref data (97%)"
positional :otumap, :type => :infile
optparse!

counts = {:lines => 0,
          :denovo => 0,
          :denovo_1 => 0,
          :denovo_m => 0,
          :refbased => 0,
          :refbased_1 => 0,
          :refbased_m => 0,
          :refbased_correct => 0,
          :refbased_noncorrect => 0,
          :refbased_1_correct => 0,
          :refbased_1_noncorrect => 0,
          :refbased_m_correct => 0,
          :refbased_m_noncorrect => 0,
          :multi => 0,
          :one_correct => 0,
          :one_noncorrect_or_denovo => 0}

def outstr(counts, part)
  [part, counts[part], "%.2f" % (counts[part].to_f*100/counts[:lines])].join("\t")
end

@otumap.each do |line|
  elems=line.chomp.split("\t")
  otuname=elems.shift
  multi=elems.size > 1
  counts[:lines]+=1
  if otuname =~ /New\..*/
    counts[:denovo]+=1
    if multi
      counts[:denovo_m]+=1
      counts[:multi]+=1
    else
      counts[:denovo_1]+=1
      counts[:one_noncorrect_or_denovo]+=1
    end
  else
    counts[:refbased]+=1
    correct = elems.include?(otuname)
    if multi
      counts[:refbased_m]+=1
      counts[:multi]+=1
      if correct
        counts[:refbased_m_correct]+=1
        counts[:refbased_correct]+=1
      else
        counts[:refbased_m_noncorrect]+=1
        counts[:refbased_noncorrect]+=1
      end
    else
      counts[:refbased_1]+=1
      if correct
        counts[:refbased_1_correct]+=1
        counts[:refbased_correct]+=1
        counts[:one_correct]+=1
      else
        counts[:refbased_1_noncorrect]+=1
        counts[:refbased_noncorrect]+=1
        counts[:one_noncorrect_or_denovo]+=1
      end
    end
  end
end

counts.keys.each do |k|
  puts outstr(counts, k)
end
