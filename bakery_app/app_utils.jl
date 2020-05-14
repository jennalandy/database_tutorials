using ODBC, DataFrames, Printf

function getcols(con, tablename)
    id= ODBC.query(con,"select object_id from sys.tables where name = '$tablename' ")[1,1] 
    res = ODBC.query(con, "select name from sys.columns where object_id = $id ")[!,1]
    return res
    
end

function addrow(con, tablename, values)
    val2=values |> String
    insertstring = "insert into $tablename values( $val2 )"
    try 
        ODBC.execute!(con,insertstring)
        return "UPLOAD SUCCESSFUL :)"
    catch 
        return "UPLOAD FAILED :("
    end 
end 

