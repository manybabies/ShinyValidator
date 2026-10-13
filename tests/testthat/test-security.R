test_that("YAML !expr tags are never evaluated", {
  marker <- normalizePath(tempfile("pwned"), winslash = "/", mustWork = FALSE)
  yml <- write_tmp(sprintf('app_title: !expr file.create("%s")', marker), ".yaml")
  try(read_yaml_safe(yml), silent = TRUE)
  expect_false(file.exists(marker))
})

test_that("YAML size cap and missing files", {
  big <- write_tmp(rep("a: 1", 300000), ".yaml")        # about 1.5 MB
  expect_error(read_yaml_safe(big), "too large")
  expect_error(read_yaml_safe(tempfile(fileext = ".yaml")), "not found")
  expect_equal(read_yaml_safe(write_tmp("a: 1", ".yaml"))$a, 1)
})

test_that("only http(s) links are allowed", {
  expect_equal(safe_link_url("https://example.org/a?b=1"), "https://example.org/a?b=1")
  expect_equal(safe_link_url("  http://example.org "), "http://example.org")
  
  bad_inputs <- list(
    "javascript:alert(1)", "JaVaScRiPt:alert(1)", "data:text/html,x",
    "vbscript:x", "//example.org", "ftp://example.org", "https://a b",
    "", NA, NULL, c("https://a.org", "https://b.org")
  )
  
  for (i in seq_along(bad_inputs)) {
    expect_null(safe_link_url(bad_inputs[[i]]), info = paste("case", i))
  }
})

test_that("regex_escape neutralises special characters", {
  tricky <- c("A.B", "ID(", "[x]", "a+b", "a|b", "^start$", "back\\slash", "{1,2}", "a*b?")
  for (s in tricky) {
    expect_true(grepl(paste0("^", regex_escape(s), "$"), s, perl = TRUE), info = s)
  }
  expect_false(grepl(paste0("^", regex_escape("A.B"), "$"), "AxB", perl = TRUE))
})