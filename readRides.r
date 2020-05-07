readRides <- function(filename)
{
  rides = read_csv(filename)
  colnames(rides)=c("Date","Live","Instructor","Length","Discipline","Type","Title","ClassTime","Output","AvgWatts","AvgResistance","RPM","MPH","Miles","Calories","AvgHR","Incline","Pace")
  #Workout Timestamp,Live/On-Demand,Instructor Name,Length (minutes),Fitness Discipline,Type,Title,Class Timestamp,Total Output,Avg. Watts,Avg. Resistance,Avg. Cadence (RPM),Avg. Speed (MPH),Distance (miles),Calories Burned,Avg. Heartrate,Avg. Incline,Avg. Pace (min/mile)
  
  # Get rid of Beyond The Ride entries
  rides = rides[grep("Cycling",rides$Discipline),]
  # Distinguish between Hannah Marie Corbin and Hannah Fran...
  rides$Instructor[grep("Hannah Marie",rides$Instructor)] = "HMC"
  rides$AvgResistance=as.numeric(str_replace(rides$AvgResistance,"%",""))
  rides$Instructor = str_replace(rides$Instructor," .*","")
  
  return(rides)
}