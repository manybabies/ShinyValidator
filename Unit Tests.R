# Load necessary libraries and source your common functions
library(testthat)
library(tidyverse)
library(yaml)

source("common.R")  # Make sure common.R contains your validation functions

# Sample dataset for testing
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

# Run unit tests
test_that("ValidateRestricted works correctly", {
  expect_false(ValidateRestricted(data.frame(restricted_field = c(5, 60, 70)), test_fields[[4]]))
})

# Print a message if all tests pass
cat("All unit tests completed successfully!\n")


