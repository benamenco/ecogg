#!/usr/bin/env Rscript
library("ggplot2")
t=read.table("plot.data")
ranks=c("Species","Genus","Family","Order","Class","Phylum","Kingdom")
t$V1=factor(t$V1,levels=ranks)
pdf("plot.pdf");
ggplot(t, aes(x=V2,y=V3,group=V1,colour=V1)) +
  geom_line(stat="identity") +
  scale_x_continuous(lim=c(0,1.125),
                     breaks=c(0,0.125,0.250,0.375,0.500,0.625,0.750,0.875,1,1.125))
dev.off()
