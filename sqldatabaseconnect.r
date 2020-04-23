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

# open connection
conn <- dbConnect(
  odbc(),
  Driver = "ODBC Driver 17 for SQL Server",
  Server = "24.205.251.117",
  Database = rstudioapi::showPrompt("Database name","Database name"),
  UID = rstudioapi::showPrompt("Database username", "Database username"),
  PWD = rstudioapi::askForPassword("Database password")
)

# --- Simple Table: Iris ---

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

# --- Related Tables Connected by Keys: Bakery ---

# load dataframes
customers <- read.csv('BAKERY/customers.csv', stringsAsFactors = FALSE)
goods <- read.csv('BAKERY/goods.csv', stringsAsFactors = FALSE)
items <- read.csv('BAKERY/items.csv', stringsAsFactors = FALSE)
items$Item <- trimws(items$Item)
receipts <- read.csv('BAKERY/receipts.csv', stringsAsFactors = FALSE)

# In these tables: 
# - customers is referenced by receipts
# - receipts is referenced by goods
# - goods are referenced by items

# can't drop a table if it is referenced by another table

dbExecute(conn, 'drop table if exists items;')
dbExecute(conn, 'drop table if exists goods;')
dbExecute(conn, 'drop table if exists receipts;')
dbExecute(conn, 'drop table if exists customers;')

## --- customers ---
# create new table from customers dataset
dbWriteTable(conn, name = "customers",  value = customers)

# the column we want as a primary key must not be null, then we can add the constraint
dbExecute(conn, 'alter table customers alter column Id int not null;')
dbExecute(conn, 'alter table customers add primary key (Id);')

# check key usage in this table
dbGetQuery(conn, "select * from information_schema.key_column_usage where TABLE_NAME = 'customers';")

## --- goods ---

# create new table from goods dataset
dbWriteTable(conn, name = "goods",  value = goods)

# the column we want as a primary key must not be null, then we can add the constraint
dbExecute(conn, 'alter table goods alter column Id varchar(20) not null;')
dbExecute(conn, 'alter table goods add primary key (Id);')

# check key usage in this table
dbGetQuery(conn, "select * from information_schema.key_column_usage where TABLE_NAME = 'goods';")

## --- receipts ---

# create new table from receipts dataset
dbWriteTable(conn, name = "receipts",  value = receipts)

# the column we want as a primary key must not be null, then we can add the constraint
dbExecute(conn, 'alter table receipts alter column RecieptNumber int not null;')
dbExecute(conn, 'alter table receipts add primary key (RecieptNumber);')

dbExecute(conn, 'alter table receipts alter column CustomerID int not null;')
dbExecute(conn, 'alter table receipts add foreign key (CustomerID) references customers (Id);')

# check key usage in this table
dbGetQuery(conn, "select * from information_schema.key_column_usage where TABLE_NAME = 'receipts';")

## --- items ---

# create new table from items dataset
dbWriteTable(conn, name = "items",  value = items)

# the column we want as a primary key must not be null, then we can add the constraint
dbExecute(conn, 'alter table items alter column Reciept int not null;')
dbExecute(conn, 'alter table items alter column Ordinal int not null;')
dbExecute(conn, 'alter table items add primary key (Reciept, Ordinal);')

dbExecute(conn, 'alter table items add foreign key (Reciept) references receipts (RecieptNumber);')

dbExecute(conn, 'alter table items alter column Item varchar(20) not null;')
dbExecute(conn, 'alter table items add foreign key (Item) references goods (Id);')

# check key usage in this table
dbGetQuery(conn, "select * from information_schema.key_column_usage where TABLE_NAME = 'items';")



