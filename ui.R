library(shiny)
library(shinythemes)
library(DT)
library(yaml)

# Load shared functions
source("common.R")

# Load configuration
config <- yaml::read_yaml("configuration/config.yaml")

# UI
ui <- fluidPage(
  
  theme = shinythemes::shinytheme("spacelab"),
  
  titlePanel(config$app_title),
  
  br(),
  
  sidebarLayout(
    
    # Sidebar
    sidebarPanel(
      width = 3,
      
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
      radioButtons(
        "page",
        "Navigation",
        choices = c(
          "Validation Results" = "validation_results",
          "Specification" = "specification",
          "Specification Creation" = "specification_creation",
          "Configuration Creation" = "configuration_creation"
        ),
        selected = "validation_results"
      )
    ),
    
    # Main panel
    mainPanel(
      width = 9,
      
      # Validation Results
      conditionalPanel(
        condition = "input.page == 'validation_results'",
        
        h3("Validation Results"),
        
        p(
          strong(config$welcome_message)
        ),
        
        p(
          em(config$secondary_message),
          tags$a(
            href = config$secondary_link_url,
            config$secondary_link_text
          )
        ),
        
        p(
          strong(config$instructions_before),
          em(config$instructions_emphasis),
          strong(config$instructions_after)
        ),
        
        p(
          config$upload_instructions_before,
          em(config$upload_instructions_emphasis),
          config$upload_instructions_after
        ),
        
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
        
        h3("Specification"),
        
        p(
          config$specification_message
        ),
        
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
        
        h3("Configuration Creation"),
        
        h4("Create your configuration"),
        
        textInput(
          "config_app_title",
          "Application title:",
          value = ""
        ),
        
        textAreaInput(
          "config_welcome_message",
          "Welcome message:",
          value = "",
          rows = 3
        ),
        
        textAreaInput(
          "config_secondary_message",
          "Secondary message:",
          value = "",
          rows = 3
        ),
        
        textInput(
          "config_secondary_link_url",
          "Secondary link URL:",
          value = ""
        ),
        
        textInput(
          "config_secondary_link_text",
          "Secondary link text:",
          value = ""
        ),
        
        textInput(
          "config_instructions_before",
          "Main instructions — before emphasized text:",
          value = ""
        ),
        
        textInput(
          "config_instructions_emphasis",
          "Main instructions — emphasized text:",
          value = ""
        ),
        
        textInput(
          "config_instructions_after",
          "Main instructions — after emphasized text:",
          value = ""
        ),
        
        textInput(
          "config_upload_instructions_before",
          "Upload instructions — before emphasized text:",
          value = ""
        ),
        
        textInput(
          "config_upload_instructions_emphasis",
          "Upload instructions — emphasized text:",
          value = ""
        ),
        
        textInput(
          "config_upload_instructions_after",
          "Upload instructions — after emphasized text:",
          value = ""
        ),
        
        textAreaInput(
          "config_specification_message",
          "Specification message:",
          value = "",
          rows = 3
        ),
        
        br(),
        
        downloadButton(
          "downloadConfiguration",
          "Download Configuration"
        )
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