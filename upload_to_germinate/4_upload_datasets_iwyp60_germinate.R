## R code to connect and interface with IWYP60 Germinate database
## This script updates 'datasets' and 'datasetmembers' tables based on import data and locations table

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

#### collate data
iwyp_dir <- "iwyp60_data/"
traits <- c("Harvest", "Lidar", "Biomass", "ASD", "Q2", "Physiology-Raw", "Physiology-BLUE")
compound_sets <- c('Metabolomics-metabolite', 'Proteomics-functionalbin', 'Proteomics-peptide')

## subset csv files
csv_fls <- dir(iwyp_dir, "csv") %>% tibble %>% 
  mutate(datatype = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(datatype = sapply(strsplit(datatype, ".csv"), function(l) l[1])) %>%
  filter(datatype %in% traits | datatype %in% compound_sets)

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## get specific database tables, read into R, and give names
table_names <- dbListTables(con)
rq_tables <- c("links","datasets","locations","experiments","datasetstates", "licenses","licenselogs",
               "datasetmembers","datasetmembertypes","datasetpermissions","datasetmeta", "datasetstates",
               "germinatebase",'usergroups','usergroupmembers')
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
names(tables) <- rq_tables

### setup datasets table including linking location_id and experiment_id
dat <- csv_fls %>%
  mutate(description = sapply(strsplit(., "_"), function(l) paste0(l[2],l[1],"_",l[3]))) %>%
  mutate(datatype = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(datatype = sapply(strsplit(datatype, ".csv"), function(l) l[1])) %>%
  mutate(description = sub(pattern = 'Obregon2016_trial', replacement = "CIMMYT2016", x = description)) %>%
  mutate(description = sub(pattern = 'GES20', replacement = "GES", x = description)) %>%
  mutate(description = ifelse(datatype %in% compound_sets, 
                              yes = paste(description,datatype,sep=' '),
                              no= description)) %>%
  mutate(., source_file = .) %>%
  mutate(year = sapply(strsplit(., "_"), function(l) l[1])) %>%
  mutate(site_name_short = sapply(strsplit(., "_"), function(l) l[2])) %>%
  mutate(site_name_short = ifelse(year == 2017, 
                                  yes = sub(pattern = "GES", replacement = "GES CR04", x=site_name_short),
                                  no = sub(pattern = "GES", replacement = "GES VR11", x=site_name_short))) %>% 
  mutate(experiment_id = tables$experiments$id[match(description,tables$experiments$description)]) %>% 
  mutate(location_id = tables$locations$id[match(site_name_short, tables$locations$site_name_short)]) %>%
  mutate(version = 0.1) %>%
  mutate(created_by = 1) %>%
  mutate(dataset_state_id = 2) %>%
  mutate(contact = 'diep.ganguly@anu.edu.au') %>%
  mutate(description=ifelse(datatype %in% compound_sets, yes=description, no= paste(description, datatype, sep=' '))) %>%
  select(experiment_id, location_id, description, source_file, datatype, version, created_by, dataset_state_id, contact)

### Remove datasets already existing
new_dat <- subset(dat, !(description %in% tables$datasets$description))

## APPEND DATA TO EXISTING TABLE datasets
dbWriteTable(conn = con, name = 'datasets', value = new_dat, row.names = NA, append = TRUE)

## check updated table
print(dbReadTable(name = "datasets", conn=con))

################
## update datasetmembers
a <- dbReadTable(name = "datasets", conn=con) %>%
  mutate(dataset_id = id) %>%
  mutate(datasetmembertype_id = 2) %>%
  select(dataset_id, datasetmembertype_id)

new_a <- subset(a, !(dataset_id%in% tables$datasetmembers$dataset_id))

## APPEND DATA TO EXISTING TABLE datasetmembers
dbWriteTable(conn = con, name = 'datasetmembers', value = new_a, row.names = NA, append = TRUE)

## check updated table
print(dbReadTable(name = "datasetmembers", conn=con))

## update datasetpermissions
a <- dbReadTable(name = "datasets", conn=con) %>%
  mutate(dataset_id = id) %>%
  mutate(user_id = 1) %>%
  mutate(group_id = 1) %>%
  select(dataset_id, user_id, group_id)

new_a <- subset(a, !(dataset_id%in% tables$datasetpermissions$dataset_id))

## APPEND DATA TO EXISTING TABLE datasetpermissions
dbWriteTable(conn = con, name = 'datasetpermissions', value = new_a, row.names = NA, append = TRUE)

## check updated table
print(dbReadTable(name = "datasetpermissions", conn=con))

## disconnect from database and clean up workspace
dbDisconnect(con)
rm(list=ls())
