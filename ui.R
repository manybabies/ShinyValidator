library(shiny)
library(shinythemes)
library(DT)

source("common.R")

# UI
ui <- fluidPage(
  theme = shinythemes::shinytheme("spacelab"),
  
  titlePanel("ShinyValidator Template"),
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
        
        tabPanel(
          "Validation Results",
          
          p(
            strong("This is where you put the welcome message!")
          ),
          
          p(
            em(
              "You can also put a secondary message here with more instructions, perhaps referencing a link with helpful links:"
            ),
            tags$a(
              href = "https://github.com/manybabies/ShinyValidator",
              "For example, link to this app's Github repo."
            )
          ),
          
          p(
            strong(
              "This is where you can provide specific instructions on how to use"
            ),
            em("your"),
            strong("validator.")
          ),
          
          p(
            "Click",
            em("Browse"),
            "to select the dataset you would like to validate."
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
        
        tabPanel(
          "Specification",
          
          p(
            "This is the human-readable version of the specification you have chosen."
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