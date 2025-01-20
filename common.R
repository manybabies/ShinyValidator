library(tidyverse)
library(stringr)
source("ErrorHandler.R")

studies <- data_frame(file = dir(path = "data_specifications")) %>%
  mutate(file = str_replace(file, ".yaml", "")) %>%
  separate(file, into = c("study", "format"))

# Main Validation Function
validate_dataset_field <- function(dataset_contents, field) {
  if (field$required) {
    if (field$field %in% names(dataset_contents)) {
      if (any(is.na(dataset_contents[[field$field]])) && !field$NA_allowed) {
        cat(sprintf("Dataset has blank or NA for required field: '%s'.\n", field$field))
        return(list(FALSE, NA))
      }
      
      if (field$type == "options") {
        return(ValidateOption(dataset_contents, field))
      } else if (field$type == "multiple_options") {
        return(ValidateMultipleOptions(dataset_contents, field))
      } else if (field$type == "numeric") {
        return(ValidateNumeric(dataset_contents, field))
      } else if (field$type == "string") {
        return(ValidateString(dataset_contents, field))
      }
    } else {
      cat(sprintf("Dataset is missing required field: '%s'.\n", field$field))
      return(list(FALSE, NA))
    }
  }
  return(list(TRUE, NA))
}

# Validate "options" type - C
ValidateOption <- function(dataset_contents, field) {
  options <- if (is.list(field$options)) {
    names(unlist(field$options, recursive = FALSE))
  } else {
    field$options
  }
  
  invalid_values <- setdiff(unique(dataset_contents[[field$field]]), options)
  
  if (field$NA_allowed) {
    invalid_values <- na.omit(invalid_values)
  }
  
  if (length(invalid_values) > 0) {
    incorrect <- data.frame(
      column = field$field, 
      invalid_value = invalid_values
    )
    return(list(FALSE, incorrect))
  }
  
  return(list(TRUE, NA))
}

# Validate "numeric" type - C
ValidateNumeric <- function(dataset_contents, field) {
  field_contents <- dataset_contents[[field$field]]
  invalid_content <- c()
  
  numeric_values <- suppressWarnings(as.numeric(field_contents))
  non_numeric_indices <- which(is.na(numeric_values) & !is.na(field_contents))
  
  if (length(non_numeric_indices) > 0) {
    cat(sprintf("Dataset has wrong type for numeric field '%s'. Please check the specifications!\n", field$field))
    invalid_content <- c(invalid_content, field_contents[non_numeric_indices])
  }
  
  if (field$format == "restricted") {
    numeric_values <- numeric_values[!is.na(numeric_values)]
    lowerLimit <- as.numeric(field$lowerlimit)
    upperLimit <- as.numeric(field$upperlimit)
    
    below_lower <- numeric_values[numeric_values < lowerLimit]
    above_upper <- numeric_values[numeric_values > upperLimit]
    
    if (length(below_lower) > 0) {
      cat(sprintf("Dataset has data points below the lower limit for numeric field '%s'. Please check the specifications!\n", field$field))
      invalid_content <- c(invalid_content, below_lower)
    }
    
    if (length(above_upper) > 0) {
      cat(sprintf("Dataset has data points above the upper limit for numeric field '%s'. Please check the specifications!\n", field$field))
      invalid_content <- c(invalid_content, above_upper)
    }
  }
  
  if (length(invalid_content) > 0) {
    incorrect <- data.frame(
      column = field$field, 
      invalid_value = invalid_content
    )
    
    return(list(FALSE, incorrect))
  }
  
  return(list(TRUE, NA))
}

# Validate "string" type
ValidateString <- function(dataset_contents, field) {
  field_contents <- dataset_contents[[field$field]]
  invalid_value <- c()
  
  if (field$format == "uncapitalized") {
    has_upper <- grepl("[[:upper:]]", field_contents)
    
    if (any(has_upper)) {
      cat(sprintf("Dataset has an uppercase letter in lowercase-only field '%s'.\n", field$field))
      invalid_value <- c(invalid_value, field_contents[has_upper])
    }
  }
  
  if (!is.na(field$lowerlimit)) {
    lowerLimit <- as.numeric(field$lowerlimit)
    short_strings <- field_contents[nchar(field_contents) < lowerLimit]
    
    if (length(short_strings) > 0) {
      cat(sprintf("Dataset has strings shorter than the lower limit for field '%s'.\n", field$field))
      invalid_value <- c(invalid_value, short_strings)
    }
  }
  
  if (!is.na(field$upperlimit)) {
    upperLimit <- as.numeric(field$upperlimit)
    long_strings <- field_contents[nchar(field_contents) > upperLimit]
    
    if (length(long_strings) > 0) {
      cat(sprintf("Dataset has strings longer than the upper limit for field '%s'.\n", field$field))
      invalid_value <- c(invalid_value, long_strings)
    }
  }
  
  if (length(invalid_value) > 0) {
    incorrect <- data.frame(
      column = field$field, 
      invalid_value = invalid_value
    )
    
    return(list(FALSE, incorrect))
  }
  
  return(list(TRUE, NA))
}

# Validate dataset
validate_dataset <- function(fields, dataset_contents) {
  issues <- list() 
  results <- TRUE
  
  for(i in fields){
    result <- validate_dataset_field(dataset_contents, i)
    if (!result[[1]]) {
      results <- FALSE
      issues <- append(issues,result[[2]])
    }
  }
  
  return(list(results,issues))
}
