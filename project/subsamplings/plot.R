#!/usr/bin/env Rscript
library(ggplot2)
library(plyr)
data1 <-read.table("vent_counts_shared.tsv")
sdata1 = ddply(data1, c("V1"), summarise, N=length(V2), mean=mean(V2),
              sd=sd(V2), se=sd/sqrt(N))
data2 <-read.table("../otu_tables_all_ouroo_but_random_subsampled_vents/vent_counts_shared.tsv")
sdata2 = ddply(data2, c("V1"), summarise, N=length(V2), mean=mean(V2),
              sd=sd(V2), se=sd/sqrt(N))
data3 <-read.table("vent_counts_shared.whole.tsv")
sdata3 = ddply(data3, c("V1"), summarise, N=length(V2), mean=mean(V2),
              sd=sd(V2), se=sd/sqrt(N))
sdata1$V1=sdata1$V1/27729283
sdata1$rarefaction="Open ocean"
sdata2$V1=7901441/sdata2$V1
sdata2$rarefaction="Vents"
sdata3$V1=sdata3$V1/27729283
sdata3$rarefaction="None (Whole data)"
sdata<-rbind(sdata1,sdata2)
sdata<-rbind(sdata,sdata3)
sdata$units="OTUs counts"

data1o <-read.table("vent_otus_shared.tsv")
sdata1o = ddply(data1o, c("V1"), summarise, N=length(V2), mean=mean(V2),
              sd=sd(V2), se=sd/sqrt(N))
data2o <-read.table("../otu_tables_all_ouroo_but_random_subsampled_vents/vent_otus_shared.tsv")
sdata2o = ddply(data2o, c("V1"), summarise, N=length(V2), mean=mean(V2),
              sd=sd(V2), se=sd/sqrt(N))
data3o <-read.table("vent_otus_shared.whole.tsv")
sdata3o = ddply(data3o, c("V1"), summarise, N=length(V2), mean=mean(V2),
              sd=sd(V2), se=sd/sqrt(N))
sdata1o$V1=sdata1o$V1/27729283
sdata1o$rarefaction="Open ocean"
sdata2o$V1=7901441/sdata2o$V1
sdata2o$rarefaction="Vents"
sdata3o$V1=sdata3o$V1/27729283
sdata3o$rarefaction="None (Whole data)"
sdatao<-rbind(sdata1o,sdata2o)
sdatao<-rbind(sdatao,sdata3o)
sdatao$units="OTUs"
sdata<-rbind(sdata,sdatao)
print(sdata)
pdf("combined_vo_ration_plot.pdf")
ggplot(sdata, aes(x=V1,y=mean,color=rarefaction,shape=units))+
  geom_errorbar(aes(ymin=mean-se,ymax=mean+se),width=500000)+
  geom_line()+
  geom_point()+
  scale_x_log10(limits=c(0.0005,500))+
  scale_y_continuous(limits=c(0,100))+
  xlab("Open ocean reads / Vent read")+
  ylab("% Shared")+
  theme(axis.text=element_text(size=21),
        axis.title=element_text(size=21,face="bold",vjust=-0.3))
dev.off()
