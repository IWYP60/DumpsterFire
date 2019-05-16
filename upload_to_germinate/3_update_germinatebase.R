## R code to connect and interface with IWYP60 Germinate database
## This script updates germinatebase to have location_ids attached to sample_ and plant/pot_IDs

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

#### collate sample ID across datasets
iwyp_dir <- "iwyp60_data/"
traits <- c("Harvest", "Lidar", "Biomass", "ASD", "Q2", "Physiology-Raw", "Physiology-BLUE")

## subset to files that contains Panel info
csv_fls <- dir(iwyp_dir, "csv") %>% tibble %>% 
  mutate(datatype = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(datatype = sapply(strsplit(datatype, ".csv"), function(l) l[1])) %>%
  filter(datatype %in% traits)

sample_ids <- NULL
for(i in csv_fls$.){
  a <- read_csv(file.path(iwyp_dir, i)) %>%
    select(ID) %>%
    mutate(file = i)
  
  sample_ids <- rbind(a, sample_ids)
}

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## get specific database tables, read into R, and give names
table_names <- dbListTables(con)
rq_tables <- c("entitytypes","locations","germinatebase","locationtypes","institutions","biologicalstatus")
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
names(tables) <- rq_tables

## link sample IDs to location_ids
sample_ids <- unique(sample_ids) %>%
  mutate(year = sapply(strsplit(file, "_"), function(l) l[1])) %>%
  mutate(site_name_short = sapply(strsplit(file, "_"), function(l) l[2])) %>%
  mutate(site_name_short = ifelse(year == 2017, 
                                  yes = sub(pattern = "GES", replacement = "GES CR04", x=site_name_short),
                                  no = sub(pattern = "GES", replacement = "GES VR11", x=site_name_short))) %>%
  mutate(location_id = tables$locations$id[match(site_name_short, tables$locations$site_name_short)]) %>%
  mutate(institution_id = ifelse(site_name_short == "Obregon", yes = 4, no = 1))

## now link location ids into germinatebase
a <- tables$germinatebase %>%
  mutate(location_id = sample_ids$location_id[match(general_identifier, sample_ids$ID)]) %>%
  mutate(location_id = ifelse(is.na(location_id) == T, 
                              yes = sample_ids$location_id[match(number, sample_ids$ID)],
                                no = location_id)) %>%
  mutate(location_id = ifelse(is.na(location_id) == T, 
                              yes = sample_ids$location_id[match(name, sample_ids$ID)],
                              no = location_id)) %>%
  mutate(institution_id = sample_ids$institution_id[match(general_identifier, sample_ids$ID)]) %>%
  mutate(institution_id = ifelse(is.na(institution_id) == T, 
                              yes = sample_ids$institution_id[match(number, sample_ids$ID)],
                              no = institution_id)) %>%
  mutate(institution_id = ifelse(is.na(institution_id) == T, 
                              yes = sample_ids$institution_id[match(name, sample_ids$ID)],
                              no = institution_id))

## OVERWRITE germinatebase table with new info
# dbWriteTable(conn = con, name = 'germinatebase', value = a, row.names=FALSE, overwrite = TRUE)

## check updated table
w <- print(dbReadTable(name = "germinatebase", conn=con))

## disconnect from database and clean up workspace
dbDisconnect(con)
rm(list=ls())
