library(shiny)
library(shinythemes)
library(DT)
library(yaml)

source("common.R")

# Load application configuration
config <- yaml::read_yaml("configuration/config.yaml")

# UI
ui <- fluidPage(
  theme = shinythemes::shinytheme("spacelab"),
  
  titlePanel(config$app_title),
  br(),
  
  sidebarLayout(
    sidebarPanel(
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
      
      downloadButton(
        "downloadHighlighted",
        "Download Highlighted File"
      )
    ),
    
    mainPanel(
      tabsetPanel(
        
        # Validation Results
        tabPanel(
          "Validation Results",
          
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
          
          uiOutput("row_actions"),
          
          DTOutput("validation_preview")
          
        ),
        
        # Specification Creation
        tabPanel(
          "Specification Creation",
          
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
        
        # Specification
        tabPanel(
          "Specification",
          
          p(
            config$specification_message
          ),
          
          uiOutput("specification")
        )
      )
    )
  ),
  
  # Update variable tab names without rebuilding the inputs
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