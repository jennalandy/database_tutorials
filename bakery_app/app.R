## TODO Ideas

# Reading from Database
# 1. Fix the lag between changing the selected table and updating selected column where
#    an error is breifly displayed
# 2. Check if any columns are datetime in SQL, make sure they're datetime in R
# 3. Add "Where" options
#    DONE a. range sliders for numeric values
#    b. "like" with text input for string values
#    c. calendar picker for date values
# 4. Join options??
# 5. Alternate option to have user input a raw SQL query

# Writing to Database
# 1. Menu selections: user chooses amount
# 2. Input customer Id (existing in database) or create new customer (writes to database)
# 3. Check-out writes to receipts and items database
# 4. Add a new item to the menu writes to goods database

library(shiny)
library(DT)
library(tidyverse)

source('app_utils.R')

tables <- get_tables()

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("BAKERY"),

    # Sidebar with a slider input for number of bins 
    tabsetPanel(
        
        # Panel 1: Reading from Database
        tabPanel(
            title = "Reading from Database",
            sidebarLayout(
                sidebarPanel(
                    selectInput(
                        "select_table",
                        label = h3("Table"),
                        choices = tables
                    ),
                    uiOutput("select_columns"),
                    uiOutput("wheres")
                ),
        
                mainPanel(
                    verbatimTextOutput("query"),
                    DTOutput("out")
                )
            )
        ),
        
        # Panel 2: Writing to Database
        tabPanel(
            title = "Writing to Database",
             sidebarLayout(
                sidebarPanel(
                    textInput("table_name","Enter File Name", value="Unnnamed File"),    
                    fileInput("file1", "Choose CSV File",
                         accept = c(
                                "text/csv",
                                "text/comma-separated-values,text/plain",
                                ".csv")
                            ),
                            tags$hr(),
                    checkboxInput("header", "Header", TRUE)
                ),
                mainPanel(
                    tableOutput("contents")
                )
            )
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    output$choice_table <- renderPrint({ input$select_table })
    
    
    output$select_columns <- renderUI({
        column_info <- get_columns(input$select_table)
        print(column_info)
        
        checkboxGroupInput(
            "select_columns",
            label = h3("Column"),
            choices = column_info$names,
            selected = column_info$names[1]
        )
    })
    
    output$choice_column <- renderPrint({ input$select_columns })
    
    output$wheres <- get_wheres(input)
    
    output$selected <- renderPrint({
        input$select_columns
    })
    
    output$out <- getDT(input, output)
        
        
    #writing output
    output$contents <- renderTable({
    inFile <- input$file1

    if (is.null(inFile)){
        return(NULL)
    } else {
    wrotetab=read.csv(inFile$datapath, header = input$header)
    dbWriteTable(conn, name = input$table_name,  value= wrotetab)
    return(wrotetab)
    }
  })
}

shinyApp(ui = ui, server = server)