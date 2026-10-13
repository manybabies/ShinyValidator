library(testthat)

app_dir <- normalizePath(test_path("..", ".."))
source(file.path(app_dir, "common.R"))

fx <- function(...) test_path("fixtures", ...)

make_field <- function(...) {
  modifyList(
    list(
      field = "x", type = "string", format = "open",
      required = TRUE, NA_allowed = FALSE, empty_allowed = FALSE
    ),
    list(...)
  )
}

col <- function(x) data.frame(x = x, stringsAsFactors = FALSE)

bad_rows <- function(res) if (res[[1]]) integer(0) else res[[2]]$invalid_row

write_tmp <- function(lines, ext = ".csv") {
  p <- tempfile(fileext = ext)
  writeLines(lines, p)
  p
}

has_yellow_fill <- function(xlsx_path) {
  d <- tempfile()
  dir.create(d)
  utils::unzip(xlsx_path, files = "xl/styles.xml", exdir = d)
  any(grepl("FFFFFF00", readLines(file.path(d, "xl/styles.xml"), warn = FALSE),
            ignore.case = TRUE))
}