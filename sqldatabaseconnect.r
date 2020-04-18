library(RODBC)
# tried the tidyverse ODBC package, but it kept giving me errors
library(tidyverse)
conn=odbcDriverConnect(connection="Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=ntsb;UID=ntsb;PWD=Cessna182;")
dat =conn%>% sqlQuery("select * from events")
close(conn)
