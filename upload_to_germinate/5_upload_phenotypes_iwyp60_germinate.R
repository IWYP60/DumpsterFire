## R code to connect and interface with IWYP60 Germinate database
## This script populates units and phenotypes table

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

### assemble all traits defined in keyfile
out_traits <- NULL

## ugh for loop because no-one followed data standards ...
for(i in csv_fls$.){
  a <- read_csv(file.path(iwyp_dir, i)) %>%
    gather(trait, value, na.rm = T) %>%
    mutate(file = i) %>%
    mutate(datatype = sapply(strsplit(file, "_"), function(l) l[4])) %>%
    mutate(datatype = sapply(strsplit(datatype, ".csv"), function(l) l[1])) %>%
    mutate(description = sapply(strsplit(trait, "_"), function(l) l[1])) %>%
    mutate(unit_abbreviation = sapply(strsplit(trait, "_"), function(l) l[2])) %>%
    mutate(measure_id = sapply(strsplit(trait, "_"), function(l) l[3])) %>%
    filter(description %in% keyfile$short_name)
  
  out_traits <- rbind(a, out_traits)
}

## see files and data sources imported
table(out_traits$datatype)
table(out_traits$description)
head(out_traits)

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## get database tables and give useable names
table_names <- dbListTables(con)
rq_tables <- c("phenotypes","units")
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
names(tables) <- rq_tables

## assemble units table using keyfile
dat_unit <- select(out_traits, unit_abbreviation) %>% unique %>%
  mutate(unit_name = units_keyfile$unit_name[match(unit_abbreviation, units_keyfile$unit_abbreviation)]) %>%
  mutate(unit_description = units_keyfile$unit_description[match(unit_abbreviation, units_keyfile$unit_abbreviation)])

## check for pre-existing units
new_dat2 <- subset(dat_unit, !(unit_abbreviation %in% tables$units$unit_abbreviation))

## APPEND table
dbWriteTable(conn = con, name = 'units', value = new_dat2, row.names = NA, append = TRUE)

## check table
a <- dbReadTable(name = "units", conn=con)
head(a)
tail(a)

## assemble phenotypes
dat <- mutate(out_traits, unit_id = a$id[match(unit_abbreviation, a$unit_abbreviation)]) %>% 
  ## add full trait name and description from keyfile 
  mutate(name = keyfile$name[match(short_name, keyfile$short_name)]) %>%
  mutate(description = keyfile$Description[match(short_name, keyfile$short_name)]) %>%
  mutate(name = ifelse(is.na(measure_id) == F, yes= paste(name,measure_id,sep = ';'), no=name)) %>%
  mutate(short_name = ifelse(is.na(measure_id) == F, yes= paste(short_name,measure_id,sep = ';'), no=short_name)) %>%
  ## required fields for upload
  select(name, short_name, description, datatype, unit_id) %>%
  unique

#### Remove pre-existing entries
new_dat <- subset(dat, !(interaction(name, short_name) %in% interaction(tables$phenotypes$name, tables$phenotypes$short_name)))

## APPEND TABLES
dbWriteTable(conn = con, name = 'phenotypes', value = new_dat, row.names = NA, append = TRUE)

## check updated table
print(dbReadTable(name = "phenotypes", conn=con))

## disconnect from database and clean up workspace
dbDisconnect(con)
rm(list=ls())
