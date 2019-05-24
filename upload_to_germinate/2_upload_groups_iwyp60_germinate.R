## R code to connect and interface with IWYP60 Germinate database
## This script populates 'groups' and 'groupmembers' tables

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

#### collate panels across experiments
iwyp_dir <- "iwyp60_data/"
traits <- c("Harvest", "Lidar", "Biomass", "ASD", "Q2", "Physiology-Raw", "Physiology-BLUE")

## subset to files that contains Panel info
csv_fls <- dir(iwyp_dir, "csv") %>% tibble %>% 
  mutate(datatype = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(datatype = sapply(strsplit(datatype, ".csv"), function(l) l[1])) %>%
  filter(datatype %in% traits)

site_accessions <- NULL

## ugh for loop because no-one followed data standards ...
for(i in csv_fls$.){
  a <- read_csv(file.path(iwyp_dir, i)) %>%
    select(ID, Panel) %>%
    mutate(file = i)
  
  site_accessions <- rbind(a, site_accessions)
}

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## get specific database tables, read into R, and give names
table_names <- dbListTables(con)
rq_tables <- c("groups","locations","germinatebase","markers","grouptypes","groupmembers", "locationtypes")
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
names(tables) <- rq_tables

## update grouptypes to include trialsite
w <- tibble(description = "trialsite", target_table = "locations")
w <- subset(w, !(description %in% tables$grouptypes$description))

## APPEND DATA TO TABLE
dbWriteTable(conn = con, name = 'grouptypes', value = w, row.names = NA, append = TRUE)

## check updated table
w <- dbReadTable(name = "grouptypes", conn=con)
print(w)

### collate all panels to add as "groups"
grp_panel <- select(site_accessions, ID, Panel) %>%
  mutate(name = Panel) %>%
  mutate(description = "Accession panel") %>%
  mutate(visibility = 1) %>%
  mutate(grouptype_id = 3) %>% ## grouptype 3 = accessions
  select(name, description, visibility, grouptype_id) %>%
  unique

# filter pre-existing entries
grp_panel <- subset(grp_panel, !(name %in% tables$groups$name))

## APPEND DATA TO TABLE
dbWriteTable(conn = con, name = 'groups', value = grp_panel, row.names = NA, append = TRUE)

## check updated table
a <- dbReadTable(name = "groups", conn=con)
print(a)

## collate locations to add as "groups"
grp_locs <- select(site_accessions, file) %>%
  mutate(year = sapply(strsplit(file, "_"), function(l) l[1])) %>%
  mutate(name = sapply(strsplit(file, "_"), function(l) l[2])) %>%
  mutate(name = ifelse(year == 2017, 
                                  yes = sub(pattern = "GES", replacement = "GES CR04", x=name),
                                  no = sub(pattern = "GES", replacement = "GES VR11", x=name))) %>% 
  mutate(location_id = tables$locations$id[match(name, tables$locations$name)]) %>%
  mutate(description = "Trial location") %>%
  mutate(visibility = 1) %>%
  mutate(grouptype_id = 4) %>% ## grouptype 1 = trialsite
  select(name, description, visibility, grouptype_id) %>%
  unique

# filter pre-existing entries
grp_locs <- subset(grp_locs, !(name %in% tables$groups$name))

## APPEND DATA TO TABLE
dbWriteTable(conn = con, name = 'groups', value = grp_locs, row.names = NA, append = TRUE)

## check updated table
a <- dbReadTable(name = "groups", conn=con)
print(a)

## collate panel members
grp_panel_members <- mutate(site_accessions, germinatebase_id = tables$germinatebase$id[match(ID,tables$germinatebase$general_identifier)]) %>%
  mutate(germinatebase_id = ifelse(is.na(germinatebase_id) == TRUE, yes =
                                    tables$germinatebase$id[match(ID, tables$germinatebase$name)], no = germinatebase_id)) %>%
  mutate(panel_member = tables$germinatebase$name[match(germinatebase_id, tables$germinatebase$id)]) %>%
  mutate(group_id = a$id[match(Panel, a$name)]) %>%
  mutate(foreign_id = germinatebase_id) %>%
  select(foreign_id, group_id) %>%
  unique

grp_panel_members <- subset(grp_panel_members, !(foreign_id %in% tables$groupmembers$foreign_id))

## APPEND DATA TO TABLE
dbWriteTable(conn = con, name = 'groupmembers', value = grp_panel_members, row.names = NA, append = TRUE)

## check updated table
b <- dbReadTable(name = "groupmembers", conn=con)
print(b)

### locations group members
grp_locs_members <- select(site_accessions, file) %>%
  mutate(year = sapply(strsplit(file, "_"), function(l) l[1])) %>%
  mutate(name = sapply(strsplit(file, "_"), function(l) l[2])) %>%
  mutate(name = ifelse(year == 2017, 
                       yes = sub(pattern = "GES", replacement = "GES CR04", x=name),
                       no = sub(pattern = "GES", replacement = "GES VR11", x=name))) %>% 
  mutate(location_id = tables$locations$id[match(name, tables$locations$site_name_short)]) %>%
  mutate(group_id = a$id[match(name, a$name)]) %>%
  mutate(foreign_id = location_id) %>% ## can foreign ID be a mix of germinatebase and location IDs?
  select(foreign_id, group_id) %>%
  unique

grp_locs_members <- subset(grp_locs_members, !(foreign_id %in% tables$groupmembers$foreign_id))

## APPEND DATA TO TABLE
dbWriteTable(conn = con, name = 'groupmembers', value = grp_locs_members, row.names = NA, append = TRUE)

## check updated table
b <- dbReadTable(name = "groupmembers", conn=con)
print(b)

## disconnect from database and clean up workspace
dbDisconnect(con)
rm(list=ls())
