# Changelog

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
