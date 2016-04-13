#!/usr/bin/env ruby
require "gg_optparse"
require "gg_otutable"

purpose "Collect statistics about reference and de-novo OTUs."
positional :otutable, :type => :infile
option :pfx, "New", :help => "Unique prefix, which all de-novo OTUs share."
optparse!

t = OtuTable.from_tsv_file(@otutable)
new = t.otus.select{|x|x.to_s =~ /^#{Regexp.quote(@pfx)}/}
puts("# denovo OTUs: #{new.size} (%.2f%%)" % (new.size.to_f * 100 / t.otus.size))
old = t.otus - new
puts("# refbased OTUs: #{old.size} (%.2f%%)" % (old.size.to_f * 100 / t.otus.size))
t.collapse_otus!(new, :to => :denovo)
t.collapse_otus!(old, :to => :refbased)
t.suppress_taxonomy!
t.rescale(1, false)
puts t.to_tsv
