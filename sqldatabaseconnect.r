# Old code
# library(RODBC)
# # tried the tidyverse ODBC package, but it kept giving me errors
# library(tidyverse)
# conn=odbcDriverConnect(connection="Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=ntsb;UID=ntsb;PWD=Cessna182;")
# dat =conn%>% sqlQuery("select * from events")
# close(conn)

library(odbc)
library(DBI)
library(datasets)


conn <- dbConnect(
  odbc(),
  Driver = "ODBC Driver 17 for SQL Server",
  Server = "24.205.251.117",
  Database = rstudioapi::showPrompt("Database name","Database name"),
  UID = rstudioapi::showPrompt("Database username", "Database username"),
  PWD = rstudioapi::askForPassword("Database password")
)

# drop table from database, if it exists
dbExecute(conn, 'drop table if exists iris;')

# create new table from iris dataset
dbWriteTable(conn, name = "iris",  value = iris)

# make sure table exists in database
dbListTables(conn, table_name = "iris")

# list fields the new table
dbListFields(conn, name = "iris")

# get full dataframe of table
data <- dbReadTable(conn, name = "iris")
head(data)

# get query results: returns dataframe
species <- dbGetQuery(conn, 'select distinct Species from iris')
species

