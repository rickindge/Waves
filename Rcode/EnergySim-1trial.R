# EnergySim



windMW<-13#seq(0,50,5)
solarMWp<-13#seq(0,50,5)
geoMWe<-3
mwsref<-1#6.3
mws<-1#9*(70/45)^(1/7)

windPower<-read.table("../data/specs/windPowerCurve.csv",header=FALSE,sep=",")

# read in demand files

# domestic demand MW
houses=17852
ddata<-read.csv("../data/profiles/EESP/domDem10.csv")
domDemand<-numeric()
domDemand<-houses*ddata$W/1e6
rm(ddata)

sum(domDemand/6)

#non-domestic demand
ndDemand<-rep(0,144*365)
nProfiles=5
pc10path<-"../data/profiles/UKERC/pc10minThin/"
for (i in 3:8){
  pc10file<-paste0(pc10path,"pc10.",i,".csv")
  pc10<-read.csv(pc10file,stringsAsFactors=FALSE)$W
  #plot(pc10)
  ndDemand<-ndDemand+pc10
}
#plot(ndDemand,type="l")
sum(ndDemand/6000) # MWh per representative UKERC business

nbusiness=1364 # total business in St Austell
medianNonDomUsage<-7.422 # MWh, DECC 2015

totalNdDemand<-ndDemand*(1364*7.422)/sum(ndDemand/6)

# microDemand<-0.83*nbusiness*(10000/sum(ndDemand/6000))*ndDemand/1e6
# smallDemand<-0.162*nbusiness*(20000/sum(ndDemand/6000))*ndDemand/1e6
# largeDemand<-0.008*nbusiness*(40000/sum(ndDemand/6000))*ndDemand/1e6
# 
# totalNdDemand<-microDemand+smallDemand+largeDemand


#rm(ndDemand,microDemand,smallDemand,largeDemand)

#plot(totalNdDemand,type="l")

sum(totalNdDemand/6) # annual Non Dom demand in MWh

# combine to give total demand
demand=domDemand+totalNdDemand

# library(rafalib)
# mypar(1,1)
# plot(demand,type="l",ylim=c(0,16))
# lines(domDemand,col="red")
# lines(totalNdDemand,col="blue")

# input file paths

sipfilepathstem<-"../data/synthetic/CamBSRN_Solar10minSyn/CamSolarSyn10min"
wipfilepathstem<-"../data/synthetic/CallywithWind10minSyn/Cally"
sipfilepathtail<-".csv"
wipfilepathtail<-"_10min.csv"

# set up input file numbers
ipfilename<-function(file,ipfilepathstem,ipfilepathtail){
  ipfilehandle<-as.character(file)
  if (file < 10){
    ipfilehandle<-paste0("00",ipfilehandle)
  }
  if (file >= 10 && file < 100){
    ipfilehandle<-paste0("0",ipfilehandle)
  }
  ipfilename<-paste0(ipfilepathstem,ipfilehandle,ipfilepathtail)
}


wp<-function(x){
  ifelse(x>19,1,windPower[which(windPower[,1]==x),2])
}

## loop through solar and wind files

numTrials<-1000
trial=0
stored=0
res<-data.frame()
#start<-proc.time()
begin=Sys.time()

  trial<<-trial+1
  wfile<-floor(100*runif(1)+1)
  sfile<-floor(100*runif(1)+1)
  
  print(paste("Trial: ",trial," Solar file:",sfile,", Wind file: ",wfile,sep=" "))
  
  wfilename<-ipfilename(wfile,wipfilepathstem,wipfilepathtail)
  sfilename<-ipfilename(sfile,sipfilepathstem,sipfilepathtail)
  
  wdata<-read.csv(wfilename)[,2]
  #wdata<-floor(wdata*mws/mwsref)
  
  sdata<-read.csv(sfilename)[,2]
  
  # data$day<-min(365,data$t %/% 144 +1)
  
  solarop<-numeric()
  windop<-numeric()
  geoop<-rep(geoMWe,length(wdata))
  totalop<-numeric()
  #solarop<-matrix(length(solarMWp)*length(sdata),length(sdata),length(solarMWp))
  #windop<-matrix(length(windMW)*length(wdata),length(wdata),length(windMW))
  
  # windop<-unlist(sapply(wdata,function(x){
  #   windMW*windPower[which(windPower[,1]==x),2]
  # }))
  
  #print(paste("Solar: ",SolarMWp,", Wind: ",WindMW))
  windop<-windMW*unlist(sapply(wdata,wp))
  
  # windop<-sapply(windMW,function(x){
  #   x*unlist(sapply(wdata,wp))
  # })
  solarop<-solarMWp*sdata/1000
  # solarop<-sapply(solarMWp,function (x){
  #   x*sdata/1000
  # })
  print (paste0("windop: ",length(windop)," solarop: ",length(solarop)))
  totalop<-windop+solarop+geoop
  balance<-totalop-demand# sweep(totalop,1,demand,FUN="-") #totalop-demand
  ebalance<-cumsum(balance)/6000 # in GWhy
  #powerop<-data.frame(windop,solarop,totalop,demand,balance,ebalance)
  # summary(powerop)
  #diff<-proc.time()-start
  #print(diff)
  c(min(balance),max(balance),mean(balance),median(balance),min(ebalance),max(ebalance),mean(ebalance),median(ebalance))
  #cbind(balance,ebalance)


end=Sys.time()

print(paste0("Time taken= ",end-begin))

# opfilename=paste0("wind",windMW,"solar",solarMWp,"geo",geoMWe,".csv")
# opfilepath="../results/"
# write.table(res,paste0(opfilepath,opfilename),col.names=FALSE,row.names=FALSE,sep=",")

# library(rafalib)
# mypar(4,2)
# hist(res[,1],breaks=50,main="min pbalance")
# hist(res[,2],breaks=50,main="max pbalance")
# hist(res[,3],breaks=50,main="mean pbalance")
# hist(res[,4],breaks=50,main="median pbalance")
# hist(res[,5],breaks=50,main="min ebalance")
# hist(res[,6],breaks=50,main="max ebalance")
# hist(res[,7],breaks=50,main="mean ebalance")
# hist(res[,8],breaks=50,main="median ebalance")
# 
# summary(res)
# 

library(rafalib)
library(openintro)
data(COL)
png("../results/OneTrialTimeSeries.png",width=595,height=842)

mypar(3,1)
days<-seq(1,1000)/144

# one week of power in winter
plot(days,demand[1:1000],type="l",
     ylim=c(-14,14),
     xlab="One week of Winter days",
     ylab="Power (MW)",
     col=COL[1]
     )
lines(days,solarop[1:1000],col=COL[2])
lines(days,windop[1:1000],col=COL[3])

lgnd=legend(-.2,-9,
       c("Demand","Solar generation","Wind generation","Balance"),
       lty=c(1,1,1,1),
       lwd=c(2.5,2.5,2.5,2.5),
       col=COL[1:4],
       box.lty=0,
       cex=0.9
)

lines(days,balance[1:1000],col=COL[4])     

# repeat for summer
plot(days,demand[25001:26000],type="l",
     ylim=c(-14,14),
     xlab="One week of Summer days",
     ylab="Power (MW)",
     col=COL[1]
     )
lines(days,solarop[25001:26000],col=COL[2])
lines(days,windop[25001:26000],col=COL[3])

lgnd=legend(-.2,-9,
            c("Demand","Solar generation","Wind generation","Balance"),
            lty=c(1,1,1,1),
            lwd=c(2.5,2.5,2.5,2.5),
            col=COL[1:4],
            box.lty=0,
            cex=0.9
)


lines(days,balance[25001:26000],col=COL[4])

# energy balance
ydays<-seq(1,length(ebalance))/144
plot(ydays,ebalance,type="l",xlab="One year of days",ylab="Energy balance (GWh)")
abline(h=mean(ebalance),col=COL[1])
text(30,mean(ebalance),"mean energy balance",pos=3)

dev.off()

# plot histograms of power demand, generation and balance

png("../results/OneTrialHistograms.png",width=595,height=842)
mypar(3,1)
hist(demand,main="Demand (MW)",xlab="Demand (MW)",probability="TRUE")
hist(totalop,main="Generation (MW)",xlab="Generation (MW)",probability="TRUE")
hist(balance,main="Power Balance (MW)",xlab="Power Balance (MW)",probability="TRUE")
dev.off()
# 
# 
