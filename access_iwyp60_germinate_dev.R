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
          host = 'wheatyield.anu.edu.au',
          password = askForPassword())

## list tables in database
table_names <- dbListTables(con)
table_names

## read data from table
tables <- lapply(FUN=dbReadTable, X=table_names, conn=con)

## give tables names to make calling specific table easier
names(tables) <- table_names

i <- "compounds"
head(tables[[i]])

i <- "compounddata"
head(tables[[i]])

## disconnect from database
dbDisconnect(con)

