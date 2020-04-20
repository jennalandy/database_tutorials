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

create table event as
select * from connection to conn
(select * from events) ;

disconnect from conn;
quit;

/*by using a libname, much more straightforward*/
libname conn2 odbc
required ="Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=NickDb;UID=&id;PWD=&pass";

/*read data into work directory*/
proc sql;
create table event as
select * from conn2.events ;
quit;

/*writing data from work directory to database*/
filename download url "https://raw.githubusercontent.com/uiuc-cse/data-fa14/gh-pages/data/iris.csv";

data iris;
infile download delimiter = "," firstobs=2;
input var1-var4 species $;
run;

proc sql;
create table conn2.iris as 
(select * from iris);
quit;
