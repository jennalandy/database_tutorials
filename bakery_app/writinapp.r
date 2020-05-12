library(shiny)
library(JuliaCall)
library(tidyverse)

julia_install_package_if_needed("ODBC")
julia_install_package_if_needed("DataFrames")
julia_library("ODBC")
julia_library("DataFrames")
#source helpers
setwd("/home/datguy/Documents/stat440/bakery_app")
julia_source("app_utils.jl")


dsn =julia_eval('
 ODBC.DSN("Driver={ODBC Driver 17 for SQL Server};Address=24.205.251.117;Database=NickDb;UID=Nick;PWD=WaveTrack3@;")
')

ui <- fluidPage(
  titlePanel("Upload to nick database"),
  sidebarLayout(
    sidebarPanel(
      selectInput("table_name", "Select Table to Append To", 
      julia_call("ODBC.query",dsn,"select name from sys.tables"))
    ),

    mainPanel(
      # This outputs the dynamic UI component
      verbatimTextOutput("status"),
      uiOutput("ui"),
      actionButton("upload","Upload Data Row")
    )
  )
)
server <- function(input, output,session) {

  output$ui <- renderUI({
    # Depending on input$input_type, we'll generate a different
    # UI component and send it to the client.
    cols=julia_call("getcols",dsn,input$table_name)
    
    lapply(1:length(cols), function(i) {
        textInput(paste0('a', i),paste("Input Value for Column ",cols[i]))
    })
   
  })

observeEvent(input$upload, {
    cols=julia_call("getcols",dsn,input$table_name)
    y=NULL

    for (i in 1:length(cols)){
        y[i]= eval(parse(text=paste0('input$a',i)))
    }
    y=paste(y,collapse=",")
      print(y)
      sta=julia_call("addrow", dsn, input$table_name, y)
    output$status <- renderText({sta})
  })
}
      

shinyApp(ui = ui, server = server)

julia_eval("ODBC.disconnect!(dsn)")

