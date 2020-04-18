/*from proc sql directly*/
/*this is pretty convoluted*/
proc sql;
connect to odbc as conn
required="Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=ntsb;UID=ntsb;PWD=Cessna182";

create table event as
select * from connection to conn
(select * from events) ;

disconnect from conn;
quit;

/*by using a libname*/
libname conn2 odbc
required ="Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=ntsb;UID=ntsb;PWD=Cessna182";
proc sql;
create table event as
select * from conn2.events ;
quit;
