root <- normalizePath(test_path("..", ".."))

yaml_files <- function(dir) {
  list.files(file.path(root, dir), pattern = "\\.ya?ml$",
             recursive = TRUE, full.names = TRUE)
}

load_yaml <- function(f) suppressWarnings(read_yaml_safe(f))

# Collect every list that looks like a field definition (has `field` and `type`)
collect_fields <- function(x) {
  out <- list()
  if (is.list(x)) {
    if (!is.null(names(x)) && all(c("field", "type") %in% names(x))) {
      out <- c(out, list(x))
    }
    for (el in x) out <- c(out, collect_fields(el))
  }
  out
}

as_num <- function(v) {
  if (is.null(v) || length(v) != 1) return(NA_real_)
  suppressWarnings(as.numeric(v))
}

spec_files   <- yaml_files("data_specifications")
config_files <- yaml_files("configuration")

test_that("bundled specification and configuration files are found", {
  expect_gt(length(spec_files), 0)
  expect_gt(length(config_files), 0)
})

for (f in spec_files) {
  test_that(paste("specification is valid:", basename(f)), {
    spec <- load_yaml(f)
    expect_true(is.list(spec))
    
    fields <- collect_fields(spec)
    expect_gt(length(fields), 0)
    
    for (fl in fields) {
      label <- paste(basename(f), "/", fl$field)
      expect_true(is.character(fl$field) && nzchar(fl$field), info = label)
      expect_true(fl$type %in% c("options", "numeric", "string"), info = label)
      
      if (identical(fl$format, "regex")) {
        expect_true(!is.null(fl$pattern) && !is.na(fl$pattern), info = label)
        ok <- tryCatch({ grepl(fl$pattern, "x", perl = TRUE); TRUE },
                       error = function(e) FALSE, warning = function(w) FALSE)
        expect_true(ok, info = paste("pattern compiles:", label))
      }
      
      lo <- as_num(fl$lowerlimit)
      hi <- as_num(fl$upperlimit)
      if (!is.na(lo) && !is.na(hi)) {
        expect_true(lo <= hi, info = paste("lowerlimit <= upperlimit:", label))
      }
    }
  })
}

for (f in config_files) {
  test_that(paste("configuration is valid:", basename(f)), {
    cfg <- load_yaml(f)
    expect_true(is.list(cfg))
    if (!is.null(cfg$theme)) {
      expect_true(cfg$theme %in% c("blue", "purple", "teal"))
    }
  })
}