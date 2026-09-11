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

### Options

This variable type allows you to specify which **exact entries** are allowed.

For instance, if I have a variable called "color," and the only possible values are "red", "yellow", and "blue", I would specify as such:

<img src="README_images/options.png" alt="" width="300" height="500">

### Numeric

This variable type allows you to specify that a particular column can only take numeric values.

In addition, you can create a range restriction to further constrain the maximum and minimum values that are allowed.

For instance, if I have a variable "reaction_time_ms" with a minimum value of 300 and a maximum of 10000, I would specify as such:

<img src="README_images/numeric.png" alt="" width="300" height="500">

### String

This variable type allows for open-ended entries (useful if it is impractical to list out all possible entries), but can be used to place restrictions on capitalization as well as maximum character length.

For instance, if I am conducting a large-scale collaborative project where I collect individual lab ids, I may want to allow for open-ended entries for labs to choose what they would like to be called (lab_id).

That said, I may want a character limit (e.g. 10 characters) so people don't get too creative, and want to remove all capitalization for easier processing. I would then specify as such:

<img src="README_images/string.png" alt="" width="300" height="500">

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
| `commons.R`      | Shared functions and validation functions     |
| `ErrorHandler.R` | Error handling and user-facing error messages |

The validator also relies on `.yaml` files stored in the `data_specifications` folder to define study-specific data requirements.

Detailed documentation of each component will be provided below.

## 3.2 `app.R`

*Developer documentation to be added.*

## 3.3 `ui.R`

*Developer documentation to be added.*

## 3.4 `server.R`

*Developer documentation to be added.*

## 3.5 `commons.R`

*Developer documentation to be added.*

## 3.6 `ErrorHandler.R`

*Developer documentation to be added.*

## 3.7 Data specifications and YAML files

*Developer documentation to be added.*

## 3.8 Adding or modifying validation functions

*Developer documentation to be added.*

## 3.9 Adding new error types

*Developer documentation to be added.*

## 3.10 Development and testing workflow

*Developer documentation to be added.*
