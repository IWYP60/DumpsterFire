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

## Update compouds table with proteomic and metabolimic markers
cat("To import:", paste(traits))

## setup compounds table for upload
dat <- subset(csv_fls, description %in% traits) %>%
  mutate(contents = map(., ~ read_csv(file.path(iwyp_dir, .), col_names = T))) %>% 
  unnest %>% 
  select(description, metabolite, func_bin, peptide) %>%
  gather(compound_class, name, -description, na.rm = T) %>%
  mutate(compound_class = sapply(strsplit(description,"-"), function(l) l[2])) %>%
  mutate(description = sapply(strsplit(description,"-"), function(l) l[1])) %>%
  mutate(name = sub(pattern = " Elke", x = name, replacement = '')) %>% # remove " Elke"
  mutate(name = sub(pattern = " new", x = name, replacement = '')) # remove " new"

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## get database tables
table_names <- dbListTables(con)
rq_tables <- c("compounds")
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
## give tables names to make calling specific table easier
names(tables) <- rq_tables

#### Remove compounds already in cmp table
new_dat <- subset(dat, !(name %in% tables$compounds$name))

####
## APPEND DATA TO TABLE
## this can be changed to overwrite to replace entire compounds table - however this did not work well when trialled so BE CAREFUL
dbWriteTable(conn = con, name = 'compounds', value = new_dat, row.names = NA, append = TRUE)

## check updated table
test <- dbReadTable(name = "compounds", conn=con)

## disconnect from database and clean up workspace
dbDisconnect(con)
rm(list=ls())
  