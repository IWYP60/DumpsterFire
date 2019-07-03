## R code to connect and interface with IWYP60 Germinate database
## Upload markertype and marker tables

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

## generate DBI COnnection Object / establish connection with database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## read tables required to pull database info
table_names <- dbListTables(con)
rq_tables <- c("markers","markertypes","mapdefinitions","mapfeaturetypes",'maps')
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
names(tables) <- rq_tables

#####################
#####################
## build maps table

a <- tibble(
  description = c("DArT-seq SNPs")
)

a <- subset(a, !(description %in% tables$maps$description))

## APPEND maps TABLE
dbWriteTable(conn = con, name = 'maps', value = a, row.names = NA, append = TRUE)

## check updated table
print(dbReadTable(name = "maps", conn=con))

#################
###############
## build markertypes table
a <- tibble(
  description = c("SNP","AFLP","KASP","MicroSat")
) 

a <- subset(a, !(description %in% tables$markertypes$description))

## APPEND markertypes TABLE
dbWriteTable(conn = con, name = 'markertypes', value = a, row.names = NA, append = TRUE)

## check updated table
print(dbReadTable(name = "markertypes", conn=con))

#################
###############
## build mapfeaturetypes table
a <- tibble(
  description = c("SNP","AFLP","KASP","MicroSat")
) 

a <- subset(a, !(description %in% tables$mapfeaturetypes$description))

## APPEND mapfeaturetypes TABLE
dbWriteTable(conn = con, name = 'mapfeaturetypes', value = a, row.names = NA, append = TRUE)

## check updated table
print(dbReadTable(name = "mapfeaturetypes", conn=con))

###################################
########################
#######################
## COLLATE MARKERS
iwyp_dir <- "iwyp60_data/"
traits <- "GBS"

dat <- dir(iwyp_dir, "csv") %>% 
  tibble %>% 
  mutate(datatype = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(datatype = sapply(strsplit(datatype, ".csv"), function(l) l[1])) %>%
  filter(datatype %in% traits) %>%
  mutate(contents = map(., ~read_csv(file.path(iwyp_dir, "2016_Obregon_CAIGE_GBS.csv"), skip=5, col_names = T))) %>%
  unnest %>%
  select("AlleleID", "Chrom_Wheat_ChineseSpring04", "ChromPos_Wheat_ChineseSpring04", "SNP", "SnpPosition") %>%
  mutate(Chrom_Wheat_ChineseSpring04 = ifelse(test = is.na(Chrom_Wheat_ChineseSpring04) == T, 
                                              yes = "Unmapped", 
                                              no = Chrom_Wheat_ChineseSpring04))

## markers
a <- tibble('marker_name' = dat$AlleleID, 
            markertype_id = 1) ## assumes all markers are SNPs

a <- subset(a, !(marker_name %in% tables$markers$marker_name))

## APPEND markers TABLE
dbWriteTable(conn = con, name = 'markers', value = a, row.names = NA, append = TRUE)

## check updated table
marks <- dbReadTable(name = "markers", conn=con)
print(marks)

###############
### mapdefinitions
a <- mutate(dat, mapfeaturetype_id = 1) %>% # assumes all feature tpyes are SNPs
  mutate(marker_id = marks$id[match(AlleleID, marks$marker_name)]) %>%
  mutate(map_id = 1) %>% ## assumes all SNPs derived from DArT-seq
  mutate(definition_start = ChromPos_Wheat_ChineseSpring04) %>%
  mutate(definition_end = (ChromPos_Wheat_ChineseSpring04 + SnpPosition)) %>%
  mutate(chromosome = Chrom_Wheat_ChineseSpring04) %>%
  select(mapfeaturetype_id, marker_id, map_id, definition_start, definition_end, chromosome)

a <- subset(a, !(marker_id %in% tables$mapdefinitions$marker_id))

## APPEND markers TABLE
dbWriteTable(conn = con, name = 'mapdefinitions', value = a, row.names = NA, append = TRUE)

## check updated table
print(dbReadTable(name = "mapdefinitions", conn=con))

## disconnect from database and clean up workspace
dbDisconnect(con)
rm(list=ls())
