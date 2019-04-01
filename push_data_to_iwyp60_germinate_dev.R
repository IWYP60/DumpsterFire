## connecting to databases
## check out https://db.rstudio.com/dplyr/

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

