/*define a temporary file to read the JSON data into*/
filename raw_json temp;

/*use proc http to make the API call*/
proc http
url = "https://covidtracking.com/api/v1/us/current.json"
method = "GET"
out = raw_json

/*this api uses the path segement of the url to specify parameters*/
/*but if  you are using an an api that utilizes a query string use */
/*the query option as listed below, or append it directly to the url*/
/*if doing the latter, check the api documentation to see what delimiter is */
/*used between parameters. Parameters are typically specified in parm=val form*/

/*QUERY=("parm1" = "val1" "parm2" = "val2")*/

;
quit;

/*use the libname statement to convert the json file to a sas table*/
libname Calif JSON fileref = raw_json;

proc print data = Calif.alldata ; run;
