# Changelog

## [2.1.0] - 2026-10-13

### Added

- Added: Verify Certified File function, which lets an admin or data processor upload a certified CSV and check against the server's secret key that it passed validation and has not been changed since
- Added: Automated test suite (`tests/`), covering the validation rules, security checks, bundled specifications and configurations, certified file signing and verification, and the running app

### Changed

- Changed: `server.R` renamed to `app_server.R`, so the project folder is no longer ambiguous between the `app.R` and `server.R` launch styles
- Changed: The signing function for certified files moved to `common.R` and is shared by the download and the new verification. The file name format and codes are unchanged, so previously certified files still verify
- Changed: Stricter, more predictable validation. A field with no `required` setting is now treated as required; missing `NA_allowed` or `empty_allowed` settings mean not allowed; numeric values must be plain numbers; a value without a decimal point fails when decimal places are required; a regular-expression field with a missing or invalid pattern now gives an error instead of passing silently
- Changed: Darker error text colour for better contrast
- Removed: Unused `shinythemes` dependency

### Security

- YAML files are now read without evaluating code, with a 1 MB size limit
- The selected configuration, study and format are checked against files that actually exist before any file is opened
- Configuration links are only shown if they use `http://` or `https://`, and open with `rel="noopener noreferrer"`
- The server re-checks the Lab ID and that the dataset passes validation at the moment of a certified download, instead of relying on the button being hidden
- Dataset values are no longer printed to the server log
- Uploads are limited to 50 MB, and unreadable dataset, specification or configuration files now show a message instead of ending the session

### Fixed

- Fixed: Codebook now uses the correct range limits, string lengths and wording, and no longer prints "NA" as a pattern
- Fixed: Generate sample dataset now respects numeric limits and decimal places, capitalization, and string lengths, and reports a clear message when example values have no recognisable pattern
- Fixed: Decimal-place checks for numeric fields

## [2.0.7] - 2026-10-06

- Removed: Custom logo functions; currently deprecated, fix impending
- Added: Local YAML configuration and specification function, which allows users to upload and use a local .yaml through the live version of the app

## [2.0.6] - 2026-09-22

- Fixed: Empty and NA were not being differentiated

## [2.0.5] - 2026-09-18

- Added: auto file name generation for downloading validated csv file
- Added: authentication code to validated csv file names
- Added: server-side only secret key to check authenticity of code
- This added function ensures that submitted files have passed validation, and have not been tampered post-validation

## [2.0.4] - 2026-09-17

- Fix: issue where NA values were being replaced with blank cells
- Fix: Cells not being properly highlighted under some conditions
- Added: Option in "Specification Creation" to upload a template dataset (only variable name extracted)
- Added: Option to delete variables in "Specification Creation"
- Added: Generate sample dataset function

## [2.0.3] - 2026-09-15

- Improved robustness; validator now accepts different delimiters and European decimal system
- Differentiated between "Download Highlighted Excel File" and "Download Validated CSV File"

## [2.0.2] - 2026-09-14

- Added feature: custom logo and associated upload functions

## [2.0.1] - 2026-09-13

### Added

- Added feature: Editable data table display and downloadable edited dataset
- Added text-size accessibility controls.
- Added Error Summary view.
- Various bug fixes to improve overall robustness

## [2.0.0] - 2026-09-11

### Added

- Added Specification Creation functionality.
- Added Configuration Creation functionality.
- Added customizable project configurations.
- Added Errors by Row, and Errors by Column views.
- Added improved validation messages and user interface styling.