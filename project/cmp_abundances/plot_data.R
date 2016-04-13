#!/usr/bin/env Rscript
library("ggplot2")
args<-commandArgs(trailingOnly=T)
fn=paste0(args[1],".dat")
t<-read.table(fn)
p<-ggplot(t,aes(V1,V2))+
   xlab("Vents abundance")+ylab("Open Ocean abundance")
p+geom_point()
