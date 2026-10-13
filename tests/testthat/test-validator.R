# NA / empty ------------------------------------------------------------------------------

test_that("NA handling follows NA_allowed", {
  x <- col(c("a", NA, "b"))
  expect_equal(bad_rows(validate_dataset_field(x, make_field())), 2L)
  expect_true(validate_dataset_field(x, make_field(NA_allowed = TRUE))[[1]])
  expect_true(validate_dataset_field(x, make_field(NA_allowed = "yes"))[[1]])
})

test_that("empty-cell handling follows empty_allowed", {
  x <- col(c("a", "", "b"))
  expect_equal(bad_rows(validate_dataset_field(x, make_field())), 2L)
  expect_true(validate_dataset_field(x, make_field(empty_allowed = TRUE))[[1]])
})

test_that("empty_allowed is respected by every type check", {
  x <- col(c("a", "", "b"))
  opts  <- make_field(type = "options", options = c("a", "b"), empty_allowed = TRUE)
  rx    <- make_field(format = "regex", pattern = "^[a-z]$", empty_allowed = TRUE)
  len   <- make_field(lowerlimit = 1, empty_allowed = TRUE)
  num   <- make_field(type = "numeric", format = "open", allow_decimals = "yes",
                      empty_allowed = TRUE)
  expect_true(validate_dataset_field(x, opts)[[1]])
  expect_true(validate_dataset_field(x, rx)[[1]])
  expect_true(validate_dataset_field(x, len)[[1]])
  expect_true(validate_dataset_field(col(c("1", "", "2")), num)[[1]])
})

test_that("all problems in a column are reported together, paired with the right values", {
  f <- make_field(type = "numeric", format = "restricted", lowerlimit = 0,
                  upperlimit = 10, allow_decimals = "no")
  res <- validate_dataset_field(col(c("5", NA, "99", "abc", "3.5")), f)
  expect_false(res[[1]])
  expect_equal(res[[2]]$invalid_row, c(2L, 3L, 4L, 5L))
  expect_equal(res[[2]]$invalid_value, c(NA, "99", "abc", "3.5"))
})

# Options ---------------------------------------------------------------------------------

test_that("options are matched exactly (case-sensitive), list or vector", {
  for (opts in list(c("a", "b"), list("a", "b"))) {
    f <- make_field(type = "options", options = opts)
    expect_equal(bad_rows(validate_dataset_field(col(c("a", "c", "b", "A")), f)),
                 c(2L, 4L))
  }
  single <- make_field(type = "options", options = "only")
  expect_true(validate_dataset_field(col(c("only", "only")), single)[[1]])
})

# Numeric ---------------------------------------------------------------------------------

test_that("numeric parsing is strict", {
  f <- make_field(type = "numeric", format = "open", allow_decimals = "yes",
                  min_decimals = 0, max_decimals = 6)
  accepted <- c("0", "-3", "+5", ".5", "5.", "1e2", "1E-3", "12.3456")
  rejected <- c("abc", "0x1A", "Inf", "-Inf", "NaN", " 5", "5 ", "1,5", "1..2", "--1", "1e")
  expect_length(bad_rows(validate_dataset_field(col(accepted), f)), 0)
  expect_equal(bad_rows(validate_dataset_field(col(rejected), f)), seq_along(rejected))
})

test_that("numeric range limits are inclusive", {
  f <- make_field(type = "numeric", format = "restricted", lowerlimit = 0,
                  upperlimit = 120, allow_decimals = "no")
  expect_equal(bad_rows(validate_dataset_field(col(c("0", "120", "-1", "121", "60")), f)),
               c(3L, 4L))
})

test_that("decimal places are enforced", {
  f <- make_field(type = "numeric", format = "open", allow_decimals = "yes",
                  min_decimals = 2, max_decimals = 2)
  expect_equal(bad_rows(validate_dataset_field(col(c("1.50", "1.5", "1.555", "2", "0.00")), f)),
               c(2L, 3L, 4L))
  g <- make_field(type = "numeric", format = "open", allow_decimals = "yes",
                  min_decimals = 0, max_decimals = 2)
  expect_equal(bad_rows(validate_dataset_field(col(c("1", "1.5", "1.55", "1.555")), g)), 4L)
})

test_that("allow_decimals works as string or logical", {
  for (v in list("no", FALSE)) {
    f <- make_field(type = "numeric", format = "open", allow_decimals = v)
    expect_equal(bad_rows(validate_dataset_field(col(c("5", "5.5")), f)), 2L)
  }
})

# Strings ---------------------------------------------------------------------------------

test_that("case rules", {
  low <- make_field(format = "uncapitalized")
  up  <- make_field(format = "capitalized")
  expect_equal(bad_rows(validate_dataset_field(col(c("abc", "Abc", "aBc")), low)), c(2L, 3L))
  expect_equal(bad_rows(validate_dataset_field(col(c("ABC", "AbC", "abc", "A1")), up)),
               c(2L, 3L))
})

test_that("string length limits are inclusive", {
  f <- make_field(lowerlimit = 2, upperlimit = 4)
  expect_equal(bad_rows(validate_dataset_field(col(c("a", "ab", "abcd", "abcde")), f)),
               c(1L, 4L))
})

# Regex -----------------------------------------------------------------------------------

test_that("regex fields", {
  f <- make_field(format = "regex", pattern = "^P[0-9]+$")
  expect_equal(bad_rows(validate_dataset_field(col(c("P1", "p1", "P", "P12")), f)),
               c(2L, 3L))
})

test_that("a regex field with no or a broken pattern fails loudly", {
  expect_error(validate_dataset_field(col("a"), make_field(format = "regex", pattern = NA)),
               "no valid pattern")
  expect_error(validate_dataset_field(col("a"), make_field(format = "regex")),
               "no valid pattern")
  expect_error(
    suppressWarnings(
      validate_dataset_field(col("a"), make_field(format = "regex", pattern = "["))
    ),
    "Invalid regular expression"
  )
})

# Whole-dataset validation ----------------------------------------------------------------

test_that("validate_dataset reports unexpected / missing columns", {
  fields <- list(
    make_field(field = "id", type = "options", options = c("a", "b")),
    make_field(field = "n", type = "numeric", format = "open", allow_decimals = "no"),
    make_field(field = "opt", required = FALSE, NA_allowed = TRUE, empty_allowed = TRUE)
  )
  ok <- data.frame(id = c("a", "b"), n = c("1", "2"), stringsAsFactors = FALSE)
  res <- validate_dataset(fields, ok)
  expect_named(res, c("valid", "issues"))
  expect_true(res$valid)                      # optional column absent is fine
  
  extra <- cbind(ok, extra = c("x", "y"))
  types <- vapply(validate_dataset(fields, extra)$issues, `[[`, "", "type")
  expect_equal(types, "unexpected_column")
  
  types <- vapply(validate_dataset(fields, ok["id"])$issues, `[[`, "", "type")
  expect_equal(types, "missing_column")
})

test_that("a field with no `required` key counts as required", {
  f <- make_field(field = "id"); f$required <- NULL
  types <- vapply(validate_dataset(list(f), data.frame(z = "1"))$issues, `[[`, "", "type")
  expect_true("missing_column" %in% types)
})

# Explanations ----------------------------------------------------------------------------

test_that("explain_error", {
  fields <- list(
    make_field(field = "a", type = "options", options = c("x", "y")),
    make_field(field = "b", type = "numeric", format = "open", allow_decimals = FALSE),
    make_field(field = "c", error_message = "Custom text")
  )
  expect_match(
    explain_error(list(type = "invalid_cell", column = "a"), fields),
    '"x"',
    fixed = TRUE
  )
  expect_match(explain_error(list(type = "invalid_cell", column = "b"), fields),
               "Decimal values are not allowed")
  expect_equal(explain_error(list(type = "invalid_cell", column = "c"), fields), "Custom text")
  expect_match(explain_error(list(type = "invalid_cell", column = "zzz"), fields),
               "does not meet")
})

# Helpers ---------------------------------------------------------------------------------

test_that("flag() and num_or()", {
  expect_identical(flag("YES"), TRUE);  expect_identical(flag("no"), FALSE)
  expect_identical(flag(TRUE), TRUE);   expect_true(is.na(flag(NULL)))
  expect_true(is.na(flag("maybe")))
  expect_equal(num_or("3", 0), 3);      expect_equal(num_or(NA, 7), 7)
  expect_equal(num_or(NULL, 7), 7);     expect_equal(num_or("abc", 7), 7)
})

test_that("GenerateRegex", {
  rx <- GenerateRegex(c("A.1", "A.2", "A.3"))
  expect_equal(rx, "^A\\.[0-9]+$")
  expect_true(grepl(rx, "A.7")); expect_false(grepl(rx, "AX7"))
  expect_true(is.na(GenerateRegex(c("abc", "x-9"))))
  expect_true(is.na(GenerateRegex("only-one")))
  expect_true(grepl(GenerateRegex(c("ID1", "ID22", "ID333")), "ID9"))
})

# Sample dataset generator ----------------------------------------------------------------

test_that("generated sample data always passes its own specification", {
  fields <- list(
    make_field(field = "id", format = "regex", pattern = "^ID[0-9]{3}$"),
    make_field(field = "ref", format = "regex", pattern = "^A\\.[0-9]+$"),
    make_field(field = "grp", type = "options", options = "only"),
    make_field(field = "fixed", type = "numeric", format = "restricted",
               lowerlimit = 5, upperlimit = 5, allow_decimals = "no"),
    make_field(field = "big", type = "numeric", format = "restricted",
               lowerlimit = 100000, upperlimit = 200000, allow_decimals = "no"),
    make_field(field = "score", type = "numeric", format = "restricted",
               lowerlimit = 0, upperlimit = 1, allow_decimals = "yes",
               min_decimals = 2, max_decimals = 2),
    make_field(field = "mixed", type = "numeric", format = "open",
               allow_decimals = "yes", min_decimals = 0, max_decimals = 4),
    make_field(field = "CODE", format = "capitalized"),
    make_field(field = "lower", format = "uncapitalized"),
    make_field(field = "short", lowerlimit = 3, upperlimit = 5),
    make_field(field = "Participant ID")
  )
  for (seed in 1:30) {
    set.seed(seed)
    df <- as.data.frame(generate_sample_dataset(fields, 40),
                        check.names = FALSE, stringsAsFactors = FALSE)
    expect_equal(nrow(df), 40)
    expect_true("Participant ID" %in% names(df))
    expect_true(validate_dataset(fields, df)$valid, info = paste("seed", seed))
  }
})

test_that("generator reports impossible specifications", {
  expect_error(generate_sample_dataset(list(make_field(
    type = "numeric", format = "restricted", lowerlimit = 10, upperlimit = 1,
    allow_decimals = "no")), 5), "exceeds")
  expect_error(generate_sample_dataset(list(make_field(type = "weird")), 5), "Unknown field type")
})

test_that("sample data survives a CSV round trip", {
  fields <- list(make_field(field = "n", type = "numeric", format = "restricted",
                            lowerlimit = 100000, upperlimit = 200000, allow_decimals = "no"),
                 make_field(field = "s", type = "numeric", format = "open",
                            allow_decimals = "yes", min_decimals = 2, max_decimals = 2))
  set.seed(1)
  p <- tempfile(fileext = ".csv")
  readr::write_csv(generate_sample_dataset(fields, 20), p, na = "")
  back <- readr::read_csv(p, col_types = readr::cols(.default = "c"), na = "NA")
  expect_false(any(grepl("e", back$n)))             # no 1e+05
  expect_true(all(grepl("\\.[0-9]{2}$", back$s)))   # trailing zeros kept
  expect_true(validate_dataset(fields, as.data.frame(back))$valid)
})

# Robustness (garbage in, no crash out) ---------------------------------------------------

test_that("validator never errors on random messy input", {
  set.seed(42)
  messy <- c("", NA, " ", "NA", "null", "é", "日本語", "a,b", "\"q\"", "1e999", "-0",
             "0x10", "١٢٣", strrep("x", 10000), "line\nbreak", "\t")
  fields <- list(
    make_field(field = "a", type = "numeric", format = "restricted", lowerlimit = 0,
               upperlimit = 10, allow_decimals = "yes", min_decimals = 0, max_decimals = 3),
    make_field(field = "b", type = "options", options = c("x", "y")),
    make_field(field = "c", format = "regex", pattern = "^[A-Z]+$"),
    make_field(field = "d", lowerlimit = 1, upperlimit = 5, format = "capitalized")
  )
  for (i in 1:50) {
    df <- data.frame(a = sample(messy, 20, TRUE), b = sample(messy, 20, TRUE),
                     c = sample(messy, 20, TRUE), d = sample(messy, 20, TRUE),
                     stringsAsFactors = FALSE)
    expect_no_error(validate_dataset(fields, df))
  }
})

# CSV import helpers ----------------------------------------------------------------------

test_that("delimiter and decimal detection", {
  expect_equal(detect_delimiter(write_tmp(c("a,b,c", "1,2,3"))), ",")
  expect_equal(detect_delimiter(write_tmp(c("a;b;c", "1;2;3"))), ";")
  expect_equal(detect_delimiter(write_tmp(c("a\tb", "1\t2"))), "\t")
  expect_equal(detect_decimal_mark(write_tmp(c("a;b", "1,5;2,25")), ";"), ",")
  expect_equal(detect_decimal_mark(write_tmp(c("a,b", "1.5,2.25")), ","), ".")
})

test_that("comma decimals are converted", {
  out <- standardize_decimal_mark(dplyr::tibble(a = "1,5", b = "x,y"), ",")
  expect_equal(out$a, "1.5"); expect_equal(out$b, "x,y")
})

test_that("KNOWN ISSUE: non-numeric columns are rewritten in comma-decimal files", {
  skip("Known issue: standardize_decimal_mark() changes IDs like 'A1,2' in text columns")
  out <- standardize_decimal_mark(dplyr::tibble(id = "A1,2"), ",")
  expect_equal(out$id, "A1,2")
})

test_that("KNOWN LIMITATION: single-column CSVs cannot be loaded", {
  skip("Known limitation: detect_delimiter() needs at least two columns")
  expect_equal(detect_delimiter(write_tmp(c("a", "1", "2"))), ",")
})

# Excel export ----------------------------------------------------------------------------

test_that("Excel export highlights only when there are issues", {
  fields <- list(
    make_field(field = "id", type = "options", options = c("a", "b")),
    make_field(field = "n", type = "numeric", format = "open", allow_decimals = "no")
  )
  bad  <- data.frame(id = c("a", "zz"), n = c("1", NA), stringsAsFactors = FALSE)
  good <- data.frame(id = c("a", "b"),  n = c("1", "2"), stringsAsFactors = FALSE)
  
  f_bad <- tempfile(fileext = ".xlsx"); f_good <- tempfile(fileext = ".xlsx")
  highlight_csv_to_xlsx_v2(bad,  validate_dataset(fields, bad)$issues,  f_bad)
  highlight_csv_to_xlsx_v2(good, validate_dataset(fields, good)$issues, f_good)
  
  expect_equal(openxlsx::getSheetNames(f_bad), "Validated Dataset")
  expect_true(has_yellow_fill(f_bad))
  expect_false(has_yellow_fill(f_good))
})