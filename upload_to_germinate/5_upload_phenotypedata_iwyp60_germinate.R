## R code to connect and interface with IWYP60 Germinate database
## This script populates phenotype data

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

#### collate data
iwyp_dir <- "iwyp60_data/"
traits <- c("Harvest", "Lidar", "Biomass", "ASD", "Q2", "Physiology-Raw", "Physiology-BLUE")

keyfile <- read_delim(file.path(iwyp_dir, "Phenotypes_README.txt"), delim = '\t')
units_keyfile <- read_delim(file.path(iwyp_dir, "Units_README.txt"), delim = '\t')

csv_fls <- dir(iwyp_dir, "csv") %>% tibble %>% 
  mutate(datatype = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(datatype = sapply(strsplit(datatype, ".csv"), function(l) l[1])) %>%
  filter(datatype %in% traits)

### assemble phenotype data
out_traits <- NULL

## ugh for loop because no-one followed data standards ...
## NOTE: make sure there is an ID column in spreadsheets that contain either SampleID, AccessionID, AccessionName, or PlantPlotID
for(i in csv_fls$.){
  a <- read_csv(file.path(iwyp_dir, i)) %>%
    gather(trait, phenotype_value, -ID, na.rm = T) %>%
    mutate(file = i) %>%
    mutate(datatype = sapply(strsplit(file, "_"), function(l) l[4])) %>%
    mutate(datatype = sapply(strsplit(datatype, ".csv"), function(l) l[1])) %>%
    mutate(short_name = sapply(strsplit(trait, "_"), function(l) l[1])) %>%
    mutate(unit_abbreviation = sapply(strsplit(trait, "_"), function(l) l[2])) %>%
    mutate(measure_id = sapply(strsplit(trait, "_"), function(l) l[3])) %>%
    filter(short_name %in% keyfile$short_name)
  
  out_traits <- rbind(a, out_traits)
}

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## get database tables
table_names <- dbListTables(con)
rq_tables <- c("germinatebase", "datasets", "locations", "treatments", "trialseries", "phenotypes", "locations", "phenotypedata")
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
## give tables names to make calling specific table easier
names(tables) <- rq_tables

## Populate table for upload
dat <- mutate(out_traits, description = sapply(strsplit(file, "_"), function(l) paste0(l[2],l[1],"_",l[3]))) %>%
  ## Some of the following are assumptions that need to be checked!!!
  mutate(description = sub(pattern = 'Obregon2016_trial', replacement = "CIMMYT2016", x = description)) %>%
  mutate(description = sub(pattern = 'GES2017', replacement = "GES17", x = description)) %>%
  mutate(description = sub(pattern = 'GES2018', replacement = "GES18", x = description)) %>%
  mutate(description = sub(pattern = 'Obregon2018_SBS', replacement = "Obregon2018_SerixBabax", x = description)) %>%
  mutate(phenotype_id = tables$phenotypes$id[match(short_name, tables$phenotypes$short_name)]) %>%
  ## germinate_id based on SampleID, AccessionID, AccessionName, or PlantPlotID
  mutate(germinatebase_id = tables$germinatebase$id[match(ID, tables$germinatebase$general_identifier)]) %>%
  mutate(germinatebase_id = ifelse(is.na(germinatebase_id) == TRUE, yes = 
                                     tables$germinatebase$id[match(ID, tables$germinatebase$name)], no = germinatebase_id)) %>%
  mutate(dataset_id = tables$datasets$id[match(description,tables$datasets$description)]) %>%
  mutate(year = sapply(strsplit(file, "_"), function(l) l[1])) %>%
  mutate(site_name_short = sapply(strsplit(file, "_"), function(l) l[2])) %>%
  ## assume all GES sites are GES CR04 - need to make better !!!!!
  mutate(site_name_short = ifelse(year == 2017, yes = sub(pattern = "GES", replacement = "GES CR04", x=site_name_short), 
                                  no = sub(pattern = "GES", replacement = "GES VR11", x=site_name_short))) %>% 
  mutate(location_id = tables$locations$id[match(site_name_short, tables$locations$site_name_short)]) %>%
  # mutate(treatment_id = tables$treatments$id[match(name, tables$treatments$name)]) %>%
  # mutate(trialseries_id = tables$trialseries$id[match(seriesname, tables$trialseries$seriesname)]) %>%
  select(phenotype_id, germinatebase_id, phenotype_value, dataset_id, location_id)

#### Remove pre-existing entries
new_dat <- subset(dat, !(interaction(phenotype_id, germinatebase_id, dataset_id) %in% 
    interaction(tables$phenotypedata$phenotype_id, tables$phenotypedata$germinatebase_id, tables$phenotypedata$dataset_id)))

## APPEND TABLES
dbWriteTable(conn = con, name = 'phenotypedata', value = new_dat, row.names = NA, append = TRUE)

## check updated table
print(dbReadTable(name = "phenotypedata", conn=con))

## disconnect from database and clean up workspace
dbDisconnect(con)
rm(list=ls())
