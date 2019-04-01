library(shiny)
library(RMySQL)
library(dbplyr)
library(dplyr)
library(DT)

pdf(NULL)

shinyServer(function(input, output,session) {
   
  connect <- DBI::dbConnect(RMySQL::MySQL(), host = "127.0.0.1", user = "iwyp60ro", db = "iwyp60_germinate_test")
  
  # connect <- DBI::dbConnect(RMySQL::MySQL(), host = "130.56.33.112", user = "iwyp60ro", db = "iwyp60_germinate_test")
  
  source("accession_germinate.R", local=T)
  
  source("plantplot_germinate.R", local=T)
  
  source("experiments_germinate.R",local=T)
  
  source("plantsamples_germinate.R",local=T)

  
  # NB: when combining two lists to show a display different to a value in a selectInput
  
  # use "split(value,label)"!
  
  # This will display a label different to the value returned by the selectInput

  
  countCalculator <- function(sourceText,sourceTable){
    
    query <- dbGetQuery(connect, paste0("SELECT COUNT(*) FROM ",sourceTable))[,1]
    queryText <- paste0("Total number of ", sourceText,": ", query)
    return(queryText)
  }
  
  
  output$txtAccSummary <- renderText({countCalculator("accessions","germinatebase")})
  
  output$txtExpSummary <- renderText({countCalculator("experiments","experiments")})
  
  output$txtPlantSummary<- renderText({countCalculator("individual plant or plot entries","plantplot")})
  
  output$txtSampleSummary<- renderText({countCalculator("individual samples","plantsample")})


  
  session$onSessionEnded(function() {
    dbDisconnect(connect)
    dev.off(which = dev.cur())
  })
})
