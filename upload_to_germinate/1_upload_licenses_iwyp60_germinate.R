## R code to connect and interface with IWYP60 Germinate database
## This script populates licenses table

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## get specific database tables, read into R, and give names
table_names <- dbListTables(con)
rq_tables <- c("datasets","licenses","licenselogs")
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
names(tables) <- rq_tables

a <- as.data.frame(rbind(
  c("IWYP pending", "license pending grants by IWYP"),
  c("CC-BY-NC-ND","Anyone can share this material, provided it remains unaltered in any way, this is not done for commercial purposes, and the original authors are credited and cited."),
  c("CC-BY-ND","Anyone can share this material, providing it remains unaltered in any way and the original authors are credited and cited."),
  c("CC-BY-NC","Anyone can share, reuse, remix, or adapt this material, providing this is not done for commercial purposes and the original authors are credited and cited."),
  c("CC-BY","Anyone can share, reuse, remix, or adapt this material for any purpose, providing the original authors are credited and cited.")
  )
)

colnames(a) <-  c('name', 'description')

## APPEND DATA TO TABLE
dbWriteTable(conn = con, name = 'licenses', value = a, row.names = NA, append = TRUE)

## check updated table
print(dbReadTable(name = "licenses", conn=con))

## disconnect from database and clean up workspace
dbDisconnect(con)
rm(list=ls())