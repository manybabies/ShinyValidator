# load specs
library(tidyverse)
library(stringr)

studies <- data_frame(file = dir(path = "data_specifications")) %>%
  mutate(file = str_replace(file, ".yaml", "")) %>%
  separate(file, into = c("study","format"))


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
        if(field$format == "restricted") {
          return(ValidateRestricted(dataset_contents, field))
        } else {
          return(ValidateNumeric(dataset_contents, field))
        }
      } else if (field$type == "string") {
        return(ValidateString(dataset_contents, field))
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
  
  min <- min(field_contents)
  print(min)
  max <- max(field_contents)
  print(max)
  
  ll <- as.numeric(field$lowerlimit)
  print(ll)
  ul <- as.numeric(field$upperlimit)
  print(ul)
  
  if(min < ll) {
    print("FALSE")
    return(FALSE)
  }
  
  if(max > ul) {
    print("FALSE")
    return(FALSE)
  }
  print("TRUE")
  return(TRUE)
}

# Validate data set's values for all fields
validate_dataset <- function(fields, dataset_contents) {

  valid_fields <- map(fields, function(field) {
    validate_dataset_field(dataset_contents, field)
  })
  valid_dataset <- all(unlist(valid_fields))
  print(valid_dataset)
  return(valid_dataset)
}
