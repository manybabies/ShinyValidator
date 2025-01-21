library(openxlsx)

highlight_csv_to_xlsx <- function(df, highlight_entries, output_file) {
  wb <- createWorkbook()
  sheet_name <- "Error Based"
  addWorksheet(wb, sheet_name)
  
  writeData(wb, sheet = sheet_name, x = df)
  highlight_style <- createStyle(fgFill = "yellow")
  
  i <- 1
  while (i <= length(highlight_entries) - 1) {
    column_name <- highlight_entries[[i]]
    invalid_value <- highlight_entries[[i+1]]
    col_index <- which(names(df) == column_name)
    if (length(col_index) == 0) {
      stop(sprintf("Column '%s' not found in the dataframe. Available columns: %s", 
                   column_name, paste(names(df), collapse = ", ")))
    }
    
    row_indices <- which(df[[col_index]] %in% invalid_value)
    
    if (length(row_indices) > 0) {
      addStyle(
        wb,
        sheet = sheet_name,
        style = highlight_style,
        rows = row_indices + 1, 
        cols = col_index,
        gridExpand = TRUE,
        stack = TRUE
      )
    } else {
      warning(sprintf("No rows match the highlight criteria for column '%s'.", column_name))
    }
    
    i <- i + 2
  }
  
  return(wb)
  saveWorkbook(wb, output_file, overwrite = TRUE)
}
