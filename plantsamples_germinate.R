plantsample <- tbl(connect,"plantsample")


sampFields <- reactive({
  if (input$sampExtendedCheck) { 
    sampColz <- "plantsample.id, plantsample.name, parentsample.name AS parent, plantplot.name AS plantname,
    plantsample.altname, tissue.name AS tissue, samplestage.name AS growthstage, experimenttypes.description AS samplepurpose,
    plantsample.weight, plantsample.sampled_on, plantsample.details, plantsample.created_on, plantsample.updated_on"
  }
  else{
    sampColz <- paste0("plantsample.name, parentsample.name AS parentsample, plantplot.name AS plantname, tissue.name AS tissue,
                       samplestage.name AS growthstage,experimenttypes.description AS samplepurpose, plantsample.created_on")
  }
  return(sampColz)
})



output$uiSampleSelect<- renderUI({
  
  if (sampFields() == "*"){
    fieldChoices <- colnames(as.data.frame(plantsample %>% collect))
  }
  else{
    fieldChoices <- strsplit(sampFields(),",")[[1]]
  }
  selectInput("sampFieldSelect", "Search Column:", choices = fieldChoices, multiple = F, selected = "name")
})


output$tblSample <- renderTable({as.data.frame(sampQuery())})


sampSearchName <- eventReactive(input$btnSampSearch,{
  sampNameText <- input$txtSampNameSearch
  return(sampNameText)
},ignoreNULL = F)



sampQueryConstruct <- reactive({
  ordering <- ""
  
  if (sampSearchName() == ""){
    ordering <- "plantsample.name"
  }
  else{
    ordering <- input$sampFieldSelect  
  }
  
  if (regexpr("AS", ordering)[1] != -1){
    ordering <- substr(ordering, 1, ((regexpr("AS", ordering)[1])-2))  
  }
  
  sampBuildQuery <- paste0("SELECT ",sampFields()," FROM plantsample
                          LEFT JOIN plantplot ON (plantsample.plantplot_id = plantplot.id)
                          LEFT JOIN tissue ON (plantsample.tissue_id = tissue.id)
                          LEFT JOIN samplestage ON (plantsample.samplestage_id = samplestage.id)
                          LEFT JOIN experimenttypes ON (plantsample.experimenttypes_id = experimenttypes.id)
                          INNER JOIN plantsample AS parentsample ON (plantsample.parentsample_id = parentsample.id)
                          WHERE ",ordering," LIKE \"",paste0("%",sampSearchName(),"%"),"\" ORDER BY ", ordering)
  
  output$txtQuery <- renderText({sampBuildQuery})
  return(sampBuildQuery)
})



sampQuery <- reactive({
  req(input$sampFieldSelect)
  
  calcQuery <- dbGetQuery(connect, sampQueryConstruct())
  
  return(calcQuery)
})



output$btnSampleDL <- downloadHandler(
  filename = function() {paste0('germinateSamples_', Sys.Date(), '.csv')},
  content = function(file) {write.csv(as.data.frame(sampQuery()), file, row.names=FALSE)}
)
