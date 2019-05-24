## R code to connect and interface with IWYP60 Germinate database
## This script collates proteomic data and uploads to the compounddata table of the germinate3 database

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

#### data to import
iwyp_dir <- "iwyp60_data/"
csv_fls <- dir(iwyp_dir, "csv") %>% tibble %>% 
  mutate(measures = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(measures = sapply(strsplit(measures, ".csv"), function(l) l[1])) %>%
  mutate(description = sapply(strsplit(., "_"), function(l) paste0(l[2],l[1],"_",l[3]))) %>%
  mutate(description = sub(pattern = 'Obregon2016_trial', replacement = "CIMMYT2016", x = description)) %>%
  mutate(description = sub(pattern = 'GES20', replacement = "GES", x = description))

traits <- c("Metabolomics-metabolite","Proteomics-functionalbin","Proteomics-peptide")
cat("To import:", paste(traits))

files <- filter(csv_fls, measures %in% traits)

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## get database tables and give useable names
table_names <- dbListTables(con)
rq_tables <- c("experiments","entitytypes","germinatebase","datasets","compounds","compounddata")
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
names(tables) <- rq_tables

## take import file and assemble necessary columns to upload to compounddata table
df <- mutate(files, contents = map(., ~ read_csv(file.path(iwyp_dir, .), col_names = T))) %>% 
  unnest %>%
  mutate(description = paste(description,measures)) %>%
  select(-.,-measures,-experiment_name) %>%
  gather(sample_id, compound_value, -compound, -description, na.rm = T) %>%
  rename(name=compound) %>%
  mutate(name = sub(pattern = " Elke", x = name, replacement = '')) %>% # remove " Elke"
  mutate(name = sub(pattern = " new", x = name, replacement = '')) %>% # remove " new"
  ## link to compound id
  mutate(compound_id = tables$compounds$id[match(name, tables$compounds$name)]) %>%
  ## link to germinatebase_id, entitytype_id w/ 'germinatebase' table
  mutate(germinatebase_id = tables$germinatebase$id[match(sample_id,tables$germinatebase$general_identifier)]) %>%
  mutate(entitytype_id = tables$germinatebase$entitytype_id[match(sample_id,tables$germinatebase$general_identifier)]) %>%
  ## link experiment_id
  mutate(experiment_id = tables$experiments$id[match(sapply(strsplit(description, " "),function(l) l[1]),tables$experiments$description)]) %>%
  ## link dataset id
  mutate(dataset_id = tables$datasets$id[match(description,tables$datasets$description)]) %>%
  ## select required columns
  select(compound_id, germinatebase_id, dataset_id, compound_value)

### subset import to new samples based on interaction of compound_id and dataset_id
new_dat <- subset(df, !(interaction(compound_id, dataset_id) %in% interaction(tables$compounddata$compound_id, tables$compounddata$dataset_id)))

head(tables$compounddata)
head(new_dat)

## APPEND DATA TO TABLE
dbWriteTable(conn = con, name = 'compounddata', value = new_dat, row.names = NA, append = TRUE)

## check updated table
test <- dbReadTable(name = "compounddata", conn=con)
dim(test)
head(test)
tail(test)

## disconnect from database and clean up workspace
dbDisconnect(con)
rm(list=ls())
