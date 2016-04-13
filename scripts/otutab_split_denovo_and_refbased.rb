#!/usr/bin/env ruby
require "gg_optparse"
require "gg_otutable"

# %-PURPOSE-%
purpose "Split reference and de-novo OTUs."
positional :otutable, :type => :infile,
  :outfiles => {:ref_o => ".refbased", :denovo_o => ".denovo",
                :stats => ".dn_rb_stats"}
option :pfx, "New", :help => "Unique prefix, which all de-novo OTUs share."
optparse!

t = OtuTable.from_tsv_file(@otutable)
n_otus = t.n_otus_nonzero
n_seqs = t.overall_count
denovo = t.otus.select{|x|x.to_s =~ /^#{Regexp.quote(@pfx)}/}
ref = t.otus - denovo
t_denovo = t.dup.rm_otus!(ref)
t_ref = t.dup.rm_otus!(denovo)

dn_n_otus = t_denovo.n_otus_nonzero
dn_n_otus_p = dn_n_otus.to_f / n_otus
rb_n_otus = n_otus - dn_n_otus
rb_n_otus_p = 1 - dn_n_otus_p

dn_n_seqs = t_denovo.overall_count
dn_n_seqs_p = dn_n_seqs.to_f / n_seqs
rb_n_seqs = n_seqs - dn_n_seqs
rb_n_seqs_p = 1 - dn_n_seqs_p

dn_av_c_o = dn_n_seqs.to_f / dn_n_otus.to_f
rb_av_c_o = rb_n_seqs.to_f / rb_n_otus.to_f

def fp(perc)
  "%.2f" % (perc * 100)
end

@stats.puts ["","Count","% all","OTUs","% all","av.count"].join("\t")
@stats.puts ["Ref.based",
             rb_n_seqs, fp(rb_n_seqs_p),
             rb_n_otus, fp(rb_n_otus_p),
             "%.1f" % rb_av_c_o
            ].join("\t")
@stats.puts ["De novo",
             dn_n_seqs, fp(dn_n_seqs_p),
             dn_n_otus, fp(dn_n_otus_p),
             "%.1f" % dn_av_c_o
            ].join("\t")

@denovo_o.puts t_denovo.to_tsv
@ref_o.puts t_ref.to_tsv
