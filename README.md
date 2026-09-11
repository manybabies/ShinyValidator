# ShinyValidator

ShinyValidator is a customizable tool for checking research datasets against predefined data specifications. Upload a CSV to identify common data-entry errors, such as missing columns, invalid values, and formatting issues, and download a highlighted Excel file to help locate and correct them.

ShinyValidator is designed as a template that can be adapted to the requirements of your own project. Importantly, this tool was designed to *minimize the need to interface with R*, such that users with minimal R knowledge can nonetheless adapt the tool with ease.

Fork or download this repository to customize for your project needs, and use as an app locally or deploy via the `rsconnect` package. You can find a live version of this template [here](https://manybabies.shinyapps.io/shinyvalidator/).

## Components of this repo

This documentation is divided into three sections:

1. **Primary Functions** — how to use the validator.
2. **Adapting the Validator** — how to customize the validator for your project.
3. **Back-end Developer Documentation** — how the validator works and how to modify its code.

If you are simply creating a validator for your own project, you only need **Sections 1 and 2**.

---

# 1. Primary Functions

<details>
<summary><strong>Requirements</strong></summary>

To run the validator locally, you will need:

* **R** (version 4.6.0 or later)
* **RStudio**

The following R packages are required:

* `tidyverse`
* `shiny`
* `shinythemes`
* `DT`
* `openxlsx`
* `yaml`

If you want to deploy the validator to `shinyapps.io`, you will also need `rsconnect`.

</details>

<details>
<summary><strong>Using the validator</strong></summary>

The basic version of the validator is straightforward to use:

1. **Select a study** from the *Study* drop-down menu.

2. **Select a format** from the *Study Format* drop-down menu.

3. **Upload your dataset** by clicking *Browse* and selecting the `.csv` file you want to validate.

4. **Review the validation results.** The validator will indicate whether your dataset is valid. If errors are found, you can choose to view them by **column** or **row**.

5. **Download a highlighted file** by clicking *Download Highlighted File*. This produces an Excel file with invalid cells highlighted and an **Error Log** describing the detected errors.

</details>

<details>
<summary><strong>Data types that the validator can check</strong></summary>

The validator can check:

* **Required columns** — whether all required variables are present.
* **Options** — whether values match a predefined list of allowed values.
* **Numeric values** — whether values are numeric and meet specified range and decimal requirements.
* **Strings** — whether text meets specified capitalization and character-length requirements.
* **Regular expressions** — whether values follow a specified pattern.

The specific checks performed depend on the data specification.

</details>

<details>
<summary><strong>Creating your own validator</strong></summary>

ShinyValidator is designed as a template. You can create a validator for your own project by:

1. Customizing the instructions and other user-facing content.
2. Creating a data specification using the **Specification Creation** tab.
3. Adding the resulting specification to the validator.
4. Testing the validator with your own datasets.

> **Try it out:** Launch the validator and try out the built-in Demo specification. In your extracted RProject, there is a "sample_datasets" folder containing a valid and an invalid dataset. Run those through the validator to see what the output looks like before moving on.

See **Section 2: Adapting the Validator** for step-by-step instructions.

</details>

---

# 2. Adapting the Validator

This section provides a step-by-step guide for adapting the validator template for your own project. Before proceeding with this section, please make sure you have everything in the Requirements section above installed.

<details>
<summary><strong>2.1 Downloading the validator</strong></summary>

The first step is to download the validator from the repository.

Click **Code → Download ZIP** to download the repository as a `.zip` file, then extract it using any file compression program.

![](images/step_2.1.png)

</details>

<details>
<summary><strong>2.2 Running the validator locally</strong></summary>

The quickest way to get your validator running is to run it locally.

Open the R Project file `ShinyValidator.Rproj`. Then open `app.R` and click **Run App**.

![](images/step_2.2.png)

Note that the exact location of these buttons may differ depending on your console setup. You may be prompted to install any required packages that are not already installed.

The template version of the validator should open in a new window. You can use this version to create and test your customized data specifications.

</details>

<details>
<summary><strong>2.3 Customizing the GUI</strong></summary>

The validator contains several stand-in messages and instructions that can be customized for your project.

These can be changed directly in `ui.R`. The table below shows where the main parts of the user interface are defined.

| Part of the interface          | Where to look in `ui.R`                                      | What you can change                                           |
| ------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------- |
| **Validation Results tab**     | `tabPanel("Validation Results", ...)`                        | Tab name and contents                                         |
| **Welcome/instruction text**   | `h3()`, `p()`, and `HTML()` elements near the top of the tab | Instructions, descriptions, links, and other user-facing text |
| **Study drop-down**            | `selectInput("study", ...)`                                  | Label and instructions for selecting a study                  |
| **Study Format drop-down**     | `selectInput("format", ...)`                                 | Label and instructions for selecting a format                 |
| **CSV upload**                 | `fileInput("file", ...)`                                     | Upload instructions and accepted file types                   |
| **Error display options**      | `radioButtons(...)`                                          | Labels and choices for viewing errors by column or row        |
| **Validation preview**         | `DTOutput(...)`                                              | Placement and surrounding instructions for the preview table  |
| **Highlighted file download**  | `downloadButton(...)`                                        | Button label and surrounding instructions                     |
| **Specification Creation tab** | `tabPanel("Specification Creation", ...)`                    | Tab name and specification-creation instructions              |
| **Specification tab**          | `tabPanel("Specification", ...)`                             | Tab name and specification display                            |

The exact line numbers may change as you customize the application, so it is better to use the element names above to locate the relevant section of `ui.R`.

You can also modify the layout and add additional elements if you are familiar with Shiny and Markdown.

> **Tip:** For most projects, you only need to change the user-facing text. You do not need to modify the underlying code.

</details>

<details>
<summary><strong>2.4 Creating your data specification</strong></summary>

The next step is to specify what columns your dataset must contain and what values are allowed for each column.

Data specifications are stored as `.yaml` files in the `data_specifications` folder. However, **you do not need to write the YAML code yourself**.

Instead, open the validator and navigate to the **Specification Creation** tab.

Enter the number of variables you want to include in your specification. The validator will then generate fields for you to define each variable.

> **Important:** You can change the number of variables at any time, but decreasing the number of variables will erase some of your progress (e.g. going from 10 down to 9 will erase variable 10 permanently).

There are three main variable types:

* **Options** — values must match one of a predefined set of options.
* **Numeric** — values must be numeric and can optionally be restricted by range and decimal requirements.
* **String** — values can be open-ended but can be restricted by capitalization, character length, or a regular expression.

<details>
<summary><strong>Options</strong></summary>

Use **Options** when you want to specify exactly which values are allowed.

For example, a `color` variable could allow only:

* `red`
* `yellow`
* `blue`

</details>

<details>
<summary><strong>Numeric</strong></summary>

Use **Numeric** when a variable should contain numbers.

You can optionally specify:

* a minimum value;
* a maximum value;
* whether decimal values are allowed; and
* the minimum and maximum number of decimal places.

For example, a `reaction_time_ms` variable could be restricted to values between `300` and `10000`.

</details>

<details>
<summary><strong>String</strong></summary>

Use **String** when a variable contains open-ended text.

You can optionally restrict:

* capitalization;
* minimum character length; and
* maximum character length.

You can also use examples to generate a regular-expression-based restriction for variables that follow a consistent pattern.

</details>

</details>

<details>
<summary><strong>2.5 Adding your data specification</strong></summary>

Once you have finished defining your variables, click **Download Setup** to download your `.yaml` specification.

Move the downloaded file into the `data_specifications` folder.

Rename the file using the following format:

```text
studyname_formatname.yaml
```

For example:

```text
FishSpeed_RawData.yaml
```

would create a study called `FishSpeed` with a format called `RawData`.

> **Important:** The filename must not contain spaces or special characters. Use capitalization to separate words.

After adding the file, relaunch the application. Your new study and format should now appear in the appropriate drop-down menus.

</details>

<details>
<summary><strong>2.6 Testing your specification</strong></summary>

Before using your validator with real datasets, test your new specification with a small sample dataset.

Ideally, create a `.csv` file containing:

* at least one row with completely valid data; and
* several rows containing errors that you expect the validator to detect.

Upload this dataset to the validator and check that the expected errors are identified.

You can also click **Download Highlighted File** to create an Excel version of the dataset with invalid cells highlighted.

</details>

<details>
<summary><strong>2.7 Making manual adjustments</strong></summary>

If you discover that your specification needs to be changed after testing, you can either recreate it using the **Specification Creation** tab or edit the `.yaml` file directly.

The `.yaml` file contains the same information as the Specification Creation interface, but in a format that can be edited manually.

For most users, the **Specification Creation** tab is the easiest way to make changes.

Once your validator is working as expected, you can use it locally or deploy it online using `shinyapps.io`.

</details>

---

# 3. Back-end Developer Documentation

The **Back-end Developer Documentation** provides detailed information about the underlying code of the validator.

This section is intended for researchers and developers who wish to add new functions, modify existing functionality, or otherwise customize the validator beyond the options described in Section 2.

<details>
<summary><strong>3.1 Application architecture</strong></summary>

The validator is organized across five primary R files:

| File             | Purpose                                       |
| ---------------- | --------------------------------------------- |
| `app.R`          | Application initialization and launch         |
| `ui.R`           | User interface and layout                     |
| `server.R`       | Server-side application logic                 |
| `common.R`       | Shared functions and validation functions     |
| `ErrorHandler.R` | Error handling and downloadable error reports |

The validator also relies on `.yaml` files stored in the `data_specifications` folder to define study-specific data requirements.

</details>

<details>
<summary><strong>3.2 app.R</strong></summary>

`app.R` is the entry point for the Shiny application. It:

1. Loads the core packages needed to launch the application.
2. Sources `ui.R` and `server.R`.
3. Launches the application with `shinyApp()`.

The file generally does not need to be modified when adapting the validator. If additional R files are added, they should generally be sourced from the appropriate component file rather than directly from `app.R`.

</details>

<details>
<summary><strong>3.3 ui.R</strong></summary>

`ui.R` defines the application's user interface.

The main interface contains three tabs:

* **Validation Results** — study/format selection, CSV upload, error display options, validation preview, and highlighted-file download.
* **Specification Creation** — allows users to create a YAML specification by defining the number and properties of variables.
* **Specification** — displays the human-readable specification for the selected study and format.

### Customizing the UI

User-facing text, instructions, links, and the overall layout can be modified directly in `ui.R`. The welcome messages in the **Validation Results** tab are intended to be replaced with project-specific instructions.

The application uses `shinythemes` for the visual theme and `DT` for the validation preview table.

A small JavaScript component automatically updates specification tab labels as variable names are entered. This should generally be left unchanged unless the specification-creation interface is modified.

</details>

<details>
<summary><strong>3.4 server.R</strong></summary>

`server.R` contains the server-side logic for the application. It connects the UI inputs to the validation functions in `common.R` and generates the application's outputs.

### Main components

* **Study and format selection** — dynamically updates the available study formats based on the selected study.
* **Specification display** — loads the selected YAML file and displays its requirements.
* **Validation errors** — validates the uploaded dataset and displays errors by column or row.
* **Specification creation** — collects the user's variable settings and converts them into a YAML-compatible structure.
* **Specification download** — generates and downloads the user-created YAML specification.
* **Variable tabs** — dynamically creates and removes tabs based on the requested number of variables.
* **Option and example inputs** — generates additional inputs for option values and example-based string validation.
* **Highlighted dataset download** — validates the uploaded dataset and creates an Excel file highlighting invalid cells.
* **Validation preview** — displays the uploaded dataset and highlights invalid cells in the table.

### Validation workflow

The main validation outputs follow this general workflow:

1. Load the YAML specification corresponding to the selected study and format.
2. Read the uploaded CSV dataset.
3. Pass the specification and dataset to `validate_dataset()` in `common.R`.
4. Process the returned issues.
5. Display the results or generate the highlighted Excel file.

</details>

<details>
<summary><strong>3.5 common.R</strong></summary>

`common.R` contains the core data-validation functions used by the application. It also identifies available study/format combinations and generates user-facing explanations for validation errors.

### Study and format discovery

The `studies` object is generated automatically by reading `.yaml` files from the `data_specifications` folder. Filenames are split at the underscore to identify the study and format.

For example:

```text
FishSpeed_RawData.yaml
```

is interpreted as:

| study     | format  |
| --------- | ------- |
| FishSpeed | RawData |

Therefore, adding a correctly named YAML file to `data_specifications` automatically makes the study/format available to the application.

### Dataset validation

`validate_dataset()` is the main validation function. It:

1. Checks that all required columns are present.
2. Passes each existing field to `validate_dataset_field()`.
3. Collects any validation issues.
4. Returns whether the dataset is valid and, if not, a list of issues.

`validate_dataset_field()` determines which validation function should be used based on the field specification:

| Field type | Validation function                     |
| ---------- | --------------------------------------- |
| `options`  | `ValidateOption()`                      |
| `numeric`  | `ValidateNumeric()`                     |
| `string`   | `ValidateString()` or `ValidateRegex()` |

### Validation functions

The individual validation functions perform the following checks:

* **`ValidateOption()`** — checks whether values match one of the allowed options.
* **`ValidateNumeric()`** — checks numeric values, ranges, decimal restrictions, and decimal places.
* **`ValidateString()`** — checks capitalization and character-length restrictions.
* **`ValidateRegex()`** — checks values against a specified regular expression.
* **`GenerateRegex()`** — generates a regular expression from compatible example values.

All validation functions return the same basic structure:

```r
list(TRUE, NULL)
```

when the field is valid, or:

```r
list(FALSE, issue)
```

when an error is detected.

Issues contain information such as the error type, column, invalid value, and row number. This standardized structure allows the server and error-handling components to process validation errors consistently.

### Error explanations

`explain_error()` converts validation issues into user-facing explanations. It uses the field specification to describe the relevant requirement, while allowing individual fields to provide a custom `error_message`.

### Developer notes

When adding a new validation function, maintain the existing return structure and include the affected column and row information in the issue object.

If adding a new field type, update `validate_dataset_field()` so that the new type is routed to the appropriate validation function.

</details>

<details>
<summary><strong>3.6 ErrorHandler.R</strong></summary>

`ErrorHandler.R` contains the function used to generate the downloadable Excel validation report.

### `highlight_csv_to_xlsx()`

`highlight_csv_to_xlsx()` takes the uploaded dataset and the validation issues returned by `validate_dataset()` and creates an Excel workbook containing:

* **Data** — the original dataset, with invalid cells highlighted.
* **Error Log** — a record of missing columns and invalid cells, including the row, column, and invalid value where applicable.

Missing columns are recorded in the error log but cannot be highlighted in the dataset because the column does not exist.

The function returns an `openxlsx` workbook object, which is saved by the download handler in `server.R`.

### Developer notes

If new issue types are added to `common.R`, update `highlight_csv_to_xlsx()` if those issues should appear in the downloadable error report.

</details>
