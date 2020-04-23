---
title : Creating, Writing to, and Reading From Tables
author : Nick Padilla & Jenna Landy
options : 
    md2pdf:
        out_path :pdf
---

## Julia
Open Connection
```julia
using Query, JuliaDB, SASLib, ODBC, CSV

# driver/connection string found at
# https://docs.microsoft.com/en-us/sql/connect/odbc/microsoft-odbc-driver-for-sql-server?view=sql-server-ver15

#enter user information to be passed into the connection string
database= begin 
    print("Enter Database Name: ")
    readline()
end 

user= begin 
    print("Enter Username: ")
    readline() 
end 

crypt=Base.getpass("Enter Password")
pass=read(crypt,String)


# setting up database  
dsn = ODBC.DSN("Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=$database;UID=$user;PWD=$pass;")

```
Reading 
```julia
#Query and filter using database sql commands, when using lower case "query" returns a dataframe, as opposed to uppercase "Query"

res=ODBC.query(dsn,"""

select cyl, drat 
from mtcars 
where disp > 200

""") 

#Query database to select all rows in mtcars, then filter/select rows in julia

##LINQ style

res=@from i in ODBC.Query(dsn,"select * from mtcars") begin 
    @where i.disp > 200
    @select {Cylinder=i.cyl, Drat=i.drat}
    @collect table 
end 

## dyplr/tidyverse style 

res = ODBC.query(dsn,"select * from mtcars") |> 
@filter( _.disp > 200) |>
@select( :cyl, :drat) |>
table 
```
Writing 
```julia
#= 
depending on your ODBC driver, you could do something as simple as

ODBC.load(database, "name of sql table", julia_table)

some ODBC drivers/database systems don't support this however, including MS SQL Server
so we must use an alternative method
=#

## create the tables
ODBC.execute!(dsn,"""
create table projects 
(Class VARCHAR(10), id INT, StartDate INT, EndDate INT)
""")

ODBC.execute!(dsn,
"create table users 
(Class VARCHAR(10), Fname VARCHAR(16), Lname VARCHAR(16), Email VARCHAR(36), Phone VARCHAR(9), Dept VARCHAR(10), id INT) ")

## make a sql statement with "blank" values that we'll put in actual values into 
insertstmt=ODBC.prepare(dsn,"insert into projects values(?,?,?,?)")

## now for each row in the rows of gridprojects, run the previous insert statemet, with the values for each row 
## inserted into the previous "blank rows" ie those question marks

for row in rows(gridprojects)
    ODBC.execute!(insertstmt,row)
end

## make a sql statement with "blank" values that we'll put in actual values into 
insertstmt=ODBC.prepare(dsn,"insert into users values(?,?,?,?,?,?,?)")

## now for each row in the rows of gridusers, run the previous insert statemet, with the values for each row 
## inserted into the previous "blank rows" ie those question marks
for row in rows(gridusers)
    ODBC.execute!(insertstmt,row)
end

# select top 50 rows from sample table, select as a julia DB indexed table. 
results=ODBC.query(dsn,"select TOP 50 * from projects") |> 
        table



#==============================  Loading Data Bigger than Memory =========================================================#
# ok so this isn't actually larger than memory, but it should work for any delimited text file of arbitray size

ODBC.execute!(dsn,""""
create table iris 
(Sepal_length Float, Sepal_width Float, Petal_length FLOAT, Petal_width FLOAT, Species VARCHAR(20) )
""")

insertstmt=ODBC.prepare(dsn,"insert into iris values(?,?,?,?,?)")

#================================== Utilizing the CSV package (more optimized)============================================# 

for row in CSV.Rows("iris.csv",skipto=2 )
    ODBC.execute!(insertstmt,row)
end 

#================================== In base Julia (less optimized)=========================================================#

ODBC.execute!(dsn,"""
create table iris2 
(Sepal_length Float, Sepal_width Float, Petal_length FLOAT, Petal_width FLOAT, Species VARCHAR(20) )
""")

insertstmt=ODBC.prepare(dsn,"insert into iris values(?,?,?,?,?)")

## open the file
open("iris.csv") do f
  #put this readline in if you'd like to skip the first row
    readline(f)
    #for the remaining lines, read in as a single string, break apart at the commas, then insert the rest
   for lines in readlines(f)
    rawline=map(String,split(lines, ","))
    ODBC.execute!(insertstmt,rawline)
   end 
end



#========================================Bulk Insert ======================================================================#
#=
If you have bulk insert permissions you can do something like below to write data without reading it into memory
Note, this is not tested, since I do not have bulk load permissions, so use at own risk
more info can be found at 

https://docs.microsoft.com/en-us/sql/relational-databases/import-export/import-bulk-data-by-using-bulk-insert-or-openrowset-bulk-sql-server?view=sql-server-ver15#bulk-insert-statement
=#

#=
ODBC.execute!(dsn,"""
BULK INSERT iris
FROM 'iris.csv'
""")

ODBC.execute!(dsn, 
"""
INSERT INTO iris (Sepal_length, Sepal_width, Petal_length, Petal_width, Species)
SELECT *  
FROM OPENROWSET (  
    BULK 'iris.csv') AS b ;
""")
=#
ODBC.disconnect!(dsn)
```
## SAS
Open Connection
```sas
/*Window Prompt Courtesy of SAS Documentation */
/** This code is for the SAS windowing environment only. **/

/** %WINDOW defines the prompt **/
%window info
  #5 @5 'Please enter userid:'
  #5 @26 id 8 attr=underline
  #7 @5 'Please enter password:'
  #7 @28 pass 8 attr=underline display=no;

/** %DISPLAY invokes the prompt **/
%display info;

/*from proc sql directly*/
/*this is pretty convoluted*/
proc sql;
connect to odbc as conn
required="Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=NickDb;UID=&id;PWD=&pass";
disconnect from conn;
quit;

/*by using a libname, much more straightforward*/
libname conn2 odbc
required ="Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=NickDb;UID=&id;PWD=&pass";

```
Reading
```sas
/*from proc sql directly*/
/*this is pretty convoluted*/
proc sql;
connect to odbc as conn
required="Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=NickDb;UID=&id;PWD=&pass";

create table event as
select * from connection to conn
(select * from events) ;

disconnect from conn;
quit;

/*read data into work directory*/
proc sql;
create table event as
select * from conn2.events ;
quit;
libname conn2 clear;

```
Writing
```sas
/*writing data from work directory to database*/
filename download url "https://raw.githubusercontent.com/uiuc-cse/data-fa14/gh-pages/data/iris.csv";

data iris;
infile download delimiter = "," firstobs=2;
input var1-var4 species $;
run;


/*using the libname option again, turn on the bulkload for improved performance when loading large datasets */
/*since sas doesn't load everything into memory we can directly put sas datasets into the database! */
libname conn2 odbc
required ="Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=NickDb;UID=&id;PWD=&pass"
bulkload = YES;

proc sql;
create table conn3.iris as 
(select * from work.iris);
quit;

```
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

* I still need to test this - Nick 

Open Connection
```
conn = opendatabaseconnection(
	    "Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=ntsb;UID=ntsb;PWD=Cessna182")

```
Read Data 
```
res = executesql(conn,
    "select * from mtcars"
)
```
Write data
```
#need to import csv
res2 = executesql(conn,
    "create table iris (var1 float, var2 float, var3 float, var4 float, var6 varchar") 
)
#fake data, will figure out how to write real data
executesql("insert into iris values (1,2,3,4,"fakespecies")")
```