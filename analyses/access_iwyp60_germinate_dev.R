## R code to connect and interface with IWYP60 Germinate database
## This script sets a template for accessing database information but NOT editing info
## Useful for read-only accounts

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

## generate DBI COnnection Object / establish connection with database
con <- dbConnect(MySQL(),
          dbname="iwyp60_germinate_dev",
          user = "iwyp60ro",
          host = 'wheatyield.anu.edu.au')

## read tables required to pull database info
table_names <- dbListTables(con)
rq_tables <- c("markers","markertypes","compounddata", "compounds","datasetmembers", "datasets", "experiments", "germinatebase","groups","grouptypes","groupmembers")
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
names(tables) <- rq_tables

df <- select(tables$compounddata, compound_id, germinatebase_id, dataset_id, compound_value) %>%
  full_join(., tables$compounds, by=c("compound_id"="id")) %>%
  full_join(., tables$germinatebase, by=c("germinatebase_id"="id")) %>%
  full_join(., tables$datasets, by=c("dataset_id"="id")) %>%
  select(-breeders_code, -breeders_name, -subtaxa_id, -puid, -colldate, -collcode, -collname, -collmissid, -othernumb, -duplsite, -duplinstname)

## disconnect from database
dbDisconnect(con)

