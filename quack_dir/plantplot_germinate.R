plantplottable <- tbl(connect,"plantplot")



PPFields <- reactive({
  if (input$PPExtendedCheck) { 
    PPColz <- "plantplot.id, plantplot.number, plantplot.name, germinatebase.number AS accession, locations.site_name, experiments.experiment_name, plantplot.plantplot_position,
seriesname AS fieldtrial, plantplot.created_on, plantplot.updated_on"
  }
  else{
    PPColz <- paste0("plantplot.number, plantplot.name, seriesname AS fieldtrial,plantplot.created_on")
  }
  return(PPColz)
})


PPSearchName <- eventReactive(input$btnPPSearch,{
  PPNameText <- input$txtPPNameSearch
  return(PPNameText)
},ignoreNULL = F)


PPQueryConstruct <- reactive({
  # ordering <- ""
  # 
  # if (PPSearchName() == ""){
  #   ordering <- "plantplot.number"
  # }
  # else{
  #   ordering <- input$PPSelect  
  # }
  # 
  ordering <- input$PPSelect
  
  if (regexpr("AS", ordering)[1] != -1){
    ordering <- substr(ordering, 1, ((regexpr("AS", ordering)[1])-2))  
  }
  
  
  PPBuildQuery <- paste0("SELECT ",PPFields()," FROM plantplot
                         LEFT JOIN germinatebase ON (plantplot.germinatebase_id = germinatebase.id)
                         LEFT JOIN locations ON (plantplot.locations_id = locations.id)
                         LEFT JOIN experimentdesign ON (plantplot.experimentdesign_id = experimentdesign.id)
                         LEFT JOIN experiments ON (experimentdesign.experiments_id= experiments.id)
                         LEFT JOIN trialseries ON (plantplot.trialseries_id = trialseries.id) 
                         WHERE ",ordering," LIKE \"",paste0("%",PPSearchName(),"%"),"\" ORDER BY ", ordering)

  output$txtQuery <- renderText({PPBuildQuery})
  
  return(PPBuildQuery)
  
})



PPQuery <- reactive({
  req(input$PPSelect)
  
  calcQuery <- dbGetQuery(connect, PPQueryConstruct())
  
  return(calcQuery)
})


output$uiPlantPlotSelect <- renderUI({
 
  # if (PPFields() == "*"){
  #   fieldChoices <- colnames(as.data.frame(plantplottable %>% collect))
  # }
  # else{
  #   fieldChoices <- strsplit(PPFields(),",")[[1]]
  # }
  
  fieldChoices <- strsplit(PPFields(),",")[[1]]
  
  selectInput("PPSelect", "Search Column:",choices = as.list(fieldChoices),
              multiple = F, selected = "name")
})


output$tblPP <- renderTable({as.data.frame(PPQuery())})

output$btnPPDL <- downloadHandler(
  filename = function() {paste0('germinatePlantPlots_', Sys.Date(), '.csv')},
  content = function(file) {write.csv(as.data.frame(PPQuery()), file, row.names=FALSE)}
)