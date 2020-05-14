using HTTP, JSON, DataFrames, Query

urlcacurrent = "https://covidtracking.com/api/v1/states/CA/current.json"

rawdata = HTTP.get(urlcacurrent)

JSONdata = rawdata.body |> String

CACOVID = JSONdata |> JSON.parse |> DataFrame