#!/usr/bin/env ruby
require "gg_otutable"
fn="../H2.vents_vs_ouroo/otu_table_mc1_w_tax.collapsed.classic"
t1 = OtuTable.from_tsv(fn)
t1.rm_site(:OpenOcean)
t1.rm_allzero!

t2 = OtuTable.from_tsv(fn)
t2.rm_site(:"Not-OpenOcean")
t2.rm_allzero!

f1=File.open("otu_table.vents.classic", "w")
f1.puts t1.to_tsv
f1.close

f2=File.open("otu_table.oo.classic", "w")
f2.puts t2.to_tsv
f2.close
