germinatebase <- tbl(connect,"germinatebase")



accSearchName <- eventReactive(input$btnAccSearch,{
  accNameText <- input$txtAccNameSearch
  return(accNameText)
},ignoreNULL = F)



accFields <- reactive({
  if (input$accExtendedCheck) { 
    accColz <- "*"
  }
  else{
    accColz <- paste0("number,name,notes,created_on")
  }
  return(accColz)
})


accQueryConstruct <- reactive({
  ordering <- ""
  
  if (accSearchName() == ""){
    ordering <- "number"
  }
  else{
    ordering <- input$accFieldSelect  
  }
  
  accBuildQuery <- paste0("SELECT ",accFields()," FROM germinatebase WHERE ",input$accFieldSelect," LIKE \"",paste0("%",accSearchName(),"%"),"\" ORDER BY ", ordering)

  output$txtQuery <- renderText({accBuildQuery})
  return(accBuildQuery)
})


accQuery <- reactive({
  req(input$accFieldSelect)
  
  calcQuery <- dbGetQuery(connect, accQueryConstruct())
  
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




output$tblAcc <- renderTable({as.data.frame(accQuery())})


output$btnAccDL <- downloadHandler(
  filename = function() {paste0('germinateAccesions_', Sys.Date(), '.csv')},
  content = function(file) {write.csv(as.data.frame(accQuery()), file, row.names=FALSE)}
)