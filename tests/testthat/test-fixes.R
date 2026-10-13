mk <- function(name, type, ...) {
  c(list(field = name, type = type, required = TRUE,
         NA_allowed = FALSE, empty_allowed = FALSE), list(...))
}

df1 <- function(name, values) {
  out <- data.frame(values, stringsAsFactors = FALSE)
  names(out) <- name
  out
}

test_that("upper-case fields get upper-case proposals", {
  f <- mk("code", "string", format = "capitalized")
  fx1 <- suggest_fixes(list(f), df1("code", c("ABC", "abc", "Abc")))
  expect_equal(fx1$row, c(2L, 3L))
  expect_equal(fx1$proposed, c("ABC", "ABC"))
  expect_equal(fx1$current, c("abc", "Abc"))
  expect_true(all(nzchar(fx1$reason)))
})

test_that("lower-case fields get lower-case proposals", {
  f <- mk("code", "string", format = "uncapitalized")
  fx1 <- suggest_fixes(list(f), df1("code", c("abc", "ABC", "Abc")))
  expect_equal(fx1$row, c(2L, 3L))
  expect_equal(fx1$proposed, c("abc", "abc"))
})

test_that("spaces are removed, alone or together with other fixes", {
  f <- mk("code", "string", format = "capitalized")
  
  # Only cells that currently fail validation are touched: " ABC" is already valid
  fx1 <- suggest_fixes(list(f), df1("code", c(" ABC", " abc ", "abc")))
  expect_equal(fx1$row, c(2L, 3L))
  expect_equal(fx1$proposed, c("ABC", "ABC"))
  expect_match(fx1$reason[1], "spaces")
  expect_match(fx1$reason[1], "upper case")
  expect_false(grepl("spaces", fx1$reason[2]))
  expect_match(fx1$reason[2], "upper case")
})

test_that("options that differ only by case or spaces are proposed", {
  f <- mk("grp", "options", options = c("control", "treatment"))
  fx1 <- suggest_fixes(list(f), df1("grp", c("Control", "TREATMENT", "control", " treatment")))
  expect_equal(fx1$row, c(1L, 2L, 4L))
  expect_equal(fx1$proposed, c("control", "treatment", "treatment"))
})

test_that("ambiguous or unknown options are not proposed", {
  f <- mk("grp", "options", options = c("Yes", "YES"))
  expect_equal(nrow(suggest_fixes(list(f), df1("grp", "yes"))), 0)
  
  g <- mk("grp", "options", options = c("control", "treatment"))
  expect_equal(nrow(suggest_fixes(list(g), df1("grp", c("other", "contrl")))), 0)
})

test_that("decimal commas are proposed, but thousands-style values are left alone", {
  f <- mk("score", "numeric", format = "restricted",
          lowerlimit = 0, upperlimit = 100, allow_decimals = "yes")
  fx1 <- suggest_fixes(list(f), df1("score", c("3,5", "4.5", "1,234", "7,25")))
  expect_equal(fx1$row, c(1L, 4L))
  expect_equal(fx1$proposed, c("3.5", "7.25"))
})

test_that("a proposal is only made if the new value passes every check", {
  num <- mk("score", "numeric", format = "restricted",
            lowerlimit = 0, upperlimit = 100, allow_decimals = "yes")
  expect_equal(nrow(suggest_fixes(list(num), df1("score", "150,5"))), 0)
  
  short <- mk("code", "string", format = "capitalized", upperlimit = 3)
  expect_equal(nrow(suggest_fixes(list(short), df1("code", "abcdef"))), 0)
  expect_equal(suggest_fixes(list(short), df1("code", "abc"))$proposed, "ABC")
})

test_that("NA and empty cells are never touched", {
  f <- mk("code", "string", format = "capitalized")
  expect_equal(nrow(suggest_fixes(list(f), df1("code", c(NA, "")))), 0)
})

test_that("auto_fix: no switches suggestions off for a field", {
  f <- mk("code", "string", format = "capitalized", auto_fix = "no")
  expect_equal(nrow(suggest_fixes(list(f), df1("code", "abc"))), 0)
})

test_that("valid data and missing columns give an empty table with the right columns", {
  f <- mk("code", "string", format = "capitalized")
  
  none <- suggest_fixes(list(f), df1("code", c("ABC", "DEF")))
  expect_equal(nrow(none), 0)
  expect_equal(names(none), c("row", "column", "current", "proposed", "reason", "confidence"))
  
  expect_equal(nrow(suggest_fixes(list(f), df1("other", "abc"))), 0)
  expect_equal(nrow(suggest_fixes(list(f), NULL)), 0)
  expect_equal(nrow(suggest_fixes(list(), df1("code", "abc"))), 0)
})

test_that("approved fixes are applied and the dataset then validates", {
  fields <- list(
    mk("code", "string", format = "capitalized"),
    mk("grp", "options", options = c("control", "treatment"))
  )
  
  dat <- data.frame(code = c("abc", "DEF"), grp = c("Control", "treatment"),
                    stringsAsFactors = FALSE)
  expect_false(validate_dataset(fields, dat)$valid)
  
  fixes <- suggest_fixes(fields, dat)
  expect_equal(nrow(fixes), 2)
  
  out <- apply_fixes(dat, fixes)
  expect_equal(nrow(out$applied), 2)
  expect_equal(out$data$code, c("ABC", "DEF"))
  expect_equal(out$data$grp, c("control", "treatment"))
  expect_true(validate_dataset(fields, out$data)$valid)
  
  # The original is untouched
  expect_equal(dat$code, c("abc", "DEF"))
})

test_that("only the approved subset is applied", {
  f <- mk("code", "string", format = "capitalized")
  dat <- df1("code", c("abc", "def"))
  fixes <- suggest_fixes(list(f), dat)
  
  out <- apply_fixes(dat, fixes[2, , drop = FALSE])
  expect_equal(out$data$code, c("abc", "DEF"))
  expect_equal(out$applied$row, 2L)
})

test_that("a stale proposal is skipped when the cell has changed since", {
  f <- mk("code", "string", format = "capitalized")
  dat <- df1("code", c("abc", "def"))
  fixes <- suggest_fixes(list(f), dat)
  
  dat$code[1] <- "xyz"
  out <- apply_fixes(dat, fixes)
  expect_equal(out$data$code, c("xyz", "DEF"))
  expect_equal(out$applied$row, 2L)
})

test_that("applying nothing changes nothing", {
  dat <- df1("code", c("abc", "def"))
  out <- apply_fixes(dat, suggest_fixes(list(), dat))
  expect_equal(out$data, dat)
  expect_equal(nrow(out$applied), 0)
})