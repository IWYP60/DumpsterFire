## R code to connect and interface with IWYP60 Germinate database
## This script collates proteomic (function bins and peptides) and metabolomic IDs and updates compound table

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

#### collate data
iwyp_dir <- "iwyp60_data/"
traits <- c("Metabolomics-metabolite","Proteomics-functionalbin","Proteomics-peptide")
csv_fls <- dir(iwyp_dir, "csv") %>% tibble %>% 
  mutate(description = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(description = sapply(strsplit(description, ".csv"), function(l) l[1])) %>%
  filter(description %in% traits)

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## get database tables and give useable names
table_names <- dbListTables(con)
rq_tables <- c("compounds","units")
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
names(tables) <- rq_tables

## setup compounds table for upload
dat <- subset(csv_fls, description %in% traits) %>%
  mutate(contents = map(., ~ read_csv(file.path(iwyp_dir, .), col_names = T))) %>% 
  unnest %>% 
  select(description, compound) %>%
  rename(name = compound) %>%
  mutate(compound_class = sapply(strsplit(description,"-"), function(l) l[2])) %>%
  mutate(description = sapply(strsplit(description,"-"), function(l) l[1])) %>%
  mutate(unit_id = 1) %>%
  mutate(name = sub(pattern = " Elke", x = name, replacement = '')) %>% # remove " Elke"
  mutate(name = sub(pattern = " new", x = name, replacement = '')) # remove " new"

#### Remove compounds already in cmp table
new_dat <- subset(dat, !(name %in% tables$compounds$name))

## APPEND DATA TO TABLE
dbWriteTable(conn = con, name = 'compounds', value = new_dat, row.names = NA, append = TRUE)

## check updated table
print(dbReadTable(name = "compounds", conn=con))

## disconnect from database and clean up workspace
dbDisconnect(con)
rm(list=ls())
