library(shiny)
library(DT)

# Maximum upload size. Shiny's default is 5 MB, which a CSV validator will hit quickly.
options(shiny.maxRequestSize = 50 * 1024^2)

source("ui.R")
source("server.R")

shinyApp(ui = ui, server = server)