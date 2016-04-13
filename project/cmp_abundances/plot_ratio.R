#!/usr/bin/env Rscript
library("ggplot2")
args<-commandArgs(trailingOnly=T)
fn=paste0(args[1],".dat")
t<-read.table(fn)
p<-ggplot(t,aes(factor("vent reads"), y=V2/V1))
p+geom_boxplot(notch=T)+scale_y_log10()
