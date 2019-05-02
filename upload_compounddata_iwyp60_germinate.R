## R code to connect and interface with IWYP60 Germinate database
## This script collates proteomic data and uploads to the compounddata table to the germinate3 database

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

#### data to import
iwyp_dir <- "iwyp60_data/"
csv_fls <- dir(iwyp_dir, "csv") %>% tibble %>% 
  mutate(measures = sapply(strsplit(., "_"), function(l) l[3])) %>%
  mutate(measures = sapply(strsplit(measures, ".csv"), function(l) l[1])) %>%
  mutate(description = sapply(strsplit(., "_"), function(l) paste(l[2],l[1],sep='')))

traits <- c("Metabolomics-metabolite","Proteomics-functionalbin","Proteomics-peptide")
cat("To import:", paste(traits))

files <- filter(csv_fls, measures %in% traits)

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## get database tables
table_names <- dbListTables(con)
rq_tables <- c("experiments","entitytypes","germinatebase","locations","datasets","compounds","compounddata")
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
## give tables names to make calling specific table easier
names(tables) <- rq_tables

#### proteomic data
## raw file
df <- mutate(files, contents = map(., ~ read_csv(file.path(iwyp_dir, .), col_names = T))) %>% 
  unnest %>% 
  select(-.,-measures) %>% 
  gather(sample_id, compound_value, -func_bin, -metabolite, -peptide, -description, na.rm = T) %>%
  gather(compound_class, name, -description, -sample_id, -compound_value) %>%
  mutate(name = sub(pattern = " Elke", x = name, replacement = '')) %>% # remove " Elke"
  mutate(name = sub(pattern = " new", x = name, replacement = '')) %>% # remove " new"
  mutate(compound_id = tables$compounds$id[match(name, tables$compounds$name)]) %>%
  select(-compound_class, -name) %>%
  mutate(germinatebase_id = tables$germinatebase$id[match(sample_id,tables$germinatebase$general_identifier)]) %>%
  mutate(entitytype_id = tables$germinatebase$entitytype_id[match(sample_id,tables$germinatebase$general_identifier)])

## gather information required from database tables for import into "df_"
df_exps <- left_join(df, tables$experiments, by='description') %>%
  select(id, experiment_name, description) %>% unique %>%
  mutate(experiment_id = id) %>% select(-id)

df_germbase <- left_join(df, tables$germinatebase, by=c('sample_id' = 'general_identifier')) %>%
  select(sample_id, id, number, name) %>% unique %>%
  mutate(germinatebase_id = id) %>% select(-id)

###
tables$compounddata

df_cmpdata <- full_join(df, df_exps, by='description') %>%
  full_join(df_germbase, by='sample_id') %>%
  full_join(df_locations, by='site_name') %>%
  full_join(df_cmp, by='func_bin') %>%
  full_join(df_datasets, by='experiment_id') %>%
  select(compound_id, germinatebase_id, dataset_id, compound_value)

####
####
## APPEND DATA TO TABLE
dbWriteTable(conn = con, name = 'compounddata', value = df_cmpdata, row.names = NA, append = TRUE)

## check updated table
test <- dbReadTable(name = "compounddata", conn=con)

## disconnect from database
dbDisconnect(con)

