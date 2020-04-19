using DataFrames, Query, JuliaDB

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

# setting up database  
dsn=ODBC.DSN("Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=$databse;UID=$user;PWD=$pass;")

# select top 50 rows from sample table, select as a julia DB indexed table. 
results=ODBC.query(dsn,"select TOP 50 * from events") |> table

#writing data


ODBC.disconnect!(dsn)
