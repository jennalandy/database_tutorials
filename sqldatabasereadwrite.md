---
title : Creating, Writing to, and Reading From Tables
author : Nick Padilla & Jenna Landy
options : 
    md2pdf:
        out_path :pdf
---

## Julia

## SAS

## R

Open Connection
```r
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
```

Writing
```r
# drop table from database, if it exists
dbExecute(conn, 'drop table if exists iris;')

# create new table from iris dataset
dbWriteTable(conn, name = "iris",  value = iris)

# make sure table exists in database
dbListTables(conn, table_name = "iris")

# list fields the new table
dbListFields(conn, name = "iris")
```

Reading
```r
# get full dataframe of table
data <- dbReadTable(conn, name = "iris")
head(data)

# get dataframe of a selection of the table
species <- dbGetQuery(conn, 'select distinct Species from iris')
species
```

## Python

Open Connection
```python
import pyodbc
import getpass

# NOTE: may need to adjust based on on your setup

# driver = "{ODBC Driver 17 for SQL Server}"

driver = "/usr/local/lib/libmsodbcsql.17.dylib"
# default location where file is stored on mac

# get user input -- can be replaced with raw strings if desired
database = input("Database name: ")
username = input("Username: ")
password = getpass.getpass(prompt = "Password: ")

# open connection
conn = pyodbc.connect(
    ";".join([
        "Driver="+driver,
        "Address=24.205.251.117",
        "Database="+database,
        "UID="+username,
        "PWD="+password
    ])
)

# get cursor
cursor = conn.cursor()
```

Writing to a Database
```python
# load in data
with open('iris.csv') as file:
    iris_lines = file.readlines()[1:]

# drop table if it already exists
cursor.execute("drop table if exists iris;")

# create new table
cursor.execute(" ".join([
    "create table iris(",
        "SepalLength decimal(5,2),",
        "SepalWidth decimal(5,2),",
        "PetalLength decimal(5,2),",
        "PetalWidth decimal(5,2),",
        "Species varchar(50)"
    ");"
]))

# single input: write one item to table
line = iris_lines[0].split(',')
cursor.execute(
    " ".join([
        "insert into iris(",
            "SepalLength,",
            "SepalWidth,",
            "PetalLength,",
            "PetalWidth,",
            "Species"
        ")"
        "values(?, ?, ?, ?, ?)"]),
    line[0],
    line[1],
    line[2],
    line[3],
    line[4].strip()
)

# --OR--

# bulk input: write many items to table
cursor.executemany(
    " ".join([
            "insert into iris(",
                "SepalLength,",
                "SepalWidth,",
                "PetalLength,",
                "PetalWidth,",
                "Species"
            ")"
            "values(?, ?, ?, ?, ?)"]),
    [line.split(',') for line in iris_lines[1:]]
)
```

Reading 
```python
# execute a select statement
cursor.execute("select * from iris")
iris_out = cursor.fetchall()

# output is a list of pyodbc.Row objects
print(type(iris_out[1]))

# can access by column names
print(iris_out[1].SepalLength)

# confirm it's the same as the input
print(iris_lines[1].split(',')[0])
```

## JSL