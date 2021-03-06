  setwd("c:/users/Daver/Downloads")
  downloadDir="."
  hrzones=read.csv("c:/users/daver/src/Pythia/AlgorithmRepository/dkrUtils/R/peloton/heartRateZones.csv")
  source("c:/users/Daver/src/pythia/AlgorithmRepository/dkrUtils/R/usePackage.r")
  source("c:/users/Daver/src/pythia/AlgorithmRepository/dkrUtils/R/peloton/readRides.r")
  
options(stringsAsFactors=FALSE)
options(repos=structure(c(CRAN="http://cran.rstudio.com",CRANextra="http://www.stats.ox.ac.uk/pub/RWin")))
#plist=c("stringr","ggplot2","tidyr","data.table","dtplyr","magrittr","readr")
plist=c("stringr","ggplot2","tidyr","dplyr","magrittr","readr","knitr","pander","kableExtra","lubridate")
lapply(plist,FUN=usePackage)
michele=F
rootName="Rhoda_bike"
if (michele==T)
{
  rootName="oneLMichele"
}
csvData=paste0(rootName,"_workouts.csv")
csvList=list.files(path=downloadDir,pattern=rootName)
myIndex = which.max(as.integer(str_extract(csvList,"\\d+")))
if (length(myIndex) == 1)
{
  csvData = csvList[myIndex]
}
csvData=file.path(downloadDir,csvData)
# Test stopping condition
#csvData="IDONTEXIST"

if (!file.exists(csvData))
{
  #message(paste0("The file ",csvData," does not exist. We can not continue."))
  stop(paste0("The file ",csvData," does not exist. We can not continue."))
}
message(paste0("Reading ride data from ",csvData))

rides = readRides(csvData)

# Get rid of BTR workouts
#rides = rides %>% subset(!(rides$Type %in% c("Toning","Stretch")))
fixOldNARides = FALSE
if (fixOldNARides)
{
  oldRides = readRides("Rhoda_bike_workouts_KEEPTHISONE.csv")

  # Try adding back the rides that have NA Output.
  # First, find those rides
  narides=rides[is.na(rides$Output),]
  # Now, get the oldRides from the same dates
  replacements=oldRides %>% subset(Date %in% narides$Date)
  # And then put those replacements on top of the NA output rides
  rides[rides$Date %in% replacements$Date,] = replacements
}

# Finally, get rid of any APP rides.  We're only interested in the rides
# from the bike.
#rides = rides[!is.na(rides$Output),]
# New on 11/07/2017.  Replaces the above line.
# Since App rides now count, and I've only taken the one, replace the NA's for the app
# ride with the means of the preceding rides.  Not the best solution, but it gets 
# rid of the NA's.
i = which(is.na(rides$Output))[1] # Only grab the first value.
if (is.na(i))
{
  i = which(rides$Output==0)[1]
}
tempMean = rides[1:(i-1),8:15] %>% summarise_all(funs(mean(.,na.rm=TRUE)))
rides[i,8:15] = round(tempMean[1,],digits=0)
rm(tempMean)

rides$Date[rides$ClassTime=="2017-05-16 11:18"] = "2017-05-22 06:06"

rides$DayOfWeek = factor(weekdays(as.Date(rides$Date)),levels=c("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"))
rides$DaysOwned = ceiling(as.numeric(difftime(rides$Date,rides$Date[1],units="days")))

rides$DaysSinceLastRide=0
rides$DaysSinceLastRide[2:nrow(rides)] = rides$DaysOwned[2:nrow(rides)] - rides$DaysOwned[1:(nrow(rides)-1)]
# Change the Type of the Heart Rate Zone rides so that it reflects the
# target heart rate zone.
rides$Type[rides$Type=="Heart Rate Zone"] = rides$Title[rides$Type=="Heart Rate Zone"]
rides$Type=str_replace(rides$Type,"45 min (.*) Ride","\\1")

# Change the Type of the Power Zone rides so that it reflects the
# target power zone.
rides$Type[rides$Type=="Power Zone"] = rides$Title[rides$Type=="Power Zone"]
rides$Type=str_replace(rides$Type,"45 min (.*) Ride","\\1")

# Change the Type of the Theme rides so that it reflects the theme
## This gets too granular.
#rides$Type[rides$Type=="Theme"] = rides$Title[rides$Type=="Theme"]
#rides$Type=str_replace(rides$Type,".. min (.*) Ride","\\1")

# Add month column so I can get stats by month
rides$month=as.factor(str_replace(rides$Date,".*-(.*)-.*","\\1"))
rides$year=as.factor(str_replace(rides$Date,"(.*)-.*-.*","\\1"))

# for example
monthSummary = rides %>% group_by(year,month) %>% dplyr::summarise(N=n(),TotTime=round(sum(Length)/60,digits=2),TotMiles=round(sum(Miles),digits=2),MPH=round(TotMiles/TotTime,digits=2))


# Add in January.  This code can go away in a couple of weeks when
# the new year begins. Only run this chunk of code if January doesn't exist
# in the data.
if (nrow(monthSummary) < 12) {
  # First, add the level for January, "01".
  monthSummary$month=factor(monthSummary$month,levels=c("01","02","03","04","05","06","07","08","09","10","11","12"))
  # Second, add a dummy entry to the data.frame for January "data".
  monthSummary[12,] = c("01",0,NA,NA,NA)
  
}
# Last, rename the levels to names of the months.
levels(monthSummary$month)=c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
# Average calories and watts by length
rides %>% group_by(Length) %>% dplyr::summarise(N=n(),MeanC=mean(Calories))
daysOwnedBike = tail(rides$DaysOwned,1)

dayOfWeekSummary = rides %>% group_by(DayOfWeek) %>% dplyr::summarise(N=n())
#print(x[order(x$DayOfWeek,decreasing=F),])
instructorSummary = rides %>% group_by(Instructor) %>% dplyr::summarise(N=n())
#print(x[order(x$N,decreasing=T),])
```

## R Markdown

Owned the bike `r daysOwnedBike` days.
Ridden the bike `r nrow(rides)` times and traveled `r round(sum(rides$Miles),digits=2)` miles in `r round(sum(rides$Length)/60,digits=2)` hours.

Ridden the bike `r round(nrow(rides)/daysOwnedBike,digits=2)`% of days.

Of the `r nrow(rides)` rides, `r sum(rides$Live=="Live")` of them were taken live.


```{r,echo=FALSE,results='asis',fig.width=5,fig.height=5}
#xx=factor(month(rides$Date,label=TRUE),levels=c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"))
#kable(summary(xx),col.names="N",caption="Month Summary",format="html") %>% kable_styling(bootstrap_options=c("condensed","striped"),full_width=F,position="float_left")

#kable(t(summary(xx)),caption="Month Summary",format="html") %>% kable_styling(bootstrap_options=c("condensed","striped"),full_width=F,position="float_left")
#rides45 = rides %>% subset(Length==45)

kable(monthSummary, "html",caption="Monthly Summary") %>% kable_styling(bootstrap_options=c("condensed","striped"),full_width=F,position="left")

rides45 = rides  %>% subset(Length==45) %>% mutate(curMax=cummax(Output),Day=str_replace(Date," .*",""),Hour=str_replace(Date,".*(\\d\\d:\\d\\d):\\d\\d.*","\\1"))
 

p = instructorSummary %>% ggplot(aes(x=Instructor,y=N)) + geom_bar(stat="identity") + theme(axis.text.x=element_text(angle=45,hjust=1))
kable(t(instructorSummary), row.names=F,format="html",caption="Instructor Summary") %>% kable_styling(bootstrap_options=c("condensed","striped"),full_width=F, position="float_left")

```
```{r,echo=FALSE,results='asis',fig.width=5,fig.height=5}

#kable(dayOfWeekSummary, caption="Rides By Day",format="html",table.attr="style='width:20%'")

p=dayOfWeekSummary %>% ggplot(aes(x=DayOfWeek,y=N)) + geom_bar(stat="identity")+ theme(axis.text.x=element_text(angle=45,hjust=1))
plot(p)

kable(t(dayOfWeekSummary), row.names=F, format="html",caption="Day Of Week Summary") %>% kable_styling(bootstrap_options=c("condensed","striped"),full_width=F, position="float_left")

p = rides45 %>% ggplot(aes(x=DaysOwned,y=Output)) + geom_point() +xlab("Day") + stat_smooth(method='loess')
plot(p)
ridesX = rides45[grep("Power Zone|Low|HRZ",rides45$Type,invert=T),]
p = ridesX %>% ggplot(aes(x=DaysOwned,y=Output)) + geom_point() +xlab("Day") + stat_smooth(method='loess') + ggtitle("Ignoring Power Zone and Low Impact Rides")
plot(p)
p = rides45 %>% ggplot(aes(x=DaysOwned,y=Calories)) + geom_point() +xlab("Day") + stat_smooth(method='loess')
plot(p)
p = rides45 %>% ggplot(aes(x=DaysOwned,y=RPM)) + geom_point() +xlab("Day") + stat_smooth(method='loess')
plot(p)
p = rides45 %>% ggplot(aes(x=DaysOwned,y=AvgResistance)) + geom_point() +xlab("Day") + stat_smooth(method='loess')
plot(p)
p=ggplot(rides45,aes(Type)) + geom_bar() + theme(axis.text.x=element_text(angle=45,hjust=1))
plot(p)

p = ggplot(rides45,aes(x=DaysOwned,y=Output)) + geom_point() + facet_wrap(~Type)
plot(p)

```

## Personal Records Summary

```{r,echo=FALSE,results='asis',fig.width=5,fig.height=5}
xx=rle(rides45$curMax)
prs = rides45[cumsum(xx[[1]])+1,]
prs=prs[!is.na(prs$Day),] # get rid of extraneous extra row.
x = prs[,c("Day","Hour","Instructor","Type","Output","AvgResistance","RPM", "DayOfWeek", "DaysSinceLastRide")]



p = ggplot(prs,aes(x=DaysOwned,y=Output)) + geom_line() + geom_point(aes(x=DaysOwned,y=Output,color=Instructor))
plot(p)


#kable(prs %>% group_by(Instructor) %>% summarise(N=n()) %>% arrange(-N),"html")  %>% kable_styling(bootstrap_options=c("condensed","striped"),full_width=F, position="float_right")
#panderOptions("table.style","simple")



kable(x, "html",caption="Personal Records") %>% kable_styling(bootstrap_options=c("condensed","striped"),full_width=F,position="float_left")


prCount = prs %>% group_by(Instructor) %>% dplyr::summarise(Count=n()) %>% arrange(-Count)

kable(t(prCount),"html",caption="PR By Instructor") %>% kable_styling(bootstrap_options=c("condensed","striped"),full_width=F,position="float_left") %>% column_spec(1,bold=T)

prCount = prs %>% group_by(DayOfWeek) %>% dplyr::summarise(Count=n()) # %>% arrange(-Count)
kable(t(prCount),"html",caption="PR By Day Of Week") %>% kable_styling(bootstrap_options=c("condensed","striped"),full_width=F,position="float_left") %>% column_spec(1,bold=T)

#kable(instructorSummary, caption="Rides By Instructor",format="html",table.attr="style='width:20%'")

```
