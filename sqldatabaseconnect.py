import pyodbc
import getpass

# --- PART 1: SETUP CONNECTION  ---

# NOTE: may need to adjust based on on your setup
# driver = "{ODBC Driver 17 for SQL Server}"
driver = "/usr/local/lib/libmsodbcsql.17.dylib"

# get user input
database = input("Database name: ")
username = input("Username: ")
password = getpass.getpass(prompt = "Password: ")

# open connection
conn = pyodbc.connect(
    ";".join([
        "Driver="+driver,
        "Address=24.205.251.117",
        "Database="+database,
        "UID="+username,
        "PWD="+password
    ])
)

print("Connection Successful!")

# get cursor
cursor = conn.cursor()

# --- PART 2: WRITING AND READING USING PYTHON (without Pandas) ---

# -- 2.1 WRITING TO A DATABASE

# load in data
with open('iris.csv') as file:
    iris_lines = file.readlines()[1:]

# drop table if it already exists
cursor.execute("drop table if exists iris;")

# create new table
cursor.execute(" ".join([
    "create table iris(",
        "SepalLength decimal(5,2),",
        "SepalWidth decimal(5,2),",
        "PetalLength decimal(5,2),",
        "PetalWidth decimal(5,2),",
        "Species varchar(50)"
    ");"
]))

# write one item to table
line = iris_lines[0].split(',')
cursor.execute(
    " ".join([
        "insert into iris(",
            "SepalLength,",
            "SepalWidth,",
            "PetalLength,",
            "PetalWidth,",
            "Species"
        ")"
        "values(?, ?, ?, ?, ?)"]),
    line[0],
    line[1],
    line[2],
    line[3],
    line[4].strip()
)

# write many items to table
cursor.executemany(
    " ".join([
            "insert into iris(",
                "SepalLength,",
                "SepalWidth,",
                "PetalLength,",
                "PetalWidth,",
                "Species"
            ")"
            "values(?, ?, ?, ?, ?)"]),
    [line.split(',') for line in iris_lines[1:]]
)

# -- 2.2: READING FROM A DATABASE

# execute a select statement
cursor.execute("select * from iris")
iris_out = cursor.fetchall()

# output is a list of pyodbc.Row objects
print(type(iris_out[1]))

# can access by column names
print(iris_out[1].SepalLength)

# confirm it's the same as the input
print(iris_lines[1].split(',')[0])



# --- PART 3: WRITING AND READING USING PANDAS ---
import pandas as pd

# -- 3.1 WRITING TO A DATABASE

# drop table if it already exists
cursor.execute("drop table if exists iris;")

# create new table
cursor.execute(" ".join([
    "create table iris(",
        "SepalLength decimal(5,2),",
        "SepalWidth decimal(5,2),",
        "PetalLength decimal(5,2),",
        "PetalWidth decimal(5,2),",
        "Species varchar(50)"
    ");"
]))

# load in data
iris_df = pd.read_csv('iris.csv', )

# insert one item to table
row = iris_df.iloc[0]
cursor.execute(
    " ".join([
        "insert into iris(",
            "SepalLength,",
            "SepalWidth,",
            "PetalLength,",
            "PetalWidth,",
            "Species"
        ")"
        "values(?, ?, ?, ?, ?)"]
    ),
    row['Sepal.Length'],
    row['Sepal.Width'],
    row['Petal.Length'],
    row['Petal.Width'],
    row['Species']
)

# insert many items into table
cursor.executemany(
    " ".join([
        "insert into iris(",
        "SepalLength,",
        "SepalWidth,",
        "PetalLength,",
        "PetalWidth,",
        "Species"
        ")"
        "values(?, ?, ?, ?, ?)"]),
    [list(row) for index, row in iris_df[1:].iterrows()]
)

# -- 3.2: READING FROM A DATABASE

# returns a Pandas DataFrame
iris_df_out = pd.read_sql("select * from iris", conn)
print(type(iris_df_out))

# assert it's the same as the input DataFrame
assert(sum(iris_df_out['SepalLength']==iris_df['Sepal.Length'])/len(iris_df)==1)

# close connection
conn.close()