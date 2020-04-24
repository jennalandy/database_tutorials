import pyodbc
import getpass
import calendar
month_abbr_dict = {v: k for k,v in enumerate(calendar.month_abbr)}


# --- PART 1: SETUP CONNECTION  ---

# NOTE: may need to adjust based on on your setup
# driver = "{ODBC Driver 17 for SQL Server}"

driver = "/usr/local/lib/libmsodbcsql.17.dylib"
# default location where file is stored on mac

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

# -- 2.1.1 Simple Table: Iris

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

# -- 2.1.2 Related Tables Connected by Keys: Bakery

# drop tables if they already exists
# can't drop a table if it is referenced by another table
cursor.execute("drop table if exists items;")
cursor.execute("drop table if exists goods;") # referenced by items
cursor.execute("drop table if exists receipts;") # referenced by items
cursor.execute("drop table if exists customers;") # referenced by receipts

# create new tables
cursor.execute(" ".join([
    "create table customers(",
        "Id int,",
        "LastName varchar(50),",
        "FirstName varchar(50),",
        "constraint customers_pk primary key (Id)"
    ");"
]))

cursor.execute(" ".join([
    "create table receipts(",
        "ReceiptNumber int,",
        "Date date,",
        "CustomerId int,",
        "constraint receipts_pk primary key (ReceiptNumber),",
        "constraint receipts_customers_fk foreign key (CustomerId) references customers (Id)"
    ");"
]))

cursor.execute(" ".join([
    "create table goods(",
        "Id varchar(50),",
        "Flavor varchar(50),",
        "Food varchar(50),",
        "Price decimal(5,2),",
        "constraint goods_pk primary key (Id)"
    ");"
]))

cursor.execute(" ".join([
    "create table items(",
        "Receipt int,",
        "Ordinal int,",
        "Item varchar(50),",
        "constraint items_pk primary key (Receipt, Ordinal),",
        "constraint items_goods_fk foreign key (Item) references goods (Id),",
        "constraint items_receipts_fk foreign key (Receipt) references receipts (ReceiptNumber)"
    ");"
]))

# load in data
with open('BAKERY/customers.csv') as file:
    header = True
    # iterating through lines in this way doesn't read everything to memory at once
    # useful strategy for large files!
    for line in file:
        line = line.split(', ')
        if header:
            header = False
        else:
            cursor.execute(
                " ".join([
                    "insert into customers(",
                        "Id,",
                        "FirstName,",
                        "LastName",
                    ")"
                    "values(?, ?, ?)"]),
                line[0],
                line[1],
                line[2].strip()
            )

# load in data
with open('BAKERY/receipts.csv') as file:
    header = True
    for line in file:
        line = line.split(', ')
        if header:
            header = False
        else:
            # YYYYMMDD from DD-Mon-YYYY
            date = line[1].strip().replace("'",'')
            year = date.split('-')[2]
            day = date.split('-')[0]
            if len(day) == 1:
                day = '0'+day
            month = str(month_abbr_dict[date.split('-')[1]])
            date2 = year+month+day
            cursor.execute(
                " ".join([
                    "insert into receipts(",
                        "ReceiptNumber,",
                        "Date,",
                        "CustomerId",
                    ")"
                    "values(?, ?, ?)"]),
                line[0],
                date2,
                line[2].strip()
            )

# load in data
with open('BAKERY/goods.csv') as file:
    header = True
    # iterating through lines in this way doesn't read everything to memory at once
    # useful strategy for large files!
    for line in file:
        line = line.strip().split(',')
        if header:
            header = False
        else:
            cursor.execute(
                " ".join([
                    "insert into goods(",
                        "Id,",
                        "Flavor,",
                        "Food,",
                        "Price"
                    ")"
                    "values(?, ?, ?, ?)"]),
                line[0],
                line[1],
                line[2],
                float(line[3])
            )

# load in data
with open('BAKERY/items.csv') as file:
    header = True
    # iterating through lines in this way doesn't read everything to memory at once
    # useful strategy for large files!
    for line in file:
        line = line.split(', ')
        if header:
            header = False
        else:
            cursor.execute(
                " ".join([
                    "insert into items(",
                        "Receipt,",
                        "Ordinal,",
                        "Item",
                    ")"
                    "values(?, ?, ?)"]),
                int(line[0]),
                int(line[1]),
                line[2].strip()
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
