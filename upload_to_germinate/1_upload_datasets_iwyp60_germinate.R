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

## get specific database tables, read into R, and give names
table_names <- dbListTables(con)
rq_tables <- c("links","datasets","locations","experiments","datasetstates", "licenses","licenselogs",
               "datasetmembers","datasetmembertypes","datasetpermissions","datasetmeta", "datasetstates",
               "germinatebase",'usergroups','usergroupmembers')
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
names(tables) <- rq_tables

### setup datasets table including linking location_id and experiment_id
dat <- dir(iwyp_dir, "csv") %>% tibble %>%
  mutate(description = sapply(strsplit(., "_"), function(l) paste0(l[2],l[1],"_",l[3]))) %>%
  mutate(datatype = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(datatype = sapply(strsplit(datatype, ".csv"), function(l) l[1])) %>%
  ## Some of the following are assumptions that need to be checked!!!
  mutate(description = sub(pattern = 'Obregon2016_trial', replacement = "CIMMYT2016", x = description)) %>%
  mutate(description = sub(pattern = 'GES2017', replacement = "GES17", x = description)) %>%
  mutate(description = sub(pattern = 'GES2018', replacement = "GES18", x = description)) %>%
  mutate(description = sub(pattern = 'Obregon2018_SBS', replacement = "Obregon2018_SerixBabax", x = description)) %>%
  mutate(., source_file = .) %>%
  mutate(year = sapply(strsplit(., "_"), function(l) l[1])) %>%
  mutate(site_name_short = sapply(strsplit(., "_"), function(l) l[2])) %>%
  mutate(site_name_short = ifelse(year == 2017, 
                                  yes = sub(pattern = "GES", replacement = "GES CR04", x=site_name_short),
                                  no = sub(pattern = "GES", replacement = "GES VR11", x=site_name_short))) %>% 
  mutate(experiment_id = tables$experiments$id[match(description,tables$experiments$description)]) %>% 
  mutate(location_id = tables$locations$id[match(site_name_short, tables$locations$site_name_short)]) %>%
  mutate(dataset_state_id = 1) %>%
  mutate(contact = 'andrew.bowerman@anu.edu.au') %>%
  select(experiment_id, location_id, description, source_file, datatype, dataset_state_id, contact)
  

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
