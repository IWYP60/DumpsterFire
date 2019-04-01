experiments <- tbl(connect,"experiments")


expFields <- reactive({
  if (input$expExtendedCheck) { 
    expColz <- "plantplot.id, plantplot.number, plantplot.name, germinatebase.name AS accession, site_name, experimentdesign.name, plantplot_position, seriesname AS fieldtrial, plantplot.created_on, plantplot.updated_on"
  }
  else{
    expColz <- paste0("plantplot.number,plantplot.name,plantplot.created_on,experiments.experiment_name")
  }
  return(expColz)
})


expGetExpNames <- eventReactive(input$btnExpSearch,{expNameText <- input$experimentSelect
return(expNameText)}, ignoreNULL = F
)


expQueryConstruct <- reactive({
  
  buildexpWhere <- NULL
  
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
  
  expmakeQuery <- NULL
  expmakeQuery <- paste0("SELECT ", expFields()," FROM plantplot
                         LEFT JOIN experimentdesign ON (plantplot.experimentdesign_id = experimentdesign.id)
                         LEFT JOIN experiments ON (experimentdesign.experiments_id = experiments.id)
                         LEFT JOIN germinatebase ON (plantplot.germinatebase_id = germinatebase.id)
                         LEFT JOIN locations ON (plantplot.locations_id = locations.id)
                         LEFT JOIN trialseries ON (plantplot.trialseries_id = trialseries.id) ",expWhere)
  
  output$txtQuery <- renderText({expmakeQuery})
  
  return(expmakeQuery)
  
})


expQuery <- reactive({
  
  calcQuery <- dbGetQuery(connect, expQueryConstruct())
  
  return(calcQuery)
})



output$uiExperimentSelect <- renderUI({selectInput("experimentSelect", "Experiment",
                                                   choices = as.list(as.data.frame(experiments %>% select(experiment_name))),
                                                   multiple = T, selected = "name")
})


output$tblExp <- renderTable({as.data.frame(expQuery())})


output$btnExpDL <- downloadHandler(
  filename = function() {paste0('germinateExperimentPlants_', Sys.Date(), '.csv')},
  content = function(file) {write.csv(as.data.frame(expQuery()), file, row.names=FALSE)}
)