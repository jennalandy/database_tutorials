library(odbc)
library(DBI)

conn <- dbConnect(
  odbc(),
  Driver = "ODBC Driver 17 for SQL Server",
  Server = "24.205.251.117",
  Database = "JennaDb", #rstudioapi::showPrompt("Database name","Database name"),
  UID = "Jenna", #rstudioapi::showPrompt("Database username", "Database username"),
  PWD = "ShadeHome8$" #rstudioapi::askForPassword("Database password")
)

get_tables <- function() {
  values = dbListTables(conn)[
    grepl('BAKERY', dbListTables(conn))
  ]
  names = str_replace(values, 'BAKERY_', '')
  tables = as.list(setNames(values, names))
  tables
}