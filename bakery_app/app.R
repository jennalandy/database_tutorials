## TODO Ideas

# Reading from Database
# X 1. Fix the lag between changing the selected table and updating selected column where
#    an error is breifly displayed
# 2. Check if any columns are datetime in SQL, make sure they're datetime in R
# 3. Add "Where" options
#    X a. range sliders for numeric values
#    X b. "like" with text input for string values
#    c. calendar picker for date values
# 4. X Join options ("where" options for values in related tables, only 1 degree of separation)

# Writing to Database
# 1. Menu selections: user chooses amount
# 2. Input customer Id (existing in database) or create new customer (writes to database)
# 3. Check-out writes to receipts and items database

# 4. Add a new item to the menu writes to goods database

library(shiny)
library(DT)
library(tidyverse)
source('app_utils.R')

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
                    checkboxInput(
                        "advanced_options", 
                        label = "Show Advanced Options"
                    ),
                    conditionalPanel(
                      "input.advanced_options",
                      radioButtons(
                        "just_bakery",
                        label = "Tables to include", 
                        choices = c("Just BAKERY","All Tables"), 
                        selected = "Just BAKERY",
                        inline = TRUE
                      ),
                      textInput(
                        "custom_query", 
                        label = "Enter your own query", 
                        placeholder = "select..."
                      )
                    ),
                    uiOutput("select_table"),
                    uiOutput("select_columns"),
                    uiOutput("wheres"),
                    uiOutput("foreign_wheres"),
                    actionButton(
                      "go",
                      label = "Show Table"
                    )
                ),
        
                mainPanel(
                    verbatimTextOutput("query"),
                    DTOutput("out")
                )
            )
        ),
        
        # Panel 2: Writing to Database
        tabPanel(
             title ="Upload to nick database",
             sidebarLayout(
                 sidebarPanel(
                    selectInput("table_name", "Select Table to Append To", ntables(conn))
                    ),

                mainPanel(
                # This outputs the dynamic UI component
                verbatimTextOutput("status"),
                uiOutput("ui"),
                actionButton("upload","Upload Data Row"))
             )
        )
    )    
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    output$choice_table <- renderPrint({ input$select_table })

    output$select_table <- renderUI({
      print(input$just_bakery)
      tables <- get_tables(input$just_bakery)
      selectInput(
        "select_table",
        label = h3("Table"),
        choices = tables
      )
    })
    
    output$select_columns <- renderUI({
        table_info <- get_table_info(input$select_table)
        column_info <- table_info$column_information

        checkboxGroupInput(
            "select_columns",
            label = h3("Column"),
            choices = column_info$names,
            selected = column_info$names
        )
    })
    
    output$choice_column <- renderPrint({ input$select_columns })
    
    output$wheres <- get_wheres(input)
    output$foreign_wheres <- get_foreign_wheres(input)
    
    output$selected <- renderPrint({
        input$select_columns
    })
    
    observeEvent(
      input$go,
      {
        output$out <- getDT(input, output)
      }
    )
        
    #writing output
    output$contents <- renderTable({
    inFile <- input$file1

    if (is.null(inFile)){
        return(NULL)
    } else {
    wrotetab=read.csv(inFile$datapath, header = input$header)
    dbWriteTable(conn=conn, name = input$table_name,  value= wrotetab)
    return(wrotetab)
    }
  })
    output$ui <- renderUI({
    # Depending on input$input_type, we'll generate a different
    # UI component and send it to the client.
        cols=getcols(conn,input$table_name)
    
        lapply(1:length(cols), function(i) {
            textInput(paste0('a', i),paste("Input Value for Column ",cols[i]))
        })
   
    })

    observeEvent(input$upload, {
        cols=getcols(con,input$table_name)
        y=NULL
        for (i in 1:length(cols)){
            y[i]= eval(parse(text=paste0('input$a',i)))
        }
        y=y%>% as.dataframe()
        sta=sqlAppendTable(con,input$table_name,y)
        output$status <- renderText({sta})
    })

}

shinyApp(ui = ui, server = server)