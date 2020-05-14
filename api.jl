using HTTP, JSON, DataFrames, Query

urlcurrent = "https://covidtracking.com/api/v1/us/current.json"
HTTP.get(urlcurrent)

urlcacurrent = "https://covidtracking.com/api/v1/states/CA/current.json"




