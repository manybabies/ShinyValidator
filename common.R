library(tidyverse)
library(stringr)
source("ErrorHandler.R")

studies <- tibble(
  file = list.files(
    path = "data_specifications",
    pattern = "\\.yaml$",
    full.names = FALSE
  )
) |>
  mutate(
    file = str_remove(file, "\\.yaml$")
  ) |>
  separate(
    file,
    into = c("study", "format"),
    sep = "_",
    extra = "merge",
    remove = TRUE
  )

# Main Validation Function
validate_dataset_field <- function(dataset_contents, field) {

  if (field$required) {

    # Check that required variable exists
    if (field$field %in% names(dataset_contents)) {

      # Check for missing values
      if (
        any(is.na(dataset_contents[[field$field]])) &&
        !field$NA_allowed
      ) {

        cat(
          sprintf(
            "Dataset has blank or NA for required variable: '%s'.\n",
            field$field
          )
        )

        return(list(FALSE, NA))
      }


      # Validate according to field type
      if (field$type == "options") {

        return(
          ValidateOption(
            dataset_contents,
            field
          )
        )

      } else if (field$type == "numeric") {

        return(
          ValidateNumeric(
            dataset_contents,
            field
          )
        )

      } else if (field$type == "string") {
        
        if (field$format == "regex") {
          
          return(
            ValidateRegex(
              dataset_contents,
              field
              )
          )
        } else{

        return(
          ValidateString(
            dataset_contents,
            field
            )
          )
        }
      }

    } else {

      cat(
        sprintf(
          "Dataset is missing required variable: '%s'.\n",
          field$field
        )
      )

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
    incorrect <- list(
      column = field$field, 
      invalid_value = invalid_values
    )
    cat(sprintf("Dataset has wrong type for option variable '%s'. To view these errors, please download the highlighted errors sheet on the left.\n", field$field))
    return(list(FALSE, incorrect))
  }
  
  return(list(TRUE, NA))
}

# Validate "numeric" type
ValidateNumeric <- function(dataset_contents, field) {
  
  field_contents <- dataset_contents[[field$field]]
  invalid_content <- c()
  
  # Convert to numeric only for numerical validation
  numeric_values <- suppressWarnings(
    as.numeric(field_contents)
  )
  
  # Check for values that cannot be converted to numeric
  non_numeric_indices <- which(
    is.na(numeric_values) &
      !is.na(field_contents)
  )
  
  if (length(non_numeric_indices) > 0) {
    
    cat(sprintf(
      "Dataset has wrong type for numeric variable '%s'. To view these errors, please download the highlighted errors sheet on the left.\n",
      field$field
    ))
    
    invalid_content <- c(
      invalid_content,
      field_contents[non_numeric_indices]
    )
  }
  
  # Check range restrictions
  if (field$format == "restricted") {
    
    lowerLimit <- as.numeric(field$lowerlimit)
    upperLimit <- as.numeric(field$upperlimit)
    
    valid_numeric_indices <- which(
      !is.na(numeric_values)
    )
    
    below_lower_indices <- valid_numeric_indices[
      numeric_values[valid_numeric_indices] < lowerLimit
    ]
    
    above_upper_indices <- valid_numeric_indices[
      numeric_values[valid_numeric_indices] > upperLimit
    ]
    
    if (length(below_lower_indices) > 0) {
      
      cat(sprintf(
        "Dataset has data points below the lower limit for numeric variable '%s'. To view these errors, please download the highlighted errors sheet on the left.\n",
        field$field
      ))
      
      invalid_content <- c(
        invalid_content,
        field_contents[below_lower_indices]
      )
    }
    
    if (length(above_upper_indices) > 0) {
      
      cat(sprintf(
        "Dataset has data points above the upper limit for numeric variable '%s'. To view these errors, please download the highlighted errors sheet on the left.\n",
        field$field
      ))
      
      invalid_content <- c(
        invalid_content,
        field_contents[above_upper_indices]
      )
    }
  }
  
  # Check whether decimals are allowed
  if (field$allow_decimals == "no") {
    
    decimal_indices <- which(
      !is.na(numeric_values) &
        numeric_values %% 1 != 0
    )
    
    if (length(decimal_indices) > 0) {
      
      cat(sprintf(
        "Dataset has decimal values in numeric variable '%s', but decimals are not allowed. To view these errors, please download the highlighted errors sheet on the left.\n",
        field$field
      ))
      
      invalid_content <- c(
        invalid_content,
        field_contents[decimal_indices]
      )
    }
  }
  
  # Check minimum and maximum decimal places
  if (field$allow_decimals == "yes") {
    
    min_decimals <- as.numeric(field$min_decimals)
    max_decimals <- as.numeric(field$max_decimals)
    
    valid_numeric_indices <- which(
      !is.na(numeric_values)
    )
    
    decimal_places <- sapply(
      field_contents[valid_numeric_indices],
      function(x) {
        
        x <- as.character(x)
        
        if (!grepl("\\.", x)) {
          return(0)
        }
        
        nchar(
          sub(
            "^[^.]*\\.",
            "",
            x
          )
        )
      }
    )
    
    # Too few decimal places
    too_few_decimals <- valid_numeric_indices[
      decimal_places < min_decimals
    ]
    
    # Too many decimal places
    too_many_decimals <- valid_numeric_indices[
      decimal_places > max_decimals
    ]
    
    if (length(too_few_decimals) > 0) {
      
      cat(sprintf(
        "Dataset has values with fewer than %s decimal places for numeric variable '%s'. To view these errors, please download the highlighted errors sheet on the left.\n",
        min_decimals,
        field$field
      ))
      
      invalid_content <- c(
        invalid_content,
        field_contents[too_few_decimals]
      )
    }
    
    if (length(too_many_decimals) > 0) {
      
      cat(sprintf(
        "Dataset has values with more than %s decimal places for numeric variable '%s'. To view these errors, please download the highlighted errors sheet on the left.\n",
        max_decimals,
        field$field
      ))
      
      invalid_content <- c(
        invalid_content,
        field_contents[too_many_decimals]
      )
    }
  }
  
  # Return errors if any were found, remove duplicates
  if (length(invalid_content) > 0) {
    
    invalid_content <- unique(invalid_content)
    
    incorrect <- list(
      column = field$field,
      invalid_value = invalid_content
    )
    
    return(list(FALSE, incorrect))
  }
  
  # No errors
  return(list(TRUE, NA))
}

# Validate "string" type
ValidateString <- function(dataset_contents, field) {
  field_contents <- dataset_contents[[field$field]]
  invalid_value <- c()
  
  if (field$format == "uncapitalized") {
    
    non_na_contents <- field_contents[
      !is.na(field_contents)
    ]
    
    has_upper <- grepl(
      "[[:upper:]]",
      non_na_contents
    )
    
    if (any(has_upper)) {
      cat(sprintf(
        "Dataset has an uppercase letter in lowercase-only variable '%s'. To view these errors, please download the highlighted errors sheet on the left.\n",
        field$field
      ))
      
      invalid_value <- c(
        invalid_value,
        non_na_contents[has_upper]
      )
    }
  }
  
  if (!is.na(field$lowerlimit)) {
    lowerLimit <- as.numeric(field$lowerlimit)
    short_strings <- field_contents[
      !is.na(field_contents) &
        nchar(field_contents) < lowerLimit
    ]
    
    if (length(short_strings) > 0) {
      cat(sprintf("Dataset has inputs shorter than the lower character limit for variable '%s'. To view these errors, please download the highlighted errors sheet on the left.\n", field$field))
      invalid_value <- c(invalid_value, short_strings)
    }
  }
  
  if (!is.na(field$upperlimit)) {
    upperLimit <- as.numeric(field$upperlimit)
    long_strings <- field_contents[
      !is.na(field_contents) &
        nchar(field_contents) > upperLimit
    ]
    
    if (length(long_strings) > 0) {
      cat(sprintf("Dataset has inputs longer than the upper character limit for variable '%s'. To view these errors, please download the highlighted errors sheet on the left.\n", field$field))
      invalid_value <- c(invalid_value, long_strings)
    }
  }
  
  if (length(invalid_value) > 0) {
    incorrect <- list(
      column = field$field, 
      invalid_value = invalid_value
    )
    
    return(list(FALSE, incorrect))
  }
  
  return(list(TRUE, NA))
}

# Generate regex pattern from the three provided examples
GenerateRegex <- function(examples) {
  
  # Remove missing and empty examples
  examples <- examples[
    !is.na(examples) &
      examples != ""
  ]
  
  # Need at least 2 examples
  if (length(examples) < 2) {
    return(NA)
  }
  
  # Find common prefix
  common_prefix <- examples[1]
  
  for (example in examples[-1]) {
    
    max_length <- min(
      nchar(common_prefix),
      nchar(example)
    )
    
    i <- 1
    
    while (
      i <= max_length &&
      substr(common_prefix, i, i) ==
      substr(example, i, i)
    ) {
      i <- i + 1
    }
    
    common_prefix <- substr(
      common_prefix,
      1,
      i - 1
    )
  }
  
  # Remove the common prefix from each example
  remaining <- substr(
    examples,
    nchar(common_prefix) + 1,
    nchar(examples)
  )
  
  # If everything after the prefix is numeric
  if (all(grepl("^[0-9]+$", remaining))) {
    
    pattern <- paste0(
      "^",
      common_prefix,
      "[0-9]+",
      "$"
    )
    
    return(pattern)
  }
  
  # If everything after the prefix is lowercase letters
  if (all(grepl("^[a-z]+$", remaining))) {
    
    pattern <- paste0(
      "^",
      common_prefix,
      "[a-z]+",
      "$"
    )
    
    return(pattern)
  }
  
  # If everything after the prefix is uppercase letters
  if (all(grepl("^[A-Z]+$", remaining))) {
    
    pattern <- paste0(
      "^",
      common_prefix,
      "[A-Z]+",
      "$"
    )
    
    return(pattern)
  }
  
  # If everything after the prefix is letters
  if (all(grepl("^[A-Za-z]+$", remaining))) {
    
    pattern <- paste0(
      "^",
      common_prefix,
      "[A-Za-z]+",
      "$"
    )
    
    return(pattern)
  }
  
  # If remaining characters are alphanumeric
  if (all(grepl("^[A-Za-z0-9]+$", remaining))) {
    
    pattern <- paste0(
      "^",
      common_prefix,
      "[A-Za-z0-9]+",
      "$"
    )
    
    return(pattern)
  }
  
  # Could not confidently determine a pattern
  NA
}
# Validate "regex" type
ValidateRegex <- function(dataset_contents, field) {
  
  field_contents <- dataset_contents[[field$field]]
  
  # Ignore NA values here.
  # NA handling is already performed in validate_dataset_field().
  non_na_contents <- field_contents[
    !is.na(field_contents)
  ]
  
  # Check whether the regex itself is valid
  print(field$pattern)
  print(class(field$pattern))
  
  # Check whether the regex itself is valid
  regex_valid <- tryCatch(
    {
      grepl(
        field$pattern,
        "",
        perl = TRUE
      )
      TRUE
    },
    error = function(e) {
      FALSE
    }
  )
  
  if (!regex_valid) {
    stop(
      sprintf(
        "Invalid regular expression for variable '%s': %s",
        field$field,
        field$pattern
      )
    )
  }
  
  # Find values that do not match the regex
  matches <- grepl(
    field$pattern,
    non_na_contents,
    perl = TRUE
  )
  
  invalid_values <- non_na_contents[!matches]
  
  if (length(invalid_values) > 0) {
    
    cat(
      sprintf(
        "Dataset has values that do not match the required pattern for variable '%s'. To view these errors, please download the highlighted errors sheet on the left.\n",
        field$field
      )
    )
    
    incorrect <- list(
      column = field$field,
      invalid_value = invalid_values
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
