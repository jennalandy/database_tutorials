library(odbc)
library(DBI)

conn <- dbConnect(
  odbc(),
  Driver = "ODBC Driver 17 for SQL Server",
  Server = "24.205.251.117",
  Database = "JennaDb", #rstudioapi::showPrompt("Database name","Database name"),
  UID = "Jenna", #rstudioapi::showPrompt("Database username", "Database username"),
  PWD = "ShadeHome8$" #rstudioapi::askForPassword("Database password")
)

get_tables <- function() {
  values = dbListTables(conn)[
    grepl('BAKERY', dbListTables(conn))
  ]
  names = str_replace(values, 'BAKERY_', '')
  tables = as.list(setNames(values, names))
  tables
}

get_columns <- function(table) {
  table_information <- dbGetQuery(
    conn, paste("sp_columns", table)
  )
  names = table_information[['COLUMN_NAME']]
  types = table_information[['TYPE_NAME']]
  
  out <- data.frame(list(
    'names' = names,
    'types' = types
  ))
  
  out$minimum = NA
  out$maximum = NA
  
  for (i in 1:nrow(out)) {
    if (out$types[i] %in% c('int','float')) {
      col_name <- out$names[i]
      
      min_query <- paste(
        "select min(",col_name,") from", 
        table
      )
      
      minimum = dbGetQuery(conn, min_query) %>% as.numeric() %>% floor()
      out[i, 'minimum'] = minimum
      
      max_query <- paste(
        "select max(",col_name,") from", 
        table
      )
      
      maximum = dbGetQuery(conn, max_query) %>% as.numeric() %>% ceiling()
      out[i, 'maximum'] = maximum
    }
  }
  out
}


get_wheres <- function(input) {
  renderUI({
    column_info <- get_columns(input$select_table)
    get_where <- function(i) {
      col_name <- input$select_columns[i]
      col_type <- column_info[column_info$names == col_name,]$types
      output_name <- paste('where_', col_name, sep = '')
      
      if (col_type %in% c('int', 'float')) {
        # slider
        
        minimum <- column_info[column_info$names == col_name,]$minimum
        maximum <- column_info[column_info$names == col_name,]$maximum
        
        if (!is.null(input[[output_name]])) {
          low = input[[output_name]][1]
          high = input[[output_name]][2]
        } else {
          low = minimum
          high = maximum
        }
        
        sliderInput(
          output_name,
          label = col_name,
          min = minimum, 
          max = maximum,
          value = c(low, high)
        )
      } else {
        print(col_type)
      }
    }
    
    if (length(input$select_columns) > 0){
      lapply(1:length(input$select_columns), get_where)
    }
  })
}

getDT <- function(input, output) {
  renderDT({
    column_info <- get_columns(input$select_table) %>% data.frame()
    
    # build "where" clause
    where <- ""
    for (i in 1:nrow(column_info)) {
      col_name = column_info$names[i] %>% as.character()
      if (!(col_name %in% input$select_columns)) {
        next
      }
      
      col_type = column_info$types[i]
      col_where <- input[[paste('where_', col_name, sep = '')]]
      
      if (!is.null(col_where)) {
        
        if (col_type %in% c('int','float')) {
          # slider
          minimum <- column_info$minimum[i]
          maximum <- column_info$maximum[i]
          
          if (col_where[1]!= minimum | col_where[2]!=maximum) {
            if (where != '') {
              where <- paste(where, 'and')
            }
            where <- paste(
              where,
              col_name, ">=", 
              col_where[1], "and", col_name, "<=",
              col_where[2]
            )
          }
        }
      }
    }
    
    if(length(input$select_columns) > 0) {
      query <- paste(
        "select", paste(input$select_columns,collapse = ', '), 
        "from", input$select_table,
        ifelse(where != "", paste("where", where), "")
      )
      output$query = renderText({query})
      return(
        dbGetQuery(
          conn,
          query
        ) %>% data.frame()
      )
    } else {
      return(
        data.frame()
      )
    }
    
  })
}








