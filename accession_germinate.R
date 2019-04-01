germinatebase <- tbl(connect,"germinatebase")



accSearchName <- eventReactive(input$btnAccSearch,{
  accNameText <- input$txtAccNameSearch
  return(accNameText)
},ignoreNULL = F)



accFields <- reactive({
  if (input$accExtendedCheck) { 
    # accColz <- "*"
    accColz <- "germinatebase.id, general_identifier, number, name, bank_number, 
breeders_code, taxonomies.genus,taxonomies.species,subtaxa.taxonomic_identifier AS subtaxa, institution_id, plant_passport, 
donor_code, donor_number, acqdate, collnumb, colldate, duplsite, biologicalstatus.sampstat AS biologicalstatus,
collsrc_id, location_id, notes, germinatebase.created_on, germinatebase.updated_on"
  }
  else{
    accColz <- paste0("number,name,notes,germinatebase.created_on")
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
  
  if (regexpr("AS", ordering)[1] != -1){
    ordering <- substr(ordering, 1, ((regexpr("AS", ordering)[1])-2))  
  }
  
  accBuildQuery <- paste0("SELECT ",accFields()," FROM germinatebase 
                          LEFT JOIN taxonomies ON (germinatebase.taxonomy_id = taxonomies.id)
                          LEFT JOIN subtaxa ON (germinatebase.subtaxa_id = subtaxa.id)
                          LEFT JOIN biologicalstatus ON (germinatebase.biologicalstatus_id = biologicalstatus.id)
                          WHERE ",ordering," LIKE \"",paste0("%",accSearchName(),"%"),"\" ORDER BY ", ordering)

  output$txtQuery <- renderText({accBuildQuery})
  return(accBuildQuery)
})


accQuery <- reactive({
  req(input$accFieldSelect)
  
  calcQuery <- dbGetQuery(connect, accQueryConstruct())
  
  return(calcQuery)
})


output$uiGerminatebaseSelect <- renderUI({
  
  # if (accFields() == "*"){
  #   fieldChoices <- colnames(as.data.frame(germinatebase %>% collect))
  # }
  # else{
  #   fieldChoices <- strsplit(accFields(),",")[[1]]
  # }
  
  fieldChoices <- strsplit(accFields(),",")[[1]]
  
  selectInput("accFieldSelect", "Search Column:", choices = fieldChoices, multiple = F, selected = "name")
})




output$tblAcc <- renderTable({as.data.frame(accQuery())})


output$btnAccDL <- downloadHandler(
  filename = function() {paste0('germinateAccessions_', Sys.Date(), '.csv')},
  content = function(file) {write.csv(as.data.frame(accQuery()), file, row.names=FALSE)}
)