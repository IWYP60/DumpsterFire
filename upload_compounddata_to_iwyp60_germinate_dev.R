## R code to connect and interface with IWYP60 Germinate database
## This script collates proteomic data and uploads to the compounddata table to the germinate3 database

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)
library(xlsx)

##
#### collate data
iwyp_dir <- "iwyp60_data/"
csv_fls <- dir(iwyp_dir, "csv")

yr <- unique(sapply(strsplit(csv_fls, "_"), function(l) l[1]))
sites <- unique(sapply(strsplit(csv_fls, "_"), function(l) l[2]))
measures <- unique(sapply(strsplit(csv_fls, "_"), function(l) l[3]))
print(c(yr,sites,measures))

##
#### Proteomic data
##
files <- dir(iwyp_dir, pattern = measures[4])

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

#### proteomic data
## raw file
df <- data_frame(files) %>% mutate(contents = map(., ~ read_csv(file.path(iwyp_dir, .), col_names = T))) %>% unnest %>% 
  mutate(description = sapply(strsplit(files, "_"), function(l) paste(l[2],l[1],sep=''))) %>% 
  select(-files) %>% 
  gather(sample_id, compound_value, -func_bin, -description, na.rm = T) %>%
  mutate(site_name = "Obregon (CIMMYT)") ## need to change later - ie. add sitename to spreadsheets?

## gather information required from database tables for import into "df_"

##
exps <- tables[["experiments"]]

df_exps <- left_join(df, exps, by='description') %>%
  select(id, experiment_name, description) %>% unique %>%
  mutate(experiment_id = id) %>% select(-id)

##

germbase <- tables[["germinatebase"]]

df_germbase <- left_join(df, germbase, by=c('sample_id' = 'general_identifier')) %>%
  select(sample_id, id, number, name) %>% unique %>%
  mutate(germinatebase_id = id) %>% select(-id)

##

locations <- tables[["locations"]]

df_locations <- left_join(df, locations, by=c('site_name')) %>%
  select(id, locationtype_id, country_id, site_name) %>%
  mutate(location_id = id) %>% select(-id) %>% unique

##

datasets <- tables[["datasets"]]

df_datasets <- tibble(dataset_id=1) %>% 
  mutate(experiment_id = df_exps$experiment_id) %>%
  mutate(location_id = df_locations$location_id) %>%
  mutate(description = "2016 CIMMYT Proteomics Functional Bin") %>%
  mutate(datatype = "Proteomic")

##

cmp <- tables[["compounds"]]

df_cmp <- left_join(df, cmp, by=c('func_bin' = 'name')) %>%
  mutate(compound_id = id) %>%
  select(compound_id, func_bin, compound_class) %>% unique

###
cmpdata <- tables[["compounddata"]]

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

test <- dbReadTable(name = "compounddata", conn=con)

## disconnect from database
dbDisconnect(con)

