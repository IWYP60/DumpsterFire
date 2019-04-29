## R code to connect and interface with IWYP60 Germinate database
## This script collates proteomic (function bins and peptides) and metabolomic IDs and updates compound table

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

##
#### collate data
iwyp_dir <- "iwyp60_data/"
csv_fls <- dir(iwyp_dir, "csv") %>% tibble %>% 
  mutate(description = sapply(strsplit(., "_"), function(l) l[3])) %>%
  mutate(description = sapply(strsplit(description, ".csv"), function(l) l[1]))

## Update compouds table with proteomic and metabolimic markers
traits <- csv_fls$description[4:6]
cat("To import:", paste(traits))

## setup compounds table for upload
dat <- subset(csv_fls, description %in% traits) %>%
  mutate(contents = map(., ~ read_csv(file.path(iwyp_dir, .), col_names = T))) %>% 
  unnest %>% 
  select(description, metabolite, func_bin, peptide) %>%
  gather(compound_class, name, -description, na.rm = T) %>%
  mutate(compound_class = sapply(strsplit(description,"-"), function(l) l[2])) %>%
  mutate(description = sapply(strsplit(description,"-"), function(l) l[1]))

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

cmp <- tables[["compounds"]]

#### Remove compounds already in cmp table
new_dat <- subset(dat, !(name %in% cmp$name))

### potentially need to remove " Elke" or " Elke new"  from compound names
# test2 <- sub(pattern = " Elke", x = test$name, replacement = '')
# subset(test, name == "(-)- Shikimic acid (4TMS) Elke new")
# test2[99]

####
####
## APPEND DATA TO TABLE
## this can be changed to overwrite to replace entire compounds table - however this did not work well when trialled so BE CAREFUL
dbWriteTable(conn = con, name = 'compounds', value = new_dat, row.names = NA, append = TRUE)

## check updated table
test <- dbReadTable(name = "compounds", conn=con)

## disconnect from database
dbDisconnect(con)

  