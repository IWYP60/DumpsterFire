#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# lapply(dbListConnections(MySQL()), dbDisconnect)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Germinate Database Interface"),
  tags$br(),
  tags$h4("Current summary of Germinate Database:"),
  textOutput("txtAccSummary"),
  textOutput("txtExpSummary"),
  textOutput("txtPlantSummary"),
  textOutput("txtSampleSummary"),
  tags$br(),
  tags$h4("Current Query:"),
  textOutput("txtQuery"),
  tags$br(),
  
  mainPanel(
    tabsetPanel(
      tabPanel("Details",
               tags$h2("Help and instructions are coming soon. In the meantime, contact Darren Cullerne"),
               tags$a(href="mailto:darren.cullerne@anu.edu.au", "darren.cullerne@anu.edu.au")
      ),
      tabPanel("Accessions",
              fluidRow(
                tags$br(),
                column(2,
                  textInput("txtAccNameSearch","Search database for:"),
                  actionButton("btnAccSearch","Search")),
                column(2,
                  uiOutput("uiGerminatebaseSelect"),
                  checkboxInput("accExtendedCheck", "Extended Results", value = FALSE)),
                column(2,
                  tags$br(),
                  downloadButton("btnAccDL","Download"))
                ),
              tableOutput("tblAcc"),
              tags$br()),

      tabPanel("Experiments",
               fluidRow(
                 tags$br(),
                 column(2,
                        uiOutput("uiExperimentSelect"),
                        actionButton("btnExpSearch","Search")),
                 column(2, 
                        tags$br(),
                        downloadButton("btnExpDL","Download"),
                        tags$br(),
                        tags$br(),
                        checkboxInput("expExtendedCheck", "Extended Results", value = FALSE))
               ),
               textOutput("txtExpOutput"),
               tableOutput("tblExp")),
      
      
      tabPanel("Plants and Plots",
              fluidRow(
                tags$br(),
                column(2,
                       textInput("txtPPNameSearch","Search database for:"),
                       actionButton("btnPPSearch","Search")),
                column(2,
                       uiOutput("uiPlantPlotSelect"),
                       checkboxInput("PPExtendedCheck", "Extended Results", value = FALSE)),
                column(2,
                       tags$br(),
                       downloadButton("btnPPDL","Download"))
              ),
              tableOutput("tblPP"),
              tags$br()),
      
      tabPanel("Samples",
               fluidRow(
                 tags$br(),
                 column(2,
                        textInput("txtSampNameSearch","Search database for:"),
                        actionButton("btnSampSearch","Search")),
                 column(2,
                        uiOutput("uiSampleSelect"),
                        uiOutput("uiSampleType"),
                        checkboxInput("sampExtendedCheck", "Extended Results", value = FALSE)),
                 column(2,
                        tags$br(),
                        downloadButton("btnSampDL","Download"))
               ),
               tableOutput("tblSample"),
               tags$br()),
      
      tabPanel("Phenotypes",
               tags$h2("Current Samples:"),
               tags$h2("Coming soon..."),
               tableOutput("tblPheno")),
      tabPanel("Load Data", tags$h2("Coming soon... NO TOUCHY! >:("))
    )
  )
))
