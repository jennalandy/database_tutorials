using Query, JuliaDB, SASLib, ODBC 

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

pass= begin 
    print("Enter Password: ")
    readline()
end 

######################## Data that fits in memory and using Tables.jl data sinks ##################################################
#get the grid datasets from Cal Poly, convert from sas7bdat to IndexedTable 
#we'll be using the Indexed table as the datasink as it works well with larger datasets
#but the choice is arbitray in this case and can be a dataframe, dict or some Tables.jl implementation

gridusers = download("https://web.calpoly.edu/~rottesen/Stat441/Sasdata/Sasdata/users.sas7bdat") |> 
            readsas |> 
            table

gridprojects = download("https://web.calpoly.edu/~rottesen/Stat441/Sasdata/Sasdata/projects.sas7bdat") |> 
                readsas |> 
                table

# setting up database  
dsn = ODBC.DSN("Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=$database;UID=$user;PWD=$pass;")

ODBC.execute!(dsn,"drop table if exists users; 
drop table if exists projects")

#writing projects data

## create the tables
ODBC.execute!(dsn,"create table projects 
(Class VARCHAR(10), id INT, StartDate INT, EndDate INT)")

ODBC.execute!(dsn,
"create table users 
(Class VARCHAR(10), Fname VARCHAR(16), Lname VARCHAR(16), Email VARCHAR(24), Phone VARCHAR(9), Dept VARCHAR(5), id INT) ")

## make a sql statement with "blank" values that we'll put in actual values into 
insertstmt=ODBC.prepare(dsn,"insert into projects values(?,?,?,?)")

## now for each row in the rows of gridprojects, run the previous insert statemet, with the values for each row 
## inserted into the previous "blank rows" ie those question marks

for row in rows(gridprojects)
    ODBC.execute!(insertstmt,row)
end

## make a sql statement with "blank" values that we'll put in actual values into 
insertstmt=ODBC.prepare(dsn,"insert into projects values(?,?,?,?,?,?,?)")

## now for each row in the rows of gridusers, run the previous insert statemet, with the values for each row 
## inserted into the previous "blank rows" ie those question marks
for row in rows(gridusers)
    ODBC.execute!(insertstmt,row)
end


# select top 50 rows from sample table, select as a julia DB indexed table. 
results=ODBC.query(dsn,"select TOP 50 * from projects") |> 
        table

ODBC.disconnect!(dsn)

