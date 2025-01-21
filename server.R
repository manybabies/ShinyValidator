library(shiny)
library(tidyverse)
library(yaml)

source("common.R")
source("ErrorHandler.R")

# NEW Server
server <- function(input, output, session) {
  output$study_format <- renderUI({
    selectInput("format", label = h4("Study Format"),
                choices = filter(studies, study == input$study)$format)
  })
  
  output$specification <- renderPrint({
    req(input$study, input$format)
    yaml_file_path <- paste0("data_specifications/", input$study, "_", input$format, ".yaml")
    yaml::yaml.load_file(yaml_file_path)
  })
  
  output$validator_output <- renderPrint({
    req(input$file)
    
    yaml_file_path <- paste0("data_specifications/", input$study, "_", input$format, ".yaml")
    fields <- yaml::yaml.load_file(yaml_file_path)
    
    tryCatch({
      df <- read_csv(input$file$datapath)
      cat("Upload successful!\n\n")
    }, error = function(e) {
      stop(safeError(e))
    })
    
    validated <- validate_dataset(fields, df)
    valid <- validated[[1]]
    issues <- validated[[2]]
    if (valid) {
      cat("\nDataset is valid!")
    } else {
      cat("\nDataset is NOT valid, please correct and try again!")
      highlight_csv_to_xlsx(df, issues, "/Users/abteen/Desktop/issues.xlsx")
    }
  })
  
  userData <- reactive({
    nVars <- input$numVars
    data_list <- list()
    
    if (nVars > 0) {
      for (i in 1:nVars) {
        field_type <- input[[paste0("field_type_", i)]]
        options <- ifelse(field_type == "Options", input[[paste0("option_input_", i)]], NA)
        lowerlimit <- ifelse(field_type == "Numeric" && input[[paste0("range_req_", i)]] == "yes", input[[paste0("min_value_", i)]], NA)
        upperlimit <- ifelse(field_type == "Numeric" && input[[paste0("rage_req_", i)]] == "yes", input[[paste0("max_value_", i)]], NA)
        
        format <- if (field_type == "Numeric" && input[[paste0("range_req_", i)]] == "yes") {
          "restricted"
        } else if (field_type == "String" && input[[paste0("caped_", i)]] == "yes") {
          "capitalized"
        } else {
          "open"
        }
        
        data_list[[i]] <- list(
          field = input[[paste0("field_name_", i)]],
          description = input[[paste0("field_description_", i)]],
          type = field_type,
          options = options,
          format = format,
          lowerlimit = lowerlimit,
          upperlimit = upperlimit,
          required = input[[paste0("is_required_", i)]],
          NA_allowed = input[[paste0("allow_na_", i)]],
          error_message = toString(input[[paste0("error_message_", i)]])
        )
      }
    }
    
    return(data_list)
  })
  
  
  output$downloadSetup <- downloadHandler(
    filename = function() {
      paste("data_settings_", Sys.Date(), ".yaml", sep = "")
    },
    content = function(file) {
      data <- userData()
      write_yaml(data, file)
    }
  )

  output$variableInputs <- renderUI({
    numVars <- input$numVars
    if (numVars > 0) {
      field_list <- lapply(1:numVars, function(i) {
        fluidRow(
          # Field Humanize Variables
          textInput(paste0("field_name_", i), paste("Enter the name of your data (Field ", i, "):")),
          textInput(paste0("field_description_", i), paste("Enter a description of your data (Field ", i, "):")),
          
          # Field Type and global variables
          selectInput(paste0("field_type_", i), "Choose your data type:", 
                      choices = c("options", "numeric", "string")),
          selectInput(paste0("is_required_", i), "Is the data type required:", 
                      choices = c("yes", "no")),
          selectInput(paste0("allow_na_", i), "Are NA Values Allowed:", 
                      choices = c("yes", "no")),
          
          conditionalPanel(
            condition = paste0("input.field_type_", i, " == 'Numeric'"),
            selectInput(paste0("range_req_", i), "Are there range restrictions on the input:", 
                        choices = c("no", "yes")),
          ),
          
          conditionalPanel(
            condition = sprintf("input.range_req_%s == 'yes'", i),
            numericInput(paste0("min_value_", i), "Minimum Value:", value = NA),
            numericInput(paste0("max_value_", i), "Maximum Value:", value = NA)
          ),
          
          conditionalPanel(
            condition = paste0("input.field_type_", i, " == 'String'"),
            selectInput(paste0("caped_", i), "Should the input have capitalizations:", 
                        choices = c("no", "yes"))
          ),
          
          conditionalPanel(
            condition = paste0("input.field_type_", i, " == 'String'"),
            selectInput(paste0("range_req_string", i), "Are there length restrictions on the input:", 
                        choices = c("no", "yes")),
          ),
          
          conditionalPanel(
            condition = sprintf("input.range_req_string%s == 'yes'", i),
            numericInput(paste0("min_value_", i), "Minimum Length:", value = NA),
            numericInput(paste0("max_value_", i), "Maximum Length:", value = NA)
          ),
          
          conditionalPanel(
            condition = paste0("input.field_type_", i, " == 'Options'"),
            textInput(paste0("option_input_", i), "Enter the name of the options separated by a comma and no space:")
          ),
          
          textInput(paste0("error_message_", i), "Enter an error message for your data:"),
        )
      })
      
      do.call(tagList, field_list)
    }
  })
  
  output$downloadHighlighted <- downloadHandler(
    filename = function() {
      paste("highlighted_issues_", Sys.Date(), ".xlsx", sep = "")
    },
    
    content = function(file) {
      req(input$file)
      if (is.null(input$file$datapath) || input$file$datapath == "") {
        stop("No file provided. Please upload a dataset before attempting to download.")
      }
      
      req(input$study, input$format)
      yaml_file_path <- paste0("data_specifications/", input$study, "_", input$format, ".yaml")
      
      if (!file.exists(yaml_file_path)) {
        stop("The corresponding YAML specification file does not exist. Please check your study and format selection.")
      }
      
      fields <- tryCatch(
        yaml::yaml.load_file(yaml_file_path),
        error = function(e) stop("Failed to load YAML file. Please ensure the file is valid and accessible.")
      )
      
      df <- tryCatch(
        read_csv(input$file$datapath),
        error = function(e) stop("Failed to read the uploaded dataset. Please ensure the file is in a valid CSV format.")
      )
      
      validated <- tryCatch(
        validate_dataset(fields, df),
        error = function(e) stop("Error during dataset validation: ", e$message)
      )
      
      valid <- validated[[1]]
      issues <- validated[[2]]
      
      if (!valid) {
        wb <- tryCatch(
          highlight_csv_to_xlsx(df, issues),
          error = function(e) stop("Failed to generate the highlighted workbook: ", e$message)
        )
        
        tryCatch(
          openxlsx::saveWorkbook(wb, file, overwrite = TRUE),
          error = function(e) stop("Failed to save the workbook: ", e$message)
        )
      } else {
        stop("No issues to highlight. The dataset is valid!")
      }
    }
  )
}