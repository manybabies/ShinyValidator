key <- strrep("ab", 32)

make_certified <- function(df, lab = "lab-1", study = "Default", fmt = "Data", secret = key) {
  tmp <- tempfile(fileext = ".csv")
  readr::write_csv(df, tmp, na = "")
  bytes <- readBin(tmp, "raw", n = file.info(tmp)$size)
  unlink(tmp)
  code <- generate_download_code(lab, study, fmt, bytes, secret)
  list(bytes = bytes, code = code,
       name = paste0(lab, "_", study, "_", fmt, "_", code, ".csv"))
}

df <- data.frame(participant_id = c("P1", "P2"), age = c("34", "29"),
                 stringsAsFactors = FALSE)

test_that("code matches the original formula", {
  cert <- make_certified(df)
  msg <- paste("lab-1", "Default", "Data", rawToChar(cert$bytes), sep = "|")
  expected <- substr(digest::hmac(key, msg, algo = "sha256", serialize = FALSE), 1, 16)
  expect_equal(cert$code, expected)
  expect_match(cert$code, "^[0-9a-f]{16}$")
})

test_that("an untouched certified file verifies", {
  cert <- make_certified(df)
  p <- parse_certified_filename(cert$name)
  expect_equal(p$lab_id, "lab-1")
  expect_equal(p$study_guess, "Default")
  expect_equal(p$format_guess, "Data")
  res <- verify_download_code(p$lab_id, "Default", "Data", cert$bytes, p$code, key)
  expect_true(res$verified)
})

test_that("any change to the file, ids or key fails verification", {
  cert <- make_certified(df)
  
  edited <- make_certified(data.frame(participant_id = c("P1", "P2"),
                                      age = c("34", "30"), stringsAsFactors = FALSE))
  expect_false(verify_download_code("lab-1", "Default", "Data", edited$bytes, cert$code, key)$verified)
  
  expect_false(verify_download_code("lab-2", "Default", "Data", cert$bytes, cert$code, key)$verified)
  expect_false(verify_download_code("lab-1", "Other", "Data", cert$bytes, cert$code, key)$verified)
  expect_false(verify_download_code("lab-1", "Default", "Other", cert$bytes, cert$code, key)$verified)
  expect_false(verify_download_code("lab-1", "Default", "Data", cert$bytes, cert$code, strrep("cd", 32))$verified)
  
  # One extra newline at the end is enough
  extra <- c(cert$bytes, charToRaw("\n"))
  expect_false(verify_download_code("lab-1", "Default", "Data", extra, cert$code, key)$verified)
})

test_that("code comparison ignores case and surrounding spaces", {
  cert <- make_certified(df)
  expect_true(verify_download_code("lab-1", "Default", "Data", cert$bytes,
                                   paste0(" ", toupper(cert$code), " "), key)$verified)
})

test_that("bad inputs are refused with a reason, never an error", {
  cert <- make_certified(df)
  bad <- function(...) {
    res <- verify_download_code(...)
    expect_false(res$verified)
    expect_true(nzchar(res$reason))
  }
  bad("", "Default", "Data", cert$bytes, cert$code, key)
  bad("bad id!", "Default", "Data", cert$bytes, cert$code, key)
  bad("lab-1", "", "Data", cert$bytes, cert$code, key)
  bad("lab-1", "Default", NA, cert$bytes, cert$code, key)
  bad("lab-1", "Default", "Data", cert$bytes, "short", key)
  bad("lab-1", "Default", "Data", cert$bytes, cert$code, "")
  bad("lab-1", "Default", "Data", as.raw(c(65, 0, 66)), cert$code, key)  # embedded NUL
})

test_that("file names that are not certified files are not parsed", {
  expect_null(parse_certified_filename("data.csv"))
  expect_null(parse_certified_filename("lab-1_Default_Data.csv"))
  expect_null(parse_certified_filename("lab-1_Default_Data_nothexnothexnoth.csv"))
  expect_null(parse_certified_filename(NA))
  expect_null(parse_certified_filename(NULL))
})

test_that("studies with underscores leave the guesses blank but still parse", {
  p <- parse_certified_filename("lab-1_My_Study_Fmt_0123456789abcdef.csv")
  expect_equal(p$lab_id, "lab-1")
  expect_equal(p$middle, "My_Study_Fmt")
  expect_true(is.na(p$study_guess))
})