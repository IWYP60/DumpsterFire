#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(RMySQL)
library(dbplyr)
library(dplyr)
library(DT)

pdf(NULL)


shinyServer(function(input, output,session) {
   
  connect <- DBI::dbConnect(RMySQL::MySQL(), host = "127.0.0.1", user = "iwyp60ro", db = "iwyp60_germinate_test")
  
  germinatebase <- tbl(connect,"germinatebase")
  
  experiments <- tbl(connect,"experiments")
  
  # text <- reactive(paste0("%",input$txtAccSearch,"%"))

  accSearchName <- eventReactive(input$btnAccSearch,{
                  accNameText <- input$txtAccNameSearch
                  return(accNameText)
                  },ignoreNULL = F
                  )
  
  # accSearchNotes <- eventReactive(input$btnAccSearch,{
  #                 accNotesText <- input$txtAccNameSearch
  #                 return(accNotesText)
  #                 }
  #                 )
  
  field <- reactive(input$fieldSelect)
  
  accFields <- reactive({
    if (input$accExtendedCheck) { 
      accColz <- "*"
    }
    else{
      accColz <- paste0("number,name,notes,created_on")
    }
    return(accColz)
  })
  
  expFields <- reactive({
    if (input$expExtendedCheck) { 
      expColz <- "plantplot.*,experiments.experiment_name"
    }
    else{
      expColz <- paste0("plantplot.number,plantplot.name,plantplot.created_on,experiments.experiment_name")
    }
    return(expColz)
  })
  
  accQueryConstruct <- reactive({
    ordering <- ""
    
    if (accSearchName() == ""){
      ordering <- "number"
    }
    else{
      ordering <- input$accFieldSelect  
    }
    
    # if (input$accExtendedCheck) { 
    #   tehcolz <- "*"
    # }
    # else{
    #   tehcolz <- paste0("number,name,notes,created_on")
    # }
    
    accBuildQuery <- paste0("SELECT ",accFields()," FROM germinatebase WHERE ",input$accFieldSelect," LIKE \"",paste0("%",accSearchName(),"%"),"\" ORDER BY ", ordering)
    
    output$txtQuery <- renderText({accBuildQuery})
    return(accBuildQuery)
    
  })
  
  accQuery <- reactive({
                req(input$accFieldSelect)
                # req(input$fieldSelect)
                # searchQuery1 <- paste0("%",text1(),"%")
                # searchQuery <- paste0("%",accSearchName(),"%")
                # searchQuery2 <- paste0("%",accSearchNotes(),"%")
                # searchField <- parseQueryString(paste0(%field()%))
                # column <- paste0(field())
                
                # calcQuery <- germinatebase %>% filter_(name %LIKE% "%EGYPT%")
                
                # calcQuery <- germinatebase %>% filter(input$fieldSelect %LIKE% searchQuery1)
                # Try using filter_ with eval(parse within the 
                # calcQuery <- eval(parse(text=paste0("germinatebase %>% filter_(",input$fieldSelect, " \\%LIKE\\% \"", searchQuery1, "\")")))
                # calcQuery <- germinatebase %>% filter(name %like% searchQuery1 %AND% notes %like% searchQuery2)
                
                # calcQuery <- dbGetQuery(connect, paste0("SELECT * FROM germinatebase WHERE ",input$fieldSelect," LIKE \"",searchQuery,"\""))
                
                calcQuery <- dbGetQuery(connect, accQueryConstruct())
                
                
                return(calcQuery)
                })

  
  expGetExpNames <- eventReactive(input$btnExpSearch,{expNameText <- input$experimentSelect
                    return(expNameText)}, ignoreNULL = F
                    )
                    
  
  expQueryConstruct <- reactive({
                # req(!is.null(input$experimentSelect))
                
                buildexpWhere <- NULL
                
                # if (is.null(test)){
                #   
                #   test = ""
                # } else if (length(test) == 1){
                #   print(test)
                # } else{
                #   
                #   for (x in q){
                #     test <- c(test,x)
                #   }
                # }
    
                if (length(expGetExpNames()) == 0){
                  
                  expWhere <- ""
                  
                }
                else {
                  
                  for (x in expGetExpNames()){
                    buildexpWhere <- paste(shQuote(x),buildexpWhere,sep=",")
                  }
                  buildexpWhere <- substr(buildexpWhere,1,nchar(buildexpWhere)-1)
                  expWhere <- paste0("WHERE experiments.experiment_name IN (", buildexpWhere, ")")
                  
                }
                
    
                # expmakeQuery <- dbGetQuery(connect, paste0("SELECT plantplot.*,experiments.experiment_name FROM plantplot INNER JOIN experimentdesign ON (plantplot.experimentdesign_id = experimentdesign.id) INNER JOIN experiments ON (experimentdesign.experiments_id = experiments.id) ",expWhere))
                expmakeQuery <- NULL
                expmakeQuery <- paste0("SELECT ", expFields()," FROM plantplot INNER JOIN experimentdesign ON (plantplot.experimentdesign_id = experimentdesign.id) INNER JOIN experiments ON (experimentdesign.experiments_id = experiments.id) ",expWhere)
                
                output$txtQuery <- renderText({expmakeQuery})
                
                return(expmakeQuery)
    
              })
  
  
  # output$uiGerminatebaseSelect <- renderUI({selectInput("accFieldSelect", "Search Column:",
  #                                                       choices = colnames(as.data.frame(germinatebase %>% collect)),
  #                                                       multiple = F, selected = "name")
  #                                                       })
  
  expQuery <- reactive({
    # req(input$experimentSelect)

    
    calcQuery <- dbGetQuery(connect, expQueryConstruct())
    
    
    return(calcQuery)
  })
  
  output$uiGerminatebaseSelect <- renderUI({
      
    if (accFields() == "*"){
      fieldChoices <- colnames(as.data.frame(germinatebase %>% collect))
    }
    else{
      fieldChoices <- strsplit(accFields(),",")[[1]]
    }
    
    selectInput("accFieldSelect", "Search Column:", choices = fieldChoices, multiple = F, selected = "name")
    
  })
                                                        
    
  output$uiExperimentSelect <- renderUI({selectInput("experimentSelect", "Experiment",
                                                    choices = as.list(as.data.frame(experiments %>% select(experiment_name))),
                                                    multiple = T, selected = "name")
                                                    })
 

  countCalculator <- function(sourceText,sourceTable){
    
    query <- dbGetQuery(connect, paste0("SELECT COUNT(*) FROM ",sourceTable))[,1]
    queryText <- paste0("Total number of ", sourceText,": ", query)
    return(queryText)
    
  }
  
  output$txtAccSummary <- renderText({countCalculator("accessions","germinatebase")})
  output$txtExpSummary <- renderText({countCalculator("experiments","experiments")})
  output$txtPlantSummary<- renderText({countCalculator("individual plant or plot entries","plantplot")})
  output$txtSampleSummary<- renderText({countCalculator("individual samples","plantsample")})
  

  # output$tblAcc <- renderTable({
  #   if (input$accExtendedCheck) { 
  #     tehrowz <- -1
  #   }
  #   else{
  #     tehrowz <- c(3:4,22:23)
  #     }
  #   
  #   as.data.frame(accQuery())[,tehrowz]
  #   
  # })

  output$tblAcc <- renderTable({as.data.frame(accQuery())})
  
  output$btnAccDL <- downloadHandler(
    filename = function() {paste0('germinateAccesions_', Sys.Date(), '.csv')},
    content = function(file) {write.csv(as.data.frame(accQuery()), file, row.names=FALSE)}
  )
  
  output$tblExp <- renderTable({as.data.frame(expQuery())})
  
  output$btnExpDL <- downloadHandler(
    filename = function() {paste0('germinateExperimentPlants_', Sys.Date(), '.csv')},
    content = function(file) {write.csv(as.data.frame(expQuery()), file, row.names=FALSE)}
  )
  
  
  session$onSessionEnded(function() {
    dbDisconnect(connect)
    dev.off(which = dev.cur())
  })
  
  
})
