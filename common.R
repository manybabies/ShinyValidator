
# load specs
library(tidyverse)
studies <- data_frame(file = dir(path = "data_specifications")) %>%
  mutate(file = str_replace(file, ".yaml", "")) %>%
  separate(file, into = c("study","format"))

# Load required libraries
library(stringr)

# Main Validation Function
validate_dataset_field <- function(dataset_contents, field) {
  if (field$required) {
    if (field$field %in% names(dataset_contents)) {
      if (any(is.na(dataset_contents[[field$field]])) && !field$NA_allowed) {  
        cat(sprintf("Dataset has blank or NA for required field: '%s'.\n", field$field))
        return(FALSE)
      }
      
      if (field$type == "options") {
        return(ValidateOption(dataset_contents, field))
      } else if (field$type == "multiple_options") {
        return(ValidateMultipleOptions(dataset_contents, field))
      } else if (field$type == "numeric") {
        return(ValidateNumeric(dataset_contents, field))
      } else if (field$type == "string") {
        return(ValidateString(dataset_contents, field))
      } else if (field$type == "restricted") {
        return(ValidateRestricted(dataset_contents, field))
      }
    } else {
      # Field is missing in the dataset
      cat(sprintf("Dataset is missing required field: '%s'.\n", field$field))
      return(FALSE)
    }
  }
  return(TRUE)
}

# Validator Functions

# Validate "options" type
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
    for (value in invalid_values) {
      cat(sprintf("Dataset has invalid value '%s' for field '%s'. Please check the specifications!\n", value, field$field))
    }
    return(FALSE)
  }
  
  return(TRUE)
}

# Validate "multiple_options" type
ValidateMultipleOptions <- function(dataset_contents, field) {
  options <- if (is.list(field$options)) {
    names(unlist(field$options, recursive = FALSE)) 
  } else {
    field$options
  }
  
  delimiter <- field$delimiter
  raw_contents <- dataset_contents[[field$field]]
  
  updated_fields <- unlist(str_split(raw_contents, delimiter))  
  invalid_values <- setdiff(unique(updated_fields), options)  
  
  if (field$NA_allowed) {
    invalid_values <- na.omit(invalid_values)  
  }
  
  if (length(invalid_values) > 0) {
    for (value in invalid_values) {
      cat(sprintf("Dataset has invalid value '%s' for field '%s'. Please check the specifications!\n", value, field$field))
    }
    return(FALSE)
  }
  
  return(TRUE)
}

# Validate "numeric" type
ValidateNumeric <- function(dataset_contents, field) {
  field_contents <- dataset_contents[[field$field]]
  
  if (!is.numeric(field_contents) && !all(is.na(field_contents))) {  
    cat(sprintf("Dataset has wrong type for numeric field '%s'. Please check the specifications!\n", field$field))
    return(FALSE)
  }
  
  return(TRUE)
}

# Validate "string" type
ValidateString <- function(dataset_contents, field) {
  field_contents <- dataset_contents[[field$field]]
  
  if (field$format == "uncapitalized") {
    isCap <- str_detect(field_contents, "[:upper:]")
    
    if (any(isCap)) { 
      cat(sprintf("Dataset has an uppercase letter in lowercase-only field '%s'.\n", field$field))
      return(FALSE)
    }
  }
  
  return(TRUE)
}

# Validate "restricted" type
ValidateRestricted <- function(dataset_contents, field) {
  field_contents <- as.numeric(dataset_contents[[field$field]])
  print(field_contents)
  
  min <- min(field_contents)
  print(min)
  max <- max(field_contents)
  print(max)
  
  ll <- as.numeric(field$lowerlimit)
  print(ll)
  ul <- as.numeric(field$upperlimit)
  print(ul)
  
  if(min < ll) {
    return(FALSE)
  }
  
  if(max > ul) {
    return(FALSE)
  }
  
  return(TRUE)
}


test_dataset <- data.frame(
  numeric_field = c(10, 20, 30, 40, 50),
  string_field = c("apple", "banana", "cherry", "date", "elderberry"),
  options_field = c("opt1", "opt2", "opt1", "opt3", "opt2"),
  restricted_field = c(15, 25, 20, 20, 20)
)

# Sample fields specification for testing
test_fields <- list(
  list(field = "numeric_field", type = "numeric", required = TRUE, NA_allowed = FALSE),
  list(field = "string_field", type = "string", required = TRUE, NA_allowed = TRUE, format = "uncapitalized"),
  list(field = "options_field", type = "options", required = TRUE, options = c("opt1", "opt2"), NA_allowed = FALSE),
  list(field = "restricted_field", type = "restricted", required = TRUE, lowerlimit = 10, upperlimit = 50, NA_allowed = FALSE)
)

# Validate dataset's values for all fields
validate_dataset <- function(fields, dataset_contents) {

  valid_fields <- map(fields, function(field) {
    validate_dataset_field(dataset_contents, field)
  })
  valid_dataset <- all(unlist(valid_fields))
  
  return(valid_dataset)
}




