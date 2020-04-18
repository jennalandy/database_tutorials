using DataFrames,Query, JuliaDB

#driver/connection string found at
# https://docs.microsoft.com/en-us/sql/connect/odbc/microsoft-odbc-driver-for-sql-server?view=sql-server-ver15

#enter user information to be passed into the connection string
database= begin 
    print("Enter Database Name: ")
    readline()
end 

dsn=ODBC.DSN("Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=ntsb;UID=ntsb;PWD=Cessna182;")
df=ODBC.query(dsn,"select TOP 50 * from events") |>table

x = @from i in df begin 
    @select {date =i.ev_date, type= i.ev_type, time= i.ev_time}
    @collect table
end 

y = @from i in x begin
    @where i.time < 100
    @select i.date, i.type 
    @collect table
end

ODBC.disconnect!(dsn)
