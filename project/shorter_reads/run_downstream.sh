otutab_biom_to_classic.sh otu_table_mc2.biom
otutab_remap.rb otu_table_mc2.classic ../remap.yml > otu_table_mc2.sites.classic
otutab_remap.rb otu_table_mc2.sites.classic ../remap.oo_vents.yml > otu_table_mc2.oo_vents.classic
../../scripts/otu_table/split_otu_table_by_intersection.rb otu_table_mc2.oo_vents.classic
