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
        
        h3("Validation Results"),
        
        p(
          strong(config$welcome_message)
        ),
        
        p(
          em(config$secondary_message)
        ),
        
        # Instruction Sets and Links
        fluidRow(
          
          # Instruction Sets
          column(
            width = 8,
            
            if (
              !is.null(config$instruction_set_1) &&
              length(config$instruction_set_1) > 0
            ) {
              tagList(
                h4("Instruction Set 1"),
                
                lapply(
                  config$instruction_set_1,
                  function(x) p(x)
                )
              )
            },
            
            if (
              !is.null(config$instruction_set_2) &&
              length(config$instruction_set_2) > 0
            ) {
              tagList(
                h4("Instruction Set 2"),
                
                lapply(
                  config$instruction_set_2,
                  function(x) p(x)
                )
              )
            }
          ),
          
          # Links
          column(
            width = 4,
            
            if (
              !is.null(config$links) &&
              length(config$links) > 0
            ) {
              tagList(
                h4("Links"),
                
                lapply(
                  config$links,
                  function(link) {
                    tags$p(
                      tags$a(
                        href = link$url,
                        link$text,
                        target = "_blank"
                      )
                    )
                  }
                )
              )
            }
          )
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
        
        h3("Specification Details"),
        
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
        
        p(
          "Customize the text and links used by your ShinyValidator. ",
          "The fields below are pre-populated with the current configuration."
        ),
        
        # Application title
        textInput(
          "config_app_title",
          "Application title:",
          value = config$app_title
        ),
        
        # Welcome message
        checkboxInput(
          "enable_welcome_message",
          "Enable welcome message",
          value = !is.null(config$welcome_message) &&
            nzchar(config$welcome_message)
        ),
        
        conditionalPanel(
          condition = "input.enable_welcome_message",
          
          textAreaInput(
            "config_welcome_message",
            "Welcome message:",
            value = if (
              is.null(config$welcome_message)
            ) {
              ""
            } else {
              config$welcome_message
            },
            rows = 3
          )
        ),
        
        # Secondary message
        checkboxInput(
          "enable_secondary_message",
          "Enable secondary message",
          value = !is.null(config$secondary_message) &&
            nzchar(config$secondary_message)
        ),
        
        conditionalPanel(
          condition = "input.enable_secondary_message",
          
          textAreaInput(
            "config_secondary_message",
            "Secondary message:",
            value = if (
              is.null(config$secondary_message)
            ) {
              ""
            } else {
              config$secondary_message
            },
            rows = 3
          )
        ),
        
        br(),
        
        # Instruction Sets and Links
        fluidRow(
          
          # Instruction Set 1
          column(
            width = 4,
            
            h4("Instruction Set 1"),
            
            checkboxInput(
              "enable_instruction_set_1",
              "Enable Instruction Set 1",
              value = !is.null(config$instruction_set_1) &&
                length(config$instruction_set_1) > 0
            ),
            
            conditionalPanel(
              condition = "input.enable_instruction_set_1",
              
              numericInput(
                "num_instruction_lines",
                "Number of instruction lines:",
                value = if (
                  is.null(config$instruction_set_1)
                ) {
                  1
                } else {
                  length(unlist(config$instruction_set_1))
                },
                min = 1,
                max = 20
              ),
              
              uiOutput("instruction_fields")
            )
          ),
          
          # Instruction Set 2
          column(
            width = 4,
            
            h4("Instruction Set 2"),
            
            checkboxInput(
              "enable_instruction_set_2",
              "Enable Instruction Set 2",
              value = !is.null(config$instruction_set_2) &&
                length(config$instruction_set_2) > 0
            ),
            
            conditionalPanel(
              condition = "input.enable_instruction_set_2",
              
              numericInput(
                "num_upload_instruction_lines",
                "Number of instruction lines:",
                value = if (
                  is.null(config$instruction_set_2)
                ) {
                  1
                } else {
                  length(unlist(config$instruction_set_2))
                },
                min = 1,
                max = 20
              ),
              
              uiOutput("upload_instruction_fields")
            )
          ),
          
          # Links
          column(
            width = 4,
            
            h4("Links"),
            
            checkboxInput(
              "enable_links",
              "Enable Links",
              value = !is.null(config$links) &&
                length(config$links) > 0
            ),
            
            conditionalPanel(
              condition = "input.enable_links",
              
              numericInput(
                "num_links",
                "Number of links:",
                value = if (
                  is.null(config$links)
                ) {
                  1
                } else {
                  length(config$links)
                },
                min = 1,
                max = 20
              ),
              
              uiOutput("link_fields")
            )
          )
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