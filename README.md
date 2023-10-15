# ShinyValidator
Template GUI to validate datasets. Fork this template to customize for your project needs,
and use as an app locally or deploy via the `rsconnect` package. You can find a live version of this template [here](https://manybabies.shinyapps.io/shinyvalidator/).

## Components of this repo

* [How to use the validator](#how-to-use-the-validator)
* [The "look" of the GUI - ui.R and server.R](#the-look-of-the-gui)
* [common.R - Function specifications](#commonr---validators-functions)
* [data_specifications and yaml files](#data_specifications-and-yaml-files)

## Dependencies

The following R packages are required to run the scripts in this repo: `tidyverse`, `shiny`, `shinythemes`, and `yaml`. To deploy the app on [shinyapps.io](https://www.shinyapps.io/) instead of running it locally, you will also need `rsconnect`. This application was created using R version 4.1.1.

## How to use the validator

The basic version of the validator is straightforward to use:

1. Go to the [template version of the app](https://manybabies.shinyapps.io/shinyvalidator/).

2. Select a study from the *Study* drop down menu (e.g. **samplestudy**)

3. Select a format from the *Study Format* drop down menu (e.g. **sampleformat**)

4. Click *Browse* and select a dataset to validate (e.g. **sample_data_valid.csv** or **sample_data_notvalid.csv**)

5. Output window will display whether dataset is valid, and if not valid, which variables/columns need to be fixed.

## The "look" of the GUI

`ui.r` specifies major components of the GUI.



## common.R - Validator's Functions

## data_specifications and yaml files
