## R code to connect and interface with IWYP60 Germinate database
## This script collates proteomic (function bins and peptides) and metabolomic IDs and updates compound table

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