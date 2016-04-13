#!/usr/bin/env ruby
require "gg_otutable"

# %-PURPOSE-%
purpose="Convert OTU table to mothur rabund or sabund file."

usage=<<-end
#{purpose}

Usage: $0 [-sabund] <table>

<table>: OTU table in a TSV based format, as follows:

# any line starting with # but not #OTU is a comment line
      SiteA  SiteB  SiteC ...
OTU1  count  count  count ...
OTU2  count  count  count ...
...

==> the default output (rabund) is:
SiteA  n_otus  count  count  count ...
SiteB  n_otus  count  count  count ...

==> the output using the -sabund option is:
SiteA  max_count  n_otus_with_count1  n_otus_with_count2  ...
SiteB  max_count  n_otus_with_count1  n_otus_with_count2  ...

Note: the sabund file can be very large if large counts are present
end

sabundmode=ARGV.delete("-sabund")

if ARGV.size != 1
  STDERR.puts usage
  exit 1
end

filename = ARGV[0]
table = OtuTable.from_tsv(filename)
if sabundmode
  puts table.to_sabund
else
  puts table.to_rabund
end
