## R code to connect and interface with IWYP60 Germinate database
## This script updates datasets table based on import data and locations table

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

##
#### collate data
iwyp_dir <- "iwyp60_data/"

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## get database tables
table_names <- dbListTables(con)
rq_tables <- c("links","datasets","locations","experiments","datasetstates",
               "datasetmembers","datasetmembertypes","datasetpermissions","germinatebase")
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
## give tables names to make calling specific table easier
names(tables) <- rq_tables

### setup datasets table including linking location_id and experiment_id
dat <- dir(iwyp_dir, "csv") %>% tibble %>% 
  mutate(description = sapply(strsplit(., "_"), function(l) paste0(l[2],l[1],"_",l[3]))) %>%
  mutate(datatype = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(datatype = sapply(strsplit(datatype, ".csv"), function(l) l[1])) %>%
  ###
  ## Some of the following are assumptions that need to be checked!!!
  mutate(description = sub(pattern = 'Obregon2016_trial', replacement = "CIMMYT2016", x = description)) %>%
  mutate(description = sub(pattern = 'GES2017', replacement = "GES17", x = description)) %>%
  mutate(description = sub(pattern = 'GES2018', replacement = "GES18", x = description)) %>%
  mutate(description = sub(pattern = 'Obregon2018_SBS', replacement = "Obregon2018_SerixBabax", x = description)) %>%
  mutate(site_name_short = sapply(strsplit(., "_"), function(l) l[2])) %>%
  ## assume all GES sites are GES CR04 - need to make better !!!!!
  #####
  mutate(site_name_short = sub(pattern = "GES", replacement = "GES CR04", x=site_name_short)) %>% 
  mutate(experiment_id = tables$experiments$id[match(description,tables$experiments$description)]) %>% 
  mutate(location_id = tables$locations$id[match(site_name_short, tables$locations$site_name_short)]) %>% 
  select(experiment_id, location_id, description, datatype) %>%
  ## andrew is global contract? probably needs edit ...
  mutate(contact = 'andrew.bowerman@anu.edu.au')

### Remove datasets already existing
new_dat <- subset(dat, !(interaction(description,datatype) %in% interaction(tables$datasets$description,tables$datasets$datatype)))

## APPEND DATA TO EXISTING TABLE datasets
dbWriteTable(conn = con, name = 'datasets', value = new_dat, row.names = NA, append = TRUE)

## check updated table
print(dbReadTable(name = "datasets", conn=con))

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

## disconnect from database and clean up workspace
dbDisconnect(con)
rm(list=ls())
