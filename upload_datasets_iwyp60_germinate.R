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
tables <- lapply(FUN=dbReadTable, X=table_names, conn=con)
## give tables names to make calling specific table easier
names(tables) <- table_names

datasets <- tables[["datasets"]]
locs <- tables[["locations"]]
exps <- tables[["experiments"]]
datastate <- tables[["datasetstates"]]

### setup datasets table including linking location_id and experiment_id
dats <- dir(iwyp_dir, "csv") %>% tibble %>% 
  mutate(description = sapply(strsplit(., ".csv"), function(l) l[1])) %>%
  mutate(datatype = sapply(strsplit(description, "_"), function(l) l[3])) %>%
  select(-.) %>%
  mutate(site_name_short = sapply(strsplit(description, "_"), function(l) l[2])) %>%
  mutate(site_name_short = sub(pattern = "GES", replacement = "GES CR04", x=site_name_short)) %>% ## assume all GES sites are GES CR04 - need to make better
  mutate(experiment_id = exps$id[match(site_name_short,exps$description)]) %>% ## add experiment_id = NEED TO EDIT
  mutate(location_id = locs$id[match(site_name_short, locs$site_name_short)]) %>% ## add location_id
  select(experiment_id, location_id, description, datatype) %>%
  # mutate(created_by = 1) %>% # add created_by id; arbitrary to 1?
  mutate(dataset_state_id = 1) %>% # add dataset_id; 1=public; see datasetstates table
  # mutate(is_external = 0) %>% # add external state 0?
  mutate(contact = 'andrew.bowerman@anu.edu.au')

### Remove datasets already existing
new_dats <- subset(dats, !(description %in% datasets$description))

####
####
## APPEND DATA TO EXISTING TABLE
dbWriteTable(conn = con, name = 'datasets', value = new_dats, row.names = NA, append = TRUE)

## check updated table
print(dbReadTable(name = "datasets", conn=con))

## disconnect from database
dbDisconnect(con)