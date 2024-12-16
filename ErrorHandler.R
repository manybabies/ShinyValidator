library(openxlsx)

highlight_csv_to_xlsx <- function(df, highlight_entries, output_file) {
  # Initialize a workbook and create a worksheet
  wb <- createWorkbook()
  message("Workbook initialized.")
  sheet_name <- "Error Based"
  addWorksheet(wb, sheet_name)
  
  # Write the data to the worksheet
  writeData(wb, sheet = sheet_name, x = df)
  
  # Define a highlight style
  highlight_style <- createStyle(fgFill = "yellow")
  
  i <- 1
  # Apply highlight styles based on criteria
  while (i <= length(highlight_entries) - 1) {
    column_name <- highlight_entries[[i]]
    print(column_name)
    invalid_value <- highlight_entries[[i+1]]
    print(invalid_value)
    # Check if the specified column exists
    col_index <- which(names(df) == column_name)
    if (length(col_index) == 0) {
      stop(sprintf("Column '%s' not found in the dataframe. Available columns: %s", 
                   column_name, paste(names(df), collapse = ", ")))
    }
    
    # Find rows that match the invalid values
    row_indices <- which(df[[col_index]] %in% invalid_value)
    
    if (length(row_indices) > 0) {
      # Add style to the matching cells
      addStyle(
        wb,
        sheet = sheet_name,
        style = highlight_style,
        rows = row_indices + 1,  # Account for header row
        cols = col_index,
        gridExpand = TRUE,
        stack = TRUE
      )
    } else {
      warning(sprintf("No rows match the highlight criteria for column '%s'.", column_name))
    }
    
    i <- i + 2
  }
  
  # Save the workbook
  saveWorkbook(wb, output_file, overwrite = TRUE)
  message(sprintf("Workbook saved as '%s'.", output_file))
}
