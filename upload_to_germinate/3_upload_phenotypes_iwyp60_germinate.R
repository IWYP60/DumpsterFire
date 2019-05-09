## R code to connect and interface with IWYP60 Germinate database
## This script updates datasets table based on import data and locations table

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

#### collate data
iwyp_dir <- "iwyp60_data/"
traits <- c("Harvest", "Resp", "Lidar", "Biomass", "ASD", "Q2", "Physiology-Raw", "Physiology-BLUE")

csv_fls <- dir(iwyp_dir, "csv") %>% tibble %>% 
  mutate(description = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(description = sapply(strsplit(description, ".csv"), function(l) l[1])) %>%
  filter(description %in% traits)

keyfile <- read_delim(file.path(iwyp_dir, "Phenotypes_README.txt"), delim = '\t')

dat <- mutate(csv_fls, datatype = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(datatype = sapply(strsplit(datatype, ".csv"), function(l) l[1])) %>%
  mutate(description = sapply(strsplit(., "_"), function(l) paste0(l[2],l[1],"_",l[3]))) %>%
  mutate(site_name_short = sapply(strsplit(., "_"), function(l) l[2])) %>%
  ## assume all GES sites are GES CR04 - need to make better !!!!!
  mutate(site_name_short = sub(pattern = "GES", replacement = "GES CR04", x=site_name_short)) %>% 
  mutate(experiment_id = tables$experiments$id[match(description,tables$experiments$description)]) %>% 
  mutate(location_id = tables$locations$id[match(site_name_short, tables$locations$site_name_short)]) %>% 
  select(experiment_id, location_id, description, datatype) %>%
  ## andrew is global contract? probably needs edit ...
  mutate(contact = 'andrew.bowerman@anu.edu.au')

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## get database tables
table_names <- dbListTables(con)
rq_tables <- c("germinatebase","phenotypes","experiments","experimenttypes","units")
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
## give tables names to make calling specific table easier
names(tables) <- rq_tables

#### Remove compounds already in cmp table
new_dat <- subset(dat, !(name %in% tables$compounds$name))

## APPEND DATA TO TABLE
dbWriteTable(conn = con, name = 'phenotypes', value = new_dat, row.names = NA, append = TRUE)

## check updated table
test <- dbReadTable(name = "phenotypes", conn=con)

## disconnect from database and clean up workspace
dbDisconnect(con)
rm(list=ls())
