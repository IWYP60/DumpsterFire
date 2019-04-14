## R code to connect and interface with IWYP60 Germinate database
## Theoretically, the final version will be used to upload collated & processed data to IWYP60 germinate

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)
library(xlsx)

##
#### collate data
iwyp_dir <- "iwyp60_data/"
csv_fls <- dir(iwyp_dir, "csv")
xlsx_fls <- dir(iwyp_dir, "xlsx")

yr <- unique(sapply(strsplit(csv_fls, "_"), function(l) l[1]))
sites <- unique(sapply(strsplit(csv_fls, "_"), function(l) l[2]))
measures <- unique(sapply(strsplit(csv_fls, "_"), function(l) l[3]))
print(c(yr,sites,measures))

files <- dir(iwyp_dir, pattern = measures[1])

df <- data_frame(files) %>% mutate(contents = map(., ~ read_csv(file.path(iwyp_dir, .)))) %>% unnest %>% 
  mutate(Site = sapply(strsplit(files, "_"), function(l) l[2])) %>% select(-files)
df <- as.data.frame(df)
head(df)

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

####
### create "test" table, append climate data to it, read table, then drop table.

## list database tables
dbListTables(con)

## create test table
dbCreateTable(conn = con, name = "test", fields = df)

## append data to table
dbWriteTable(conn = con, name = 'test', value = df, row.names = NA, append = TRUE)

## read/view  test table
dbReadTable(con, 'test')

## remove test table
dbRemoveTable(conn = con, name = "test")

## disconnect from database
dbDisconnect(con)

