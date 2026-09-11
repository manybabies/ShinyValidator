# ShinyValidator

Template GUI to validate datasets. Fork this template to customize for your project needs, and use as an app locally or deploy via the `rsconnect` package. You can find a live version of this template [here](https://manybabies.shinyapps.io/shinyvalidator/).

## Components of this repo

This documentation is divided into three main sections:

1. **Primary Functions** — describes the main functions of the validator and provides a brief guide on how to use it.
2. **Adapting the Validator** — provides a step-by-step guide for adapting the basic validator for your own projects.
3. **Back-end Developer Documentation** — provides more detailed documentation of the underlying code for researchers and developers who wish to modify or add functions to their validator.

If you are looking to simply make a version of the validator for your own project, you do not need to consult the **Back-end Developer Documentation** section.

---

# 1. Primary Functions

## Dependencies

You will need an up-to-date version of R (at least 4.6.0) and RStudio. The following R packages are required to run the scripts in this repo:

* `tidyverse`
* `shiny`
* `shinythemes`
* `openxlsx`
* `yaml`

To deploy the app on [shinyapps.io](https://www.shinyapps.io/) instead of running it locally, you will also need `rsconnect`.

This application was created using R version 4.6.0.

## How to use the validator

The basic version of the validator is straightforward to use. Here is a quick demo (note: to try out the demo, first download the validator from the repo. See **Downloading the validator** below):

1. Go to the [template version of the app](https://manybabies.shinyapps.io/shinyvalidator/).

2. Select a study from the *Study* drop-down menu (e.g. **samplestudy**).

3. Select a format from the *Study Format* drop-down menu (e.g. **sampleformat**).

4. Click *Browse* and select a dataset to validate (e.g. **sample_data_valid.csv** or **sample_data_notvalid.csv**).

5. The output window will display whether the dataset is valid, and if not valid, which variables/columns need to be fixed.

6. To easily locate the incorrect cells, you can click the *Download Highlighted File* button to download a spreadsheet that highlights all incorrect values.

---

# 2. Adapting the Validator

This section provides a step-by-step guide for adapting the basic validator for your own project needs.

## 2.1 Downloading the validator

The first step is to download the validator from the repository. Click on **Code → Download ZIP** to download the `.zip` file, then extract the `.zip` file using any compressor of your choice (e.g. WinZip).

<img src="README_images/downloading_zip.png" alt="">

## 2.2 Locally deploying your validator

The quickest way to get your validator up and running is to run it *locally* instead of deploying it on ShinyApp.

To do so, open the RProject file *ShinyValidator.Rproj*. Then in your RStudio, open *app.R* and click on **Run App**. (Note: You may be prompted to install relevant packages if you haven't already).

<img src="README_images/launching_app.png" alt="">

The template version of the validator should open up in a new window. You can use this locally as-is, and we will use this to generate your customized `.yaml` files later.

From here, there are two main components of the validator you would likely want to customize:

* The **Graphical User Interface (GUI)**, which is controlled by *ui.R*
* The **data template**, which is dependent on `.yaml` files stored in the *data_specifications* folder

Here is a step-by-step guide on tailoring these two components.

## 2.3 Customizing your GUI

Your locally deployed app should have several stand-in messages. These messages can be customized in the *ui.R* file by finding the corresponding line of code. For instance, if you would like to have a welcome message, you can adjust the corresponding line 26.

<img src="README_images/welcome_message_1.png" alt="">

For example, you can simply replace the message with your own and click **Reload App** to see your changes.

<img src="README_images/welcome_message_2.png" alt="">

You can similarly change any of the other fields by finding where the corresponding code is.

The template version of the validator provides a few useful fields that an average user may need, but you can add more if you are familiar with using Markdown.

## 2.4 Creating your data template

The next step is to specify your data template, i.e. what columns/variables must a dataset have, and what values are "allowed" for each column/variable.

The specifications are stored as `.yaml` files in the **data_specifications** folder, but **you do not need to hand write the code yourself**!

Open your locally deployed validator, and navigate to the **Specification Creation** tab. You will see a single field that asks how many variables you would like to have for your data template:

<img src="README_images/template_creation_1.png" alt="">

Once you enter a number, several new fields will appear for you to specify your columns/variables.

For the most part, these fields should be self-explanatory.

> **IMPORTANT NOTE:** If you change the number of variables at any point, **you will lose your progress**.

There are three variable types that the validator can check: **options**, **numeric**, and **strings**.

<details>
<summary><strong>Options</strong></summary>

This variable type allows you to specify which **exact entries** are allowed.

For instance, if I have a variable called "color," and the only possible values are "red", "yellow", and "blue", I would specify as such:

<img src="README_images/options.png" alt="" width="300" height="500">

</details>

<details>
<summary><strong>Numeric</strong></summary>

This variable type allows you to specify that a particular column can only take numeric values.

In addition, you can create a range restriction to further constrain the maximum and minimum values that are allowed.

For instance, if I have a variable "reaction_time_ms" with a minimum value of 300 and a maximum of 10000, I would specify as such:

<img src="README_images/numeric.png" alt="" width="300" height="500">

</details>

<details>
<summary><strong>String</strong></summary>

This variable type allows for open-ended entries (useful if it is impractical to list out all possible entries), but can be used to place restrictions on capitalization as well as maximum character length.

For instance, if I am conducting a large-scale collaborative project where I collect individual lab ids, I may want to allow for open-ended entries for labs to choose what they would like to be called (lab_id).

That said, I may want a character limit (e.g. 10 characters) so people don't get too creative, and want to remove all capitalization for easier processing. I would then specify as such:

<img src="README_images/string.png" alt="" width="300" height="500">

</details>

## 2.5 Adding your data specification to the validator

After specifying all your variables, you can click the **Download Setup** button to download a copy of your `.yaml` file.

The final thing to do is to move the `.yaml` file into the *data_specifications* folder, and rename it following this naming scheme:

*studyname_formatname*

For example, if this particular data template is for a study called "fishspeed" and this is the raw data file, I would name this `.yaml` file *FishSpeed_RawData*.

> **Note:** The file name must not contain spaces or special characters. Use capitalization to separate words.

Once you place the renamed `.yaml` file in the *data_specifications* folder, relaunch your app.

You should now be able to find your study and format in the dropdown menu on the left!

<img src="README_images/completed_yaml.png" alt="">

## 2.6 Testing your template

The final step is to test your newly created template.

Create a `.csv` file that contains all of the relevant columns (or, if you have an existing dataset, use that!). Create one row that contains zero errors (i.e. perfect data entry), and a few rows that contain some errors you anticipate seeing.

In your app, click **Browse** and navigate to this sample dataset.

It should correctly identify all the errors you intentionally made.

For easier comparisons, click the **Download Highlighted File** button to download a spreadsheet that highlights all errors.

## 2.7 Troubleshooting and minor adjustments

After testing your template, if you notice something is not working as intended (or if you overlooked a specification that you need), you can either remake the entire template following the steps above, or manually make adjustments by opening the `.yaml` file.

The `.yaml` file is simply a less user-friendly version of the specification creation page.

---

# 3. Back-end Developer Documentation

The **Back-end Developer Documentation** provides detailed information about the underlying code of the validator.

This section is intended for researchers and developers who wish to add new functions, modify existing functionality, or otherwise customize the validator beyond the options described in Section 2.

## 3.1 Application architecture

The validator is organized across five primary R files:

| File             | Purpose                                       |
| ---------------- | --------------------------------------------- |
| `app.R`          | Application initialization and launch         |
| `ui.R`           | User interface and layout                     |
| `server.R`       | Server-side application logic                 |
| `common.R`       | Shared functions and validation functions     |
| `ErrorHandler.R` | Error handling and downloadable error reports |

The validator also relies on `.yaml` files stored in the `data_specifications` folder to define study-specific data requirements.

Detailed documentation of each component is provided below.

<details>
<summary><strong>3.2 `app.R`</strong></summary>

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
