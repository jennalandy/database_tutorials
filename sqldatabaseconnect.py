import pyodbc
conn = pyodbc.connect("Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=ntsb;UID=ntsb;PWD=Cessna182;")
cursor = conn.cursor()
cursor.execute("select * from events" )
dat =cursor.fetchall()
conn.close()
