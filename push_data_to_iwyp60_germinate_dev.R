## R code to connect and interface with IWYP60 Germinate database
## Theoretically, the final version will be used to upload collated & processed data to IWYP60 germinate

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)

## generate DBI COnnection Object / establish connection with database
con <- dbConnect(MySQL(),
          dbname="iwyp60_germinate_dev",
          host = 'wheatyield.anu.edu.au',
          password = askForPassword())

## list tables in database
table_names <- dbListTables(con)

## read data from table
tables <- lapply(FUN=dbReadTable, X=table_names, conn=con)

## disconnect from database
dbDisconnect(con)

