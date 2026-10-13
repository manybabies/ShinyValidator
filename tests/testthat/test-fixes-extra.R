mk <- function(name, type, ...) {
  c(list(field = name, type = type, required = TRUE,
         NA_allowed = FALSE, empty_allowed = FALSE), list(...))
}

df1 <- function(name, values) {
  out <- data.frame(values, stringsAsFactors = FALSE)
  names(out) <- name
  out
}

fix_for <- function(field, values) suggest_fixes(list(field), df1(field$field, values))

# Numbers ---------------------------------------------------------------------------------

test_that("trailing zeros are added or removed to match the decimal places required", {
  f <- mk("score", "numeric", format = "restricted", lowerlimit = 0, upperlimit = 100,
          allow_decimals = "yes", min_decimals = 2, max_decimals = 2)
  
  fx1 <- fix_for(f, c("1.5", "1.500", "2", "1.555", "1.50"))
  expect_equal(fx1$row, c(1L, 2L, 3L))
  expect_equal(fx1$proposed, c("1.50", "1.50", "2.00"))
  expect_true(all(fx1$confidence == "safe"))
  expect_match(fx1$reason[1], "Trailing zeros added")
  expect_match(fx1$reason[2], "Trailing zeros removed")
})

test_that("values the validator already accepts are left alone", {
  f <- mk("n", "numeric", format = "restricted", lowerlimit = 0, upperlimit = 100000,
          allow_decimals = "no")
  
  # "34.0", "34.00", "1e3" and "2E+2" are valid as they stand, so there is nothing to fix
  expect_equal(nrow(fix_for(f, c("34.0", "34.00", "1e3", "2E+2", "1000"))), 0)
  
  # A genuine decimal is an error, and it is never rounded
  expect_equal(nrow(fix_for(f, "35.5")), 0)
})

test_that("special minus signs, full-width digits and non-breaking spaces are cleaned", {
  f <- mk("t", "numeric", format = "restricted", lowerlimit = -10, upperlimit = 10,
          allow_decimals = "no")
  
  fx1 <- fix_for(f, c("\u22125", "\uFF15", "5\u00A0", "\u20133"))
  expect_equal(fx1$row, 1:4)
  expect_equal(fx1$proposed, c("-5", "5", "5", "-3"))
  expect_match(fx1$reason[1], "unusual characters")
})

test_that("a decimal comma and extra zeros can be fixed together", {
  f <- mk("score", "numeric", format = "restricted", lowerlimit = 0, upperlimit = 100,
          allow_decimals = "yes", min_decimals = 2, max_decimals = 2)
  
  fx1 <- fix_for(f, "1,5")
  expect_equal(fx1$proposed, "1.50")
  expect_match(fx1$reason, "Decimal comma")
  expect_match(fx1$reason, "Trailing zeros added")
})

test_that("numbers are never rounded, clipped or guessed", {
  f <- mk("score", "numeric", format = "restricted", lowerlimit = 0, upperlimit = 100,
          allow_decimals = "yes", min_decimals = 2, max_decimals = 2)
  
  expect_equal(nrow(fix_for(f, c("3.14159", "150", "abc", "1,234"))), 0)
})

# Options ---------------------------------------------------------------------------------

test_that("options match despite different separators, spacing and accents", {
  f <- mk("type", "options", options = c("self_report", "interview"))
  fx1 <- fix_for(f, c("self report", "Self-Report", "interview ", "other"))
  expect_equal(fx1$row, 1:3)
  expect_equal(fx1$proposed, c("self_report", "self_report", "interview"))
  expect_match(fx1$reason[1], "spacing")
  
  g <- mk("drink", "options", options = c("caf\u00e9", "tea"))
  fx2 <- fix_for(g, c("cafe", "CAFE", "Tea"))
  expect_equal(fx2$proposed, c("caf\u00e9", "caf\u00e9", "tea"))
})

test_that("repeated spaces and zero-width or non-breaking characters in options are cleaned", {
  f <- mk("type", "options", options = c("self report", "interview"))
  expect_equal(fix_for(f, "self  report")$proposed, "self report")
  
  g <- mk("grp", "options", options = c("control", "treatment"))
  fx1 <- fix_for(g, c("con\u200Btrol", "con\u00A0trol"))
  expect_equal(fx1$proposed, c("control", "control"))
})

test_that("yes/no synonyms are proposed but marked for checking", {
  f <- mk("consent", "options", options = c("yes", "no"))
  
  fx1 <- fix_for(f, c("y", "TRUE", "1", "N", "false", "maybe", "Yes"))
  expect_equal(fx1$row, c(1L, 2L, 3L, 4L, 5L, 7L))
  expect_equal(fx1$proposed, c("yes", "yes", "yes", "no", "no", "yes"))
  expect_equal(fx1$confidence, c("check", "check", "check", "check", "check", "safe"))
})

test_that("yes/no synonyms are only used when the options really are a yes/no pair", {
  f <- mk("colour", "options", options = c("red", "blue"))
  expect_equal(nrow(fix_for(f, c("y", "1", "n"))), 0)
  
  g <- mk("answer", "options", options = c("yes", "no", "unsure"))
  expect_equal(nrow(fix_for(g, "y")), 0)
})

# Strings ---------------------------------------------------------------------------------

test_that("regex fields get a case or spacing fix when exactly one variant fits", {
  f <- mk("id", "string", format = "regex", pattern = "^P[0-9]{2}$")
  
  fx1 <- fix_for(f, c("p01", " p 01", "P1", "q05"))
  expect_equal(fx1$row, c(1L, 2L))
  expect_equal(fx1$proposed, c("P01", "P01"))
  expect_true(all(fx1$confidence == "safe"))
})

test_that("regex fields get no fix when several variants would fit", {
  f <- mk("word", "string", format = "regex", pattern = "^[A-Za-z]+$")
  expect_equal(nrow(fix_for(f, "ab c")), 0)
})

test_that("lost leading zeros are restored only when exactly one length fits", {
  f <- mk("id", "string", format = "regex", pattern = "^[0-9]{3}$")
  
  fx1 <- fix_for(f, c("7", "42", "1234", "abc"))
  expect_equal(fx1$row, c(1L, 2L))
  expect_equal(fx1$proposed, c("007", "042"))
  expect_true(all(fx1$confidence == "check"))
  
  g <- mk("id", "string", format = "regex", pattern = "^[0-9]{3,5}$")
  expect_equal(nrow(fix_for(g, "7")), 0)
})

test_that("every proposal in the table has a valid confidence", {
  f <- mk("consent", "options", options = c("yes", "no"))
  fx1 <- fix_for(f, c("y", "Yes"))
  expect_true(all(fx1$confidence %in% c("safe", "check")))
})