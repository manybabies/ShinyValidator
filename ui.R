library(shiny)
library(shinythemes)
source("common.R")

# NEW UI
ui <- fluidPage(
  theme = shinytheme("spacelab"),
  
  titlePanel("ShinyValidator Template"),
  br(),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("study", h4("Study"), 
                  choices = unique(studies$study)),
      uiOutput("study_format"),
      fileInput("file", "Choose CSV File",
                multiple = FALSE,
                accept = c("text/csv",
                           "text/comma-separated-values,text/plain",
                           ".csv"))
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Validation Results", 
                 p(strong("This is where you put the welcome message!")),
                 p(em("You can also put a secondary message here with more instructions, perhaps referencing a link with helpful links:"),
                   tags$a(href = "https://github.com/manybabies/ShinyValidator",
                          "For example, link to this app's Github repo.")),
                 p(strong("This is where you can provide specific instructions on how to use"), em("your"), strong("validator.")),
                 p("Click", em("Browse"), "to select the dataset you would like to validate."),
                 verbatimTextOutput("validator_output")),
        tabPanel("Specification Creation", 
                 h4("Make a Decision"),
                 numericInput("numVars", "Number of Variables:", value = 0),
                 uiOutput("variableInputs"),
                 conditionalPanel(
                   condition = "input.numVars > 0",
                   downloadButton("downloadSetup", "Download Setup")
                 )),
        tabPanel("Specification", 
                 p("This is the full text of the specification you have chosen."),
                 verbatimTextOutput("specification")),
      )
    )
  )
)

