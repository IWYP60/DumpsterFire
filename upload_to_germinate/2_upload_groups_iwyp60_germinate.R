## R code to connect and interface with IWYP60 Germinate database
## This script populates groups table

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

### collate all panels to add as "groups"
grp_panel <- select(site_accessions, ID, Panel) %>%
  mutate(name = Panel) %>%
  mutate(description = "Wheat accession panel") %>%
  mutate(visibility = 1) %>%
  mutate(grouptype_id = 3) %>%
  select(name, description, visibility, grouptype_id) %>%
  unique

grp_panel <- subset(grp_panel, !(name %in% tables$groups$name))

## APPEND DATA TO TABLE
dbWriteTable(conn = con, name = 'groups', value = grp_panel, row.names = NA, append = TRUE)

## check updated table
a <- dbReadTable(name = "groups", conn=con)
head(a)
tail(a)

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
a <- dbReadTable(name = "groupmembers", conn=con)
head(a)
tail(a)

#   mutate(site_accessions, description = sapply(strsplit(file, "_"), function(l) paste0(l[2],l[1],"_",l[3]))) %>%
#     mutate(description = sub(pattern = 'Obregon2016_trial', replacement = "CIMMYT2016", x = description)) %>%
#     mutate(description = sub(pattern = 'GES20', replacement = "GES", x = description)) %>%
