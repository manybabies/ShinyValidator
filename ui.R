library(shiny)
library(shinythemes)
library(DT)
library(yaml)

# Load shared functions
source("common.R")

# Load default configuration
config <- yaml::read_yaml("configuration/config_default.yaml")

# Available configurations
configuration_files <- list.files(
  "configuration",
  pattern = "^config_.+\\.(yaml|yml)$",
  full.names = FALSE
)

# Display configuration names without the "config_" prefix or file extension
configuration_choices <- setNames(
  configuration_files,
  sub(
    "^config_(.*)\\.(yaml|yml)$",
    "\\1",
    configuration_files
  )
)

# UI
ui <- fluidPage(
  
  theme = shinythemes::shinytheme("spacelab"),
  
  # Navigation styling
  tags$head(
    tags$style(HTML("
      
      /* Navigation heading */
      .navigation-menu .control-label {
        font-size: 16px;
        font-weight: 600;
        margin-bottom: 10px;
      }
      
      /* Remove default radio button spacing */
      .navigation-menu .radio {
        margin-top: 0;
        margin-bottom: 4px;
      }
      
      /* Navigation items */
      .navigation-menu .radio label {
        display: block;
        padding: 10px 12px;
        margin: 0;
        border-radius: 5px;
        cursor: pointer;
        font-weight: normal;
        transition: background-color 0.15s ease;
      }
      
      /* Hide the radio circles */
      .navigation-menu .radio input[type='radio'] {
        position: absolute;
        opacity: 0;
      }
      
      /* Hover effect */
      .navigation-menu .radio label:hover {
        background-color: #e9ecef;
      }
      
      /* Selected navigation item */
      .navigation-menu .radio input[type='radio']:checked + span {
        font-weight: 600;
      }
      
      .navigation-menu .radio:has(input[type='radio']:checked) label {
        background-color: #d9eaf7;
        color: #245a7a;
      }
      
    "))
  ),
  
  # Application title
  uiOutput("app_title"),
  
  br(),
  
  sidebarLayout(
    
    # Sidebar
    sidebarPanel(
      width = 3,
      
      # Configuration selection
      selectInput(
        "configuration",
        h4("Configuration"),
        choices = configuration_choices,
        selected = configuration_files[1]
      ),
      
      # Study selection
      selectInput(
        "study",
        h4("Study"),
        choices = unique(studies$study)
      ),
      
      uiOutput("study_format"),
      
      fileInput(
        "file",
        "Choose CSV File",
        multiple = FALSE,
        accept = c(
          "text/csv",
          "text/comma-separated-values,text/plain",
          ".csv"
        )
      ),
      
      hr(),
      
      # Navigation
      div(
        class = "navigation-menu",
        
        radioButtons(
          "page",
          "Validator Functions",
          choices = c(
            "Validation Results" = "validation_results",
            "Specification Details" = "specification",
            "Specification Creation" = "specification_creation",
            "Configuration Creation" = "configuration_creation"
          ),
          selected = "validation_results"
        )
      )
    ),
    
    # Main panel
    mainPanel(
      width = 9,
      
      # Validation Results
      conditionalPanel(
        condition = "input.page == 'validation_results'",
        
        uiOutput("validation_config_content"),
        
        br(),
        
        downloadButton(
          "downloadHighlighted",
          "Download Highlighted File"
        ),
        
        br(),
        br(),
        
        radioButtons(
          "error_view",
          "View errors by:",
          choices = c(
            "No in-app error display" = "none",
            "Column" = "column",
            "Row" = "row"
          ),
          selected = "none",
          inline = TRUE
        ),
        
        uiOutput("errors_by_column"),
        
        DTOutput("validation_preview")
      ),
      
      # Specification
      conditionalPanel(
        condition = "input.page == 'specification'",
        
        h3("Specification Details"),
        
        uiOutput("specification_message"),
        
        uiOutput("specification")
      ),
      
      # Specification Creation
      conditionalPanel(
        condition = "input.page == 'specification_creation'",
        
        h3("Specification Creation"),
        
        h4("Make a Decision"),
        
        numericInput(
          "numVars",
          "Number of Variables:",
          value = 0,
          min = 0
        ),
        
        tabsetPanel(
          id = "variable_tabs",
          type = "tabs"
        ),
        
        conditionalPanel(
          condition = "input.numVars > 0",
          uiOutput("downloadSetupButton")
        )
      ),
      
      # Configuration Creation
      conditionalPanel(
        condition = "input.page == 'configuration_creation'",
        
        uiOutput("configuration_creation_content")
      )
    )
  ),
  
  # Update variable tab names
  tags$script(HTML("
    document.addEventListener('input', function(event) {
      
      if (event.target.id.startsWith('field_name_')) {
        
        var number = event.target.id.replace('field_name_', '');
        var label = document.getElementById('tab_label_' + number);
        
        if (label) {
          
          if (event.target.value.trim() === '') {
            label.textContent = 'Variable ' + number;
          } else {
            label.textContent = event.target.value;
          }
          
        }
      }
    });
  "))
)