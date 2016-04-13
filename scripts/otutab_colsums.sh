#!/bin/bash
if [ $# -ne 1 ]; then
  # %-PURPOSE-%
  echo "Compute the column sums of an OTU table"
  echo "Usage: $0 <otutable>"
  exit 1
fi

compute_alpha_div.rb total_count $1
