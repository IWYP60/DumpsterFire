plantplottable <- tbl(connect,"plantplot")



PPFields <- reactive({
  if (input$PPExtendedCheck) { 
    PPColz <- "*"
  }
  else{
    PPColz <- paste0("number,name,trialseries_id,created_on")
  }
  return(PPColz)
})


PPSearchName <- eventReactive(input$btnPPSearch,{
  PPNameText <- input$txtPPNameSearch
  return(PPNameText)
},ignoreNULL = F)


PPQueryConstruct <- reactive({
  ordering <- ""
  
  if (PPSearchName() == ""){
    ordering <- "number"
  }
  else{
    ordering <- input$PPSelect  
  }
  
  
  PPBuildQuery <- paste0("SELECT ",PPFields()," FROM plantplot WHERE ",input$PPSelect," LIKE \"",paste0("%",PPSearchName(),"%"),"\" ORDER BY ", ordering)
  
  
  output$txtQuery <- renderText({PPBuildQuery})
  return(PPBuildQuery)
  
})


PPQuery <- reactive({
  req(input$PPSelect)
  
  calcQuery <- dbGetQuery(connect, PPQueryConstruct())
  
  return(calcQuery)
})


output$uiPlantPlotSelect <- renderUI({
  
  if (PPFields() == "*"){
    fieldChoices <- colnames(as.data.frame(plantplottable %>% collect))
  }
  else{
    fieldChoices <- strsplit(PPFields(),",")[[1]]
  }
  
  selectInput("PPSelect", "Search Column:",choices = as.list(fieldChoices),
              multiple = F, selected = "name")
})


output$tblPP <- renderTable({as.data.frame(PPQuery())})

output$btnPPDL <- downloadHandler(
  filename = function() {paste0('germinatePlantPlots_', Sys.Date(), '.csv')},
  content = function(file) {write.csv(as.data.frame(PPQuery()), file, row.names=FALSE)}
)