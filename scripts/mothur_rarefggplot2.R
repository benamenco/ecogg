#!/usr/bin/env Rscript
require("ggplot2")
require("reshape")

# %-PURPOSE-%
# Prepare a rarefaction plot using Mothur results

args <- commandArgs(trailingOnly=TRUE)
infname <- args[1]
cat("input data: ",infname,"\n")
ylabel <- args[2]

data <- read.table(infname, header=T,sep="\t",fill=0)
data = melt(data, id.vars=c("numsampled"), variable_name="Site")
pdf(paste0(infname,".pdf"),width=10)
ggplot(data = data, aes(x=numsampled,y=value,group=Site)) +
  geom_line(aes(col=Site)) + xlab("Number of sequences") +
  ylab(ylabel)
dev.off()
