#!/usr/bin/env Rscript
library("ggplot2")
t=read.table("otusp_countsp.dat")
pdf("otusp_countsp.pdf")
ggplot(t, aes(x=V1,y=V2,group=V3,colour=V3))+
   geom_line(stat="identity") +
   scale_x_continuous(lim=c(0,1)) +
   scale_y_continuous(lim=c(0,100)) +
   xlab("Portion of read length used") +
   ylab("% shared")
dev.off()
