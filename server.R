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
      cat("Dataset uploaded successfully! Reviewing Dataset... \n\n")
    }, error = function(e) {
      stop(safeError(e))
    })
    
    validated <- validate_dataset(fields, df)
    valid <- validated[[1]]
    issues <- validated[[2]]
    if (valid) {
      cat("\nDataset is valid! All variables match specifications.")
    } else {
      cat("\nThe dataset is not valid. Please review the specifications and the highlighted error log.")

    }
  })
  
  userData <- reactive({
    nVars <- input$numVars
    data_list <- list()
    
    if (nVars > 0) {
      for (i in 1:nVars) {
        field_type <- input[[paste0("field_type_", i)]]
        
        if(field_type == "numeric") {
          lowerlimit <- ifelse(input[[paste0("range_req_", i)]] == "yes", input[[paste0("min_value_", i)]], NA)
          upperlimit <- ifelse(input[[paste0("range_req_", i)]] == "yes", input[[paste0("max_value_", i)]], NA)
        } else {
          lowerlimit <- ifelse(field_type == "string" && input[[paste0("range_req_string", i)]] == "yes", input[[paste0("min_value_s", i)]], NA)
          upperlimit <- ifelse(field_type == "string" && input[[paste0("range_req_string", i)]] == "yes", input[[paste0("max_value_s", i)]], NA)
        }

        options <- c()
        
        if (field_type == "options"){
          stringList <- strsplit(input[[paste0("option_input_", i)]], split = ",")
          
          for (j in stringList) {
            options <- c(options, j)
          }
        } 
        
        format <- if (
          field_type == "numeric" &&
          input[[paste0("range_req_", i)]] == "yes"
        ) {
          
          "restricted"
          
        } else if (field_type == "string") {
          
          validation <- input[[paste0("string_validation_", i)]]
          
          if (validation %in% c(
            "letters",
            "numbers",
            "alphanumeric",
            "examples"
          )) {
            
            "regex"
            
          } else {
            
            validation
          }
          
        } else {
          
          "open"
        }
        
        pattern <- if (field_type == "string") {
          
          validation <- input[[paste0("string_validation_", i)]]
          
          if (validation == "letters") {
            
            "^[A-Za-z]+$"
            
          } else if (validation == "numbers") {
            
            "^[0-9]+$"
            
          } else if (validation == "alphanumeric") {
            
            "^[A-Za-z0-9]+$"
            
          } else if (validation == "examples") {
            
            examples <- c(
              input[[paste0("example_1_", i)]],
              input[[paste0("example_2_", i)]],
              input[[paste0("example_3_", i)]]
            )
            
            GenerateRegex(examples)
            
          } else {
            
            NA
          }
          
        } else {
          
          NA
        }
        
        required <- if(input[[paste0("is_required_", i)]] == 'yes') {
          TRUE
        } else {
          FALSE
        }
        
        NA_allowed <- if(input[[paste0("allow_na_", i)]] == 'yes'){
          TRUE
        } else {
          FALSE
        }
        
        data_list[[i]] <- list(
          field = input[[paste0("field_name_", i)]],
          description = input[[paste0("field_description_", i)]],
          type = field_type,
          options = options,
          format = format,
          pattern = pattern,
          lowerlimit = lowerlimit,
          upperlimit = upperlimit,
          required = required,
          NA_allowed = NA_allowed,
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

  createVariableTab <- function(i) {
    
    tabPanel(
      title = tags$span(
        id = paste0("tab_label_", i),
        paste("Variable", i)
      ),
      
      value = paste0("variable_", i),
      
      br(),
      
      # Variable information
      textInput(
        paste0("field_name_", i),
        "Enter the name of this variable/column:"
      ),
      
      textInput(
        paste0("field_description_", i),
        "Enter a description of your variable/column:"
      ),
      
      # Field type and global variables
      selectInput(
        paste0("field_type_", i),
        "Choose your data type:",
        choices = c("options", "numeric", "string")
      ),
      
      selectInput(
        paste0("is_required_", i),
        "Is the data type required:",
        choices = c("yes", "no")
      ),
      
      selectInput(
        paste0("allow_na_", i),
        "Are NA Values Allowed:",
        choices = c("yes", "no")
      ),
      
      # Numeric range restrictions
      conditionalPanel(
        condition = paste0(
          "input.field_type_", i, " == 'numeric'"
        ),
        
        selectInput(
          paste0("range_req_", i),
          "Are there range restrictions on the input:",
          choices = c("no", "yes")
        )
      ),
      
      conditionalPanel(
        condition = paste0(
          "input.range_req_", i, " == 'yes'"
        ),
        
        numericInput(
          paste0("min_value_", i),
          "Minimum Value:",
          value = NA
        ),
        
        numericInput(
          paste0("max_value_", i),
          "Maximum Value:",
          value = NA
        )
      ),
      
      # String validation
      conditionalPanel(
        condition = paste0(
          "input.field_type_", i, " == 'string'"
        ),
        
        selectInput(
          paste0("string_validation_", i),
          "String validation:",
          choices = c(
            "Open text" = "open",
            "Lowercase only" = "uncapitalized",
            "Uppercase only" = "capitalized",
            "Letters only" = "letters",
            "Numbers only" = "numbers",
            "Letters and numbers" = "alphanumeric",
            "Match example values" = "examples"
          )
        )
      ),
      
      # Example-based validation
      conditionalPanel(
        condition = paste0(
          "input.field_type_", i,
          " == 'string' && ",
          "input.string_validation_", i,
          " == 'examples'"
        ),
        
        textInput(
          paste0("example_1_", i),
          "Example value 1:",
          value = ""
        ),
        
        textInput(
          paste0("example_2_", i),
          "Example value 2:",
          value = ""
        ),
        
        textInput(
          paste0("example_3_", i),
          "Example value 3:",
          value = ""
        ),
        
        helpText(
          "Enter three examples of valid values. The validator will use them to determine the required pattern."
        ),
        
        uiOutput(
          paste0("example_validation_", i)
        )
      ),
      
      # String length restrictions
      conditionalPanel(
        condition = paste0(
          "input.field_type_", i,
          " == 'string'"
        ),
        
        selectInput(
          paste0("range_req_string", i),
          "Are there length restrictions on the input:",
          choices = c("no", "yes")
        )
      ),
      
      conditionalPanel(
        condition = paste0(
          "input.range_req_string", i,
          " == 'yes'"
        ),
        
        numericInput(
          paste0("min_value_s", i),
          "Minimum Value:",
          value = NA
        ),
        
        numericInput(
          paste0("max_value_s", i),
          "Maximum Value:",
          value = NA
        )
      ),
      
      # Options
      conditionalPanel(
        condition = paste0(
          "input.field_type_", i,
          " == 'options'"
        ),
        
        textInput(
          paste0("option_input_", i),
          "Enter the name of the options separated by a comma and no space:"
        )
      ),
      
      # Error message
      textInput(
        paste0("error_message_", i),
        "Enter an error message for your data:"
      )
    )
  }
  
  
  current_num_vars <- reactiveVal(0)
  
  
  observeEvent(input$numVars, {
    
    new_num_vars <- input$numVars
    
    if (is.null(new_num_vars) || is.na(new_num_vars)) {
      return()
    }
    
    old_num_vars <- current_num_vars()
    
    # Add tabs when the number of variables increases
    if (new_num_vars > old_num_vars) {
      
      for (i in seq(old_num_vars + 1, new_num_vars)) {
        
        insertTab(
          inputId = "variable_tabs",
          tab = createVariableTab(i),
          target = NULL,
          position = "after",
          select = TRUE
        )
      }
    }
    
    # Remove tabs when the number of variables decreases
    if (new_num_vars < old_num_vars) {
      
      for (i in seq(new_num_vars + 1, old_num_vars)) {
        
        removeTab(
          inputId = "variable_tabs",
          target = paste0("variable_", i)
        )
      }
    }
    
    current_num_vars(new_num_vars)
  })
  
  observe({
    
    nVars <- input$numVars
    
    if (!is.null(nVars) && !is.na(nVars) && nVars > 0) {
      
      for (i in 1:nVars) {
        
        local({
          
          j <- i
          
          output[[paste0("example_validation_", j)]] <- renderUI({
            
            validation <- input[[paste0("string_validation_", j)]]
            
            if (is.null(validation) || is.na(validation) || validation != "examples") {
              return(NULL)
            }
            
            examples <- c(
              input[[paste0("example_1_", j)]],
              input[[paste0("example_2_", j)]],
              input[[paste0("example_3_", j)]]
            )
            
            if (any(is.null(examples)) || any(examples == "")) {
              
              return(
                helpText(
                  "Please enter all three example values."
                )
              )
            }
            
            NULL
          })
          
        })
      }
    }
  })
  
  output$downloadSetupButton <- renderUI({
    
    nVars <- input$numVars
    
    if (is.null(nVars) || nVars == 0) {
      return(NULL)
    }
    
    all_examples_complete <- TRUE
    
    for (i in 1:nVars) {
      
      field_type <- input[[paste0("field_type_", i)]]
      validation <- input[[paste0("string_validation_", i)]]
      
      if (!is.null(field_type) &&
          !is.na(field_type) &&
          field_type == "string" &&
          !is.null(validation) &&
          !is.na(validation) &&
          validation == "examples") {
        
        examples <- c(
          input[[paste0("example_1_", i)]],
          input[[paste0("example_2_", i)]],
          input[[paste0("example_3_", i)]]
        )
        
        if (any(is.null(examples)) ||
            any(is.na(examples)) ||
            any(examples == "")) {
          
          all_examples_complete <- FALSE
        }
      }
    }
    
    if (all_examples_complete) {
      
      downloadButton(
        "downloadSetup",
        "Download Setup"
      )
      
    } else {
      
      tagList(
        tags$button(
          type = "button",
          class = "btn btn-default disabled",
          disabled = "disabled",
          "Download Setup"
        ),
        tags$p(
          tags$strong(
            style = "color: red;",
            "Please enter all three example values before downloading the setup."
          )
        )
      )
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