library(odbc)
library(DBI)
library(DT)
library(tidyverse)

make_connection <- function(server, db, uid, pwd) {
  conn <- dbConnect(
    odbc(),
    Driver = "ODBC Driver 17 for SQL Server",
    Server = server,
    Database = db,
    UID = uid,
    PWD = pwd
  )
  return(conn)
}

get_tables <- function(just_bakery) {
  if (exists('conn')) {
    print(just_bakery)
    all_tables <- dbGetQuery(
      conn, 'select TABLE_NAME from INFORMATION_SCHEMA.TABLES'
    ) %>% unlist() %>% unname()
    
    all_tables <- all_tables[!grepl("\\s", all_tables)]
    print(all_tables)
    
    if (is.null(just_bakery) | just_bakery == "Just BAKERY") {
      values = all_tables[grepl('BAKERY', all_tables)]
      names = str_replace(values, 'BAKERY_', '')
    } else {
      values = all_tables
      names = values
    }
    tables = as.list(setNames(values, names))
    return(tables)
  }
}

get_table_info <- function(table) {
  
  if (exists(paste(table,"_info",sep = ''))) {
    return(
      eval(parse(text = paste(table,"_info",sep = '')))
    ) 
  }
  
  # get column names and types
  table_information <- dbGetQuery(
    conn, paste("sp_columns", table)
  )
  names = table_information[['COLUMN_NAME']]
  types = table_information[['TYPE_NAME']]
  
  table_info <- data.frame(list(
    'names' = names,
    'types' = types
  ))
  
  # get minimum and maximum for numeric columns
  table_info$minimum = NA
  table_info$maximum = NA
  
  for (i in 1:nrow(table_info)) {
    if (table_info$types[i] %in% c('int','float')) {
      col_name <- table_info$names[i]
      
      min_query <- paste(
        "select min(",col_name,") from", 
        table
      )
      
      minimum = dbGetQuery(conn, min_query) %>% as.numeric() %>% floor()
      table_info[i, 'minimum'] = minimum
      
      max_query <- paste(
        "select max(",col_name,") from", 
        table
      )
      
      maximum = dbGetQuery(conn, max_query) %>% as.numeric() %>% ceiling()
      table_info[i, 'maximum'] = maximum
    }
  }
      
  # get table relationships
  table_ids <- dbGetQuery(conn, "select *  from sys.tables;") %>%
    select(name, object_id)
  table_id <- table_ids %>%
    filter(name == table) %>%
    pull(object_id)
  
  foreign_keys <- dbGetQuery(conn, "select *  from sys.foreign_key_columns;") %>%
    select(
      parent_object_id, parent_column_id, 
      referenced_object_id, referenced_column_id
    ) %>%
    filter(
      parent_object_id == table_id
    ) %>%
    merge(
      table_ids,
      by.x = 'referenced_object_id',
      by.y = 'object_id', 
      all.x = TRUE
    )
  names(foreign_keys)[names(foreign_keys) == 'name'] <- 'referenced_table'
  foreign_keys <- foreign_keys %>% merge(
    table_info %>%
        mutate(parent_column_id = 1:nrow(table_info)) %>%
        select(parent_column_id, names),
      by = 'parent_column_id'
    )
  names(foreign_keys)[names(foreign_keys) == 'names'] <- 'parent_column_name'
  
  if (nrow(foreign_keys) > 0) {
    foreign_keys$foreign_column_names <- rep(NA, nrow(foreign_keys))
    for (i in 1:nrow(foreign_keys)) {
      foreing_column_name <- dbGetQuery(
        conn, paste("sp_columns", foreign_keys$referenced_table[i])
      ) %>%
        filter(ORDINAL_POSITION == foreign_keys$referenced_column_id[i]) %>%
        select(COLUMN_NAME)
      foreign_keys$foreign_column_names[i] <- foreing_column_name
    }
  } else {
    foreign_keys = NULL
  }
  
  out <- list(
    'column_information' = table_info,
    'foreign_keys' = foreign_keys
  )
  
  assign(paste(table,"_info",sep = ''), out, envir = .GlobalEnv)
  out
}

get_wheres <- function(input) {
  renderUI({
    table_info <- get_table_info(input$select_table)
    column_info <- table_info$column_information

    get_where <- function(i) {
      col_name <- column_info$names[i]
      full_col_name <- paste(input$select_table, col_name, sep = ".")
      col_type <- column_info$types[i]
      output_name <- paste('where_', input$select_table,'_', full_col_name, sep = '')

      if (col_type %in% c('int', 'float')) {
        minimum <- column_info[column_info$names == col_name,]$minimum
        maximum <- column_info[column_info$names == col_name,]$maximum
        
        sliderInput(
          output_name,
          label = col_name,
          min = minimum, 
          max = maximum,
          value = c(minimum, maximum)
        )
      } else if (col_type == 'varchar') {
        placeholder <- "is like..."
        textInput(
          output_name,
          label = col_name,
          placeholder = placeholder
        )
      }
    }
    
    if (nrow(column_info) > 0){
      lapply(1:nrow(column_info), get_where)
    }
  })
}

get_foreign_wheres <- function(input) {
  get_foreign_where <- function(j, foreign_column_info, foreign_table_name, skip) {
    col_name <- foreign_column_info$names[j]
    full_col_name <- paste(foreign_table_name, col_name, sep = ".")
    col_type <- foreign_column_info$types[j] %>% as.character()
    output_name <- paste('where_', input$select_table, '_', full_col_name, sep = '')

    if ((col_type %in% c('int', 'float')) & !(col_name %in% skip)) {
      minimum <- foreign_column_info[foreign_column_info$names == col_name,]$minimum
      maximum <- foreign_column_info[foreign_column_info$names == col_name,]$maximum
      
      sliderInput(
        output_name,
        label = col_name,
        min = minimum, 
        max = maximum,
        value = c(minimum, maximum)
      )
      
    } else if ((col_type == 'varchar') & !(col_name %in% skip)) {
      placeholder <- "is like..."
      textInput(
        output_name,
        label = col_name,
        placeholder = placeholder
      )
    }
  }
  
  renderUI({
    table_info <- get_table_info(input$select_table)
    foreign_keys <- table_info$foreign_keys
    
    if (length(foreign_keys) > 0){
      ui_items <- c()
      for (i in 1:nrow(foreign_keys)) {
        foreign_table_name <- foreign_keys$referenced_table[i]
        col_to_skip <- foreign_keys$foreign_column_names[i]
        foreign_table_info <- get_table_info(foreign_table_name)
        foreign_column_info <- foreign_table_info$column_information
        
        ui_items <- c(
          ui_items,
          titlePanel(h3(
            paste(
              "Columns in",
              str_remove(foreign_table_name,'BAKERY_')
            )
          )),
          lapply(
            1:nrow(foreign_column_info), 
            get_foreign_where,
            foreign_column_info = foreign_column_info,
            foreign_table_name = foreign_table_name,
            skip = c(col_to_skip)
          )
        )
      }
      return(verticalLayout(ui_items))
    }
  })
}

get_query_where <- function(input, foreign_keys, col_wheres) {
  table_info <- get_table_info(input$select_table) 
  column_info <- table_info$column_information %>% data.frame()
  foreign_keys <- table_info$foreign_keys

  col_wheres <- list()
  for(col_name in column_info$names) {
    full_col_name <- paste(input$select_table, col_name, sep = ".")
    col_type <- column_info$types[column_info$names == col_name] %>% as.character()
    col_wheres[[full_col_name]] <- input[[paste('where_', input$select_table, '_', full_col_name, sep = '')]]
  }
  
  where <- ""
  
  for (col_name in names(col_wheres)) {
    i <- which(names(col_wheres) == col_name)
    col_where = col_wheres[[col_name]]

    regular_col_name = str_split(col_name, '\\.')[[1]][2]
    table_name = str_split(col_name, '\\.')[[1]][1]
    
    where_column_info <- get_table_info(table_name)$column_information
    col_type = where_column_info$types[
      where_column_info$names==regular_col_name
      ] %>% as.character()
    
    if (!is.null(col_where)) {
      
      if (col_type %in% c('int','float')) {
        minimum <- where_column_info$minimum[
          where_column_info$names==regular_col_name
          ] %>% as.numeric()
        maximum <- where_column_info$maximum[
          where_column_info$names==regular_col_name
          ] %>% as.numeric()
        
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
      } else if (col_type == 'varchar') {
        if (col_where != '') {
          if (where != '') {
            where <- paste(where, 'and')
          }
          where <- paste(
            where, ' ',
            col_name, ' like ',
            "'%", toupper(col_where), "%'",
            sep = ''
          )
        }
      }
    }
  }
    
  if (!is.null(foreign_keys)) {
    for(i in 1:nrow(foreign_keys)) {
      foreign_table <- foreign_keys$referenced_table[i] %>% as.character()
      
      foreign_table_info <- get_table_info(foreign_table)
      foreign_table_cols <- foreign_table_info$column_info
      
      parent_column_name <- foreign_keys$parent_column_name[i] %>% as.character()
      foreign_column_name <- foreign_keys$foreign_column_names[i] %>% as.character()
      
      for (col_name in foreign_table_cols$names) {
        full_col_name <- paste(foreign_table, col_name, sep = ".")
        col_type <- foreign_table_cols$types[foreign_table_cols$names == col_name] %>% as.character()
        col_where <- input[[paste('where_', input$select_table, '_', full_col_name, sep = '')]]
        
        if (is.null(col_where)) {
          next
        }
        
        where_column_info <- get_table_info(foreign_table)$column_information
        col_type = where_column_info$types[
          where_column_info$names==col_name
          ] %>% as.character()
        
        subquery <- paste(
          parent_column_name, 'in (select', foreign_column_name, 'from', foreign_table
        )
        
        if (col_type %in% c('int','float')) {
          # slider
          minimum <- where_column_info$minimum[
            where_column_info$names==col_name
            ] %>% as.numeric()
          maximum <- where_column_info$maximum[
            where_column_info$names==col_name
            ] %>% as.numeric()
          
          if (col_where[1]!= minimum | col_where[2]!=maximum) {
            subquery <- paste(
              subquery, 'where',
              full_col_name, ">=", 
              col_where[1], "and", full_col_name, "<=",
              col_where[2], ')'
            )
          }
        } else if (col_type == 'varchar') {
          if (col_where != '') {
            subquery <- paste(
              subquery, ' where ',
              full_col_name, ' like ',
              "'%", toupper(col_where), "%')",
              sep = ''
            )
          }
        }
        
        if (endsWith(subquery,')')) {
          if (where != '') {
            where <- paste(where, 'and')
          }
          where <- paste(where, subquery)
        }
      }
    }
  }
  
  return(where)
}

getDT <- function(input, output) {
  if (input$custom_query != '') {
    query <- input$custom_query
    output$query = renderText({query})
    data <- dbGetQuery(
      conn,
      query
    ) %>% data.frame()
    
  } else {
    where <- get_query_where(input)
    
    if(length(input$select_columns) > 0) {
      from_table <- input$select_table
      query <- paste(
        "select", 
        paste(
          paste(input$select_table, ".", input$select_columns, sep = ''),
          collapse = ', '
        ), 
        "from", from_table,
        ifelse(where != "", paste("where", where), "")
      )
      output$query = renderText({query})
      data <- dbGetQuery(
        conn,
        query
      ) %>% data.frame()
    } else {
      data <- data.frame()
    }
  }
  
  renderDT({
    data
  })
}

getcols = function(conn,tablename){
    id = dbGetQuery(conn, paste("select object_id from sys.tables where name = '", tablename, "'", sep =''))[1,1] %>% as.character()
    res = dbGetQuery(conn,paste("select name from sys.columns where object_id =",id))[,1]
    return(res)
}

ntables = function(){
  if (exists('conn')) {
    res = dbGetQuery(conn,"select name from sys.tables")
    return(res)
  }
}





