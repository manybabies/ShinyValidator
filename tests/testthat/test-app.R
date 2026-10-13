skip_on_cran()
skip_if_not_installed("shinytest2")

# A fixed key so the app never writes a .Renviron during testing
withr::local_envvar(VALIDATOR_SECRET_KEY = strrep("ab", 32))

new_app <- function(name) {
  app <- shinytest2::AppDriver$new(app_dir, name = name, load_timeout = 60000,
                                   width = 1300, height = 900)
  withr::defer(app$stop(), envir = parent.frame())
  app
}

visible <- function(app, id) {
  isTRUE(app$get_js(sprintf(
    "(function(){var e=document.getElementById('%s');return !!e && e.offsetParent!==null;})()", id)))
}

use_local_spec <- function(app, path = fx("spec_basic.yaml")) {
  app$set_inputs(specification_source = "local")
  app$upload_file(local_specification = path)
}

summary_text <- function(app) app$get_text("#errors_by_column .validation-summary")

text_of <- function(app, id) {
  app$wait_for_idle()
  app$get_js(sprintf(
    "(document.getElementById('%s') || {textContent: ''}).textContent.trim()", id))
}

# Startup and configuration ---------------------------------------------------------------

test_that("app boots with the default configuration and no R errors", {
  app <- new_app("boot")
  default <- yaml::read_yaml(file.path(app_dir, "configuration", "config_Default.yaml"))
  app$wait_for_js(
    "document.getElementById('app_title') && document.getElementById('app_title').textContent.trim().length > 0",
    timeout = 20000
  )
  expect_equal(text_of(app, "app_title"), default$app_title)
  expect_true(app$get_js("document.body.classList.contains('text-size-default')"))
  logs <- app$get_logs()
  expect_false(any(grepl("Error", logs$message[logs$location == "shiny"])))
})

test_that("uploaded configuration: title, theme, safe links only", {
  app <- new_app("config-upload")
  app$set_inputs(configuration_source = "local")
  app$upload_file(local_configuration = fx("config_custom.yaml"))
  expect_equal(trimws(app$get_text("#app_title")), "Custom Validator")
  expect_true(app$get_js("document.body.classList.contains('theme-purple')"))
  hrefs <- unlist(app$get_js(
    "Array.from(document.querySelectorAll('.content-card a[target=_blank]')).map(a => a.href)"))
  expect_true("https://example.org/" %in% hrefs)
  expect_false(any(grepl("^javascript:", hrefs, ignore.case = TRUE)))
  
  # Regression: opening Configuration Creation must not reset the theme to blue
  app$set_inputs(page = "configuration_creation")
  app$wait_for_idle()
  expect_equal(app$get_value(input = "config_theme"), "purple")
  expect_true(app$get_js("document.body.classList.contains('theme-purple')"))
})

test_that("configuration creation: theme preview, live heading, download round trip", {
  app <- new_app("config-create")
  step <- function(...) { app$set_inputs(...); app$wait_for_idle() }
  
  step(page = "configuration_creation")
  
  step(config_theme = "teal")
  expect_true(app$get_js("document.body.classList.contains('theme-teal')"))
  
  step(config_app_title = "Round Trip Validator")
  step(enable_links = TRUE)
  step(num_links = 2)
  step(config_link_text_1 = "Docs", config_link_url_1 = "https://example.org/docs")
  
  app$run_js("var e=document.getElementById('config_instruction_set_1_name');
              e.value='Hello'; e.dispatchEvent(new Event('input',{bubbles:true}));")
  app$wait_for_idle()
  expect_equal(text_of(app, "instruction_set_1_creation_heading"), "Hello")
  
  path <- app$get_download("downloadConfiguration")
  cfg <- yaml::read_yaml(path)
  expect_equal(cfg$theme, "teal")
  expect_equal(cfg$app_title, "Round Trip Validator")
  expect_equal(cfg$links[[1]]$url, "https://example.org/docs")
  
  # The downloaded file loads back as a local configuration
  step(configuration_source = "local")
  app$upload_file(local_configuration = path)
  expect_equal(text_of(app, "app_title"), "Round Trip Validator")
})

# Specification page ----------------------------------------------------------------------

test_that("uploaded specification is shown and the codebook is correct", {
  app <- new_app("spec")
  use_local_spec(app)
  expect_match(app$get_text("#local_specification_status"), "Specification loaded")
  
  app$set_inputs(page = "specification")
  txt <- text_of(app, "specification")
  expect_match(txt, "participant_id")
  expect_match(txt, "\\^P\\[0-9\\]\\+\\$")
  
  cb <- openxlsx::read.xlsx(app$get_download("downloadCodebook"))
  expect_equal(nrow(cb), 5)
  rules <- cb$Validation.requirements
  expect_match(rules[cb$Variable == "age"], "between 0 and 120")
  expect_false(any(grepl("\\bNA\\b", rules)))
})

test_that("bad specification files give a clear message", {
  app <- new_app("spec-bad")
  app$set_inputs(specification_source = "local")
  app$upload_file(local_specification = write_tmp("- field: x\n  type: [unclosed", ".yaml"))
  expect_match(app$get_text("#local_specification_status"), "Unable to load")
  app$upload_file(local_specification = write_tmp(c("- just", "- strings"), ".yaml"))
  expect_match(app$get_text("#local_specification_status"), "Unable to load")
})

# Validation workflow ---------------------------------------------------------------------

test_that("valid dataset: success summary and CSV button visible", {
  app <- new_app("valid")
  use_local_spec(app)
  app$upload_file(file = fx("valid.csv"))
  expect_match(summary_text(app), "No issues found")
  expect_true(visible(app, "downloadCSV"))
})

test_that("invalid dataset: counts, views, hidden CSV button, Excel highlights", {
  app <- new_app("invalid")
  use_local_spec(app)
  app$upload_file(file = fx("invalid.csv"))
  
  txt <- summary_text(app)
  expect_match(txt, "6 issues found")
  expect_match(txt, "Rows affected:\\s*2")
  expect_match(txt, "Unexpected columns:\\s*1")
  expect_false(visible(app, "downloadCSV"))
  
  app$set_inputs(error_view = "row")
  expect_match(app$get_text(".validation-errors-table"), "Row 1")
  app$set_inputs(error_view = "column")
  expect_match(app$get_text(".validation-errors-table"), "Column age")
  
  xlsx <- app$get_download("downloadHighlighted")
  expect_true("Validated Dataset" %in% openxlsx::getSheetNames(xlsx))
  expect_true(has_yellow_fill(xlsx))
})

test_that("editing a bad cell makes the dataset valid", {
  app <- new_app("edit")
  use_local_spec(app)
  app$upload_file(file = fx("one_bad.csv"))
  expect_match(summary_text(app), "1 issue found")
  # DT sends zero-based columns; adjust if your DT version differs
  app$set_inputs(validation_preview_cell_edit = list(row = 1, col = 0, value = "P1"),
                 allow_no_input_binding_ = TRUE, priority_ = "event")
  expect_match(summary_text(app), "No issues found")
  expect_true(visible(app, "downloadCSV"))
})

test_that("sample dataset passes the specification it came from", {
  app <- new_app("sample")
  use_local_spec(app)
  df <- readr::read_csv(app$get_download("downloadSampleDataset"),
                        col_types = readr::cols(.default = "c"), na = "NA")
  fields <- read_yaml_safe(fx("spec_basic.yaml"))
  expect_true(validate_dataset(fields, as.data.frame(df))$valid)
})

test_that("certified CSV: Lab ID flow works, and invalid data is refused by the server", {
  app <- new_app("certified")
  step <- function(...) { app$set_inputs(...); app$wait_for_idle() }
  has <- function(id) isTRUE(app$get_js(sprintf("!!document.getElementById('%s')", id)))
  click_confirm <- function() {
    if (has("confirm_download")) app$click("confirm_download")
    app$wait_for_idle()
  }
  
  use_local_spec(app)
  app$upload_file(file = fx("valid.csv"))
  app$wait_for_idle()
  app$click("downloadCSV")
  app$wait_for_idle()
  
  # An invalid Lab ID must not produce a download
  step(download_lab_id = "bad id!")
  click_confirm()
  expect_false(visible(app, "downloadCSV_confirmed"))
  
  # A valid Lab ID does
  step(download_lab_id = "lab-1")
  click_confirm()
  path <- app$get_download("downloadCSV_confirmed")
  got  <- readr::read_csv(path, col_types = readr::cols(.default = "c"), na = "NA")
  want <- readr::read_csv(fx("valid.csv"), col_types = readr::cols(.default = "c"), na = "NA")
  expect_equal(as.data.frame(got), as.data.frame(want))
  
  # The button is hidden for invalid data, but the server must also refuse
  app$upload_file(file = fx("invalid.csv"))
  app$wait_for_idle()
  app$run_js("Shiny.setInputValue('downloadCSV', Math.random(), {priority: 'event'})")
  app$wait_for_idle()
  step(download_lab_id = "lab-1")
  click_confirm()
  expect_error(app$get_download("downloadCSV_confirmed"))
})

# Bad input -------------------------------------------------------------------------------

test_that("garbage uploads show a message and do not end the session", {
  app <- new_app("garbage")
  use_local_spec(app)
  
  junk <- tempfile(fileext = ".csv"); writeBin(as.raw(c(0:255, 0:255)), junk)
  app$upload_file(file = junk)
  expect_gt(app$get_js("document.querySelectorAll('.shiny-notification').length"), 0)
  
  empty <- tempfile(fileext = ".csv"); file.create(empty)
  app$upload_file(file = empty)
  
  app$upload_file(file = fx("valid.csv"))                    # session still works
  expect_match(summary_text(app), "No issues found")
})

test_that("tampered input values cannot read arbitrary files", {
  app <- new_app("traversal")
  app$run_js("Shiny.setInputValue('configuration', '../data_specifications/anything.yaml')")
  expect_equal(trimws(app$get_text("#app_title")), "")       # nothing loaded
  app$run_js("Shiny.setInputValue('specification_source', 'bundled');
              Shiny.setInputValue('study', '..'); Shiny.setInputValue('format', '..')")
  expect_false(any(grepl("Error", app$get_logs()$message)))
})

test_that("dataset values never appear in the server log", {
  app <- new_app("privacy")
  use_local_spec(app)
  p <- write_tmp(c("participant_id,age,score,group,notes",
                   "P1,30,1.00,control,SENTINEL_VALUE_123"))
  app$upload_file(file = p)
  app$get_download("downloadHighlighted")
  expect_false(any(grepl("SENTINEL_VALUE_123", app$get_logs()$message)))
})

# Specification builder -------------------------------------------------------------------

test_that("specification builder: build, validate input, download, reuse", {
  app <- new_app("builder")
  step <- function(...) { app$set_inputs(...); app$wait_for_idle() }
  
  step(page = "specification_creation")
  step(numVars = 2)
  step(field_name_1 = "age", field_type_1 = "numeric",
       field_name_2 = "grp", field_type_2 = "options")
  step(num_options_2 = "2", option_1_2 = "a", option_2_2 = "b")
  expect_true(visible(app, "downloadSetup"))
  
  spec_path <- app$get_download("downloadSetup")
  fields <- read_yaml_safe(spec_path)
  expect_equal(length(fields), 2)
  expect_equal(vapply(fields, function(x) x$field, ""), c("age", "grp"))
  expect_true(validate_dataset(fields, data.frame(age = "5", grp = "a",
                                                  stringsAsFactors = FALSE))$valid)
  expect_false(validate_dataset(fields, data.frame(age = "5", grp = "z",
                                                   stringsAsFactors = FALSE))$valid)
  
  # Duplicate names disable the download with a message
  step(field_name_2 = "age")
  expect_match(text_of(app, "downloadSetupButton"), "must be unique")
  expect_false(visible(app, "downloadSetup"))
})

test_that("'match example values' needs a recognisable pattern", {
  app <- new_app("examples")
  step <- function(...) { app$set_inputs(...); app$wait_for_idle() }
  
  step(page = "specification_creation")
  step(numVars = 1)
  step(field_name_1 = "code", field_type_1 = "string")
  step(string_validation_1 = "examples")
  step(example_1_1 = "ID1", example_2_1 = "ID2", example_3_1 = "ID3",
       example_4_1 = "ID4", example_5_1 = "ID5")
  expect_true(visible(app, "downloadSetup"))
  
  step(example_1_1 = "abc", example_2_1 = "x-9", example_3_1 = "Q",
       example_4_1 = "!!", example_5_1 = "7z")
  expect_match(text_of(app, "downloadSetupButton"), "recognisable pattern")
  expect_false(visible(app, "downloadSetup"))
})

# Verify certified file ---------------------------------------------------------------------

test_that("verify page: untouched file verifies, edited file does not", {
  app <- new_app("verify")
  step <- function(...) { app$set_inputs(...); app$wait_for_idle() }
  has <- function(id) isTRUE(app$get_js(sprintf("!!document.getElementById('%s')", id)))
  
  # Make a certified file
  use_local_spec(app)
  app$upload_file(file = fx("valid.csv"))
  app$wait_for_idle()
  app$click("downloadCSV")
  app$wait_for_idle()
  step(download_lab_id = "lab-1")
  if (has("confirm_download")) app$click("confirm_download")
  app$wait_for_idle()
  path <- app$get_download("downloadCSV_confirmed")
  
  # The untouched file verifies (the study name contains an underscore,
  # so the page cannot guess study/format and they are entered by hand)
  step(page = "verify_certified")
  app$upload_file(verify_file = path)
  app$wait_for_idle()
  step(verify_study = "spec_basic", verify_format = "local")
  app$click("verify_button")
  app$wait_for_idle()
  expect_match(text_of(app, "verify_result"), "✓ Verified")
  
  # The wrong Lab ID does not
  step(verify_lab_id = "lab-2")
  app$click("verify_button")
  app$wait_for_idle()
  expect_match(text_of(app, "verify_result"), "Not verified")
  
  # An edited copy with the same file name does not
  bad_dir <- tempfile(); dir.create(bad_dir)
  bad_path <- file.path(bad_dir, basename(path))
  x <- readLines(path, warn = FALSE)
  x[2] <- sub("34", "35", x[2], fixed = TRUE)
  writeLines(x, bad_path)
  
  app$upload_file(verify_file = bad_path)
  app$wait_for_idle()
  step(verify_study = "spec_basic", verify_format = "local")
  app$click("verify_button")
  app$wait_for_idle()
  expect_match(text_of(app, "verify_result"), "Not verified")
  
  # A file that was not certified is explained
  app$upload_file(verify_file = fx("valid.csv"))
  app$wait_for_idle()
  expect_match(text_of(app, "verify_fields"), "Not a certified file")
})

# Suggested fixes ---------------------------------------------------------------------------

test_that("suggested fixes: nothing changes until approved; apply, undo and change log", {
  app <- new_app("fixes")
  
  use_local_spec(app)
  app$upload_file(file = fx("fixable.csv"))
  app$wait_for_idle()
  
  # Proposals are shown but nothing has been changed
  expect_match(text_of(app, "errors_by_column"), "2 issues found")
  expect_match(text_of(app, "suggested_fixes_panel"), "2 changes can be made")
  
  # Approve everything
  app$click("select_all_fixes")
  app$wait_for_idle()
  app$click("apply_fixes")
  app$wait_for_idle()
  expect_match(text_of(app, "errors_by_column"), "No issues found")
  expect_match(text_of(app, "suggested_fixes_panel"), "change log \\(2\\)")
  
  # The Excel report carries the change log
  sheets <- openxlsx::getSheetNames(app$get_download("downloadHighlighted"))
  expect_true("Change Log" %in% sheets)
  
  # Undo brings the errors back and is itself logged
  app$click("undo_fixes")
  app$wait_for_idle()
  expect_match(text_of(app, "errors_by_column"), "2 issues found")
  expect_match(text_of(app, "suggested_fixes_panel"), "change log \\(4\\)")
})

test_that("suggested fixes: applying with nothing selected changes nothing", {
  app <- new_app("fixes-none")
  
  use_local_spec(app)
  app$upload_file(file = fx("fixable.csv"))
  app$wait_for_idle()
  
  app$click("apply_fixes")
  app$wait_for_idle()
  expect_match(text_of(app, "errors_by_column"), "2 issues found")
})

test_that("suggested fixes: a configuration can switch them off", {
  app <- new_app("fixes-off")
  
  cfg <- c(readLines(fx("config_custom.yaml"), warn = FALSE), "allow_suggested_fixes: no")
  app$set_inputs(configuration_source = "local")
  app$upload_file(local_configuration = write_tmp(cfg, ".yaml"))
  app$wait_for_idle()
  
  use_local_spec(app)
  app$upload_file(file = fx("fixable.csv"))
  app$wait_for_idle()
  
  expect_match(text_of(app, "errors_by_column"), "2 issues found")
  expect_equal(text_of(app, "suggested_fixes_panel"), "")
})

test_that("suggested fixes: Select all skips the 'check this one' fixes", {
  app <- new_app("fixes-check")
  
  use_local_spec(app, fx("spec_fixes.yaml"))
  app$upload_file(file = fx("mixed.csv"))
  app$wait_for_idle()
  
  panel <- text_of(app, "suggested_fixes_panel")
  expect_match(panel, "4 changes can be made")
  expect_match(panel, "Check this one")
  expect_match(panel, "Select all safe fixes")
  
  # Select all picks only the two safe fixes
  app$click("select_all_fixes")
  app$wait_for_idle()
  app$click("apply_fixes")
  app$wait_for_idle()
  expect_match(text_of(app, "errors_by_column"), "2 issues found")
  
  # The two judgement calls stay until the person ticks them
  app$run_js("Shiny.setInputValue('suggested_fixes_table_rows_selected', [1, 2], {priority: 'event'})")
  app$wait_for_idle()
  app$click("apply_fixes")
  app$wait_for_idle()
  expect_match(text_of(app, "errors_by_column"), "No issues found")
})