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
#================================================= Reading Data ==============================================================#

# setting up database  
dsn = ODBC.DSN("Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=$database;UID=$user;PWD=$pass;")

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
DataFrame 


######################## Writing Data that fits in memory  using Tables.jl data sinks ##################################################
#=
get the grid datasets from Cal Poly, convert from sas7bdat to IndexedTable 
we'll be using the Indexed table as the datasink as it works well with larger datasets
but the choice is arbitray in this case and can be a Julia DataFrame, dict or some Tables.jl implementation
=#
customers = loadtable("BAKERY/customers.csv")
reciepts = loadtable("BAKERY/receipts.csv")
items = loadtable("BAKERY/items.csv")
goods = loadtable("BAKERY/goods.csv")



gridprojects = download("https://web.calpoly.edu/~rottesen/Stat441/Sasdata/Sasdata/projects.sas7bdat") |> 
                readsas |> 
                table


ODBC.execute!(dsn,
"""
drop table if exists goods; 
drop table if exists items;
drop table if exists reciepts;
drop table if exists customers;
drop table if exists iris;
drop table if exists iris2;
""")

#writing data

#= 
depending on your ODBC driver, you could do something as simple as

ODBC.load(database, "name of sql table", julia_table)

some ODBC drivers/database systems don't support this however, including MS SQL Server
so we must use an alternative method
=#


## create the tables
ODBC.execute!(dsn,"""
create table customers
(Id int Primary Key, LastName VARCHAR(30), FirstName VARCHAR(30))
""")

ODBC.execute!(dsn,
"create table goods
(Id VARCHAR(30) Primary Key, Flavor VARCHAR(30), Food VARCHAR(30), Price FLOAT)")

ODBC.execute!(dsn,"""
create table reciepts
(RecieptNumber int PRIMARY KEY, Date VARCHAR(30), CustomerId int, CONSTRAINT CustomerID FOREIGN KEY (CustomerId) references customers(Id) )
""")

ODBC.execute!(dsn,
"create table items
(Reciept INT, Ordinal INT, Item VARCHAR(30),  PRIMARY KEY (Reciept,Ordinal), CONSTRAINT RecieptNumber FOREIGN KEY (Reciept) REFERENCES reciepts (RecieptNumber) 
, CONSTRAINT ItemId FOREIGN KEY(Item) References goods (Id) )
")


## make a sql statement with "blank" values that we'll put in actual values into 
insertstmt=ODBC.prepare(dsn,"insert into customers values(?,?,?)")

## now for each row in the rows of gridprojects, run the previous insert statemet, with the values for each row 
## inserted into the previous "blank rows" ie those question marks

for row in rows(customers)
    ODBC.execute!(insertstmt,row)
end

## Now do this for the remaining three tables
insertstmt=ODBC.prepare(dsn,"insert into goods values(?,?,?,?)")
for row in rows(goods)
    ODBC.execute!(insertstmt,row)
end

insertstmt=ODBC.prepare(dsn,"insert into reciepts values(?,?,?)")
for row in rows(reciepts)
    ODBC.execute!(insertstmt,row)
end


insertstmt=ODBC.prepare(dsn,"insert into items values(?,?,?)")
for row in rows(items)
    ODBC.execute!(insertstmt,row)
end

# select top 50 rows from sample table, select as a julia DB indexed table. 
results=ODBC.Query(dsn,"select TOP 5 * from items") |> 
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
#========================================== Linking Datasets ====================================#
   
ODBC.disconnect!(dsn)
