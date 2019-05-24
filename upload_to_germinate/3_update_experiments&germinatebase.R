## R code to connect and interface with IWYP60 Germinate database
## This script updates the germinatebase & experiments tables

library(DBI) ## functions to interface with databases
library(RMySQL) ## database implementation
library(rstudioapi)
library(tidyverse)

#### collate sample ID across datasets
iwyp_dir <- "iwyp60_data/"
trials <- c("Harvest", "Lidar", "Biomass", "ASD", "Q2", "Physiology-Raw", "Physiology-BLUE")
comps <- c('Metabolomics-metabolite', 'Proteomics-functionalbin', 'Proteomics-peptide')

## connect to database
con <- dbConnect(MySQL(),
                 dbname="iwyp60_germinate_dev",
                 host = 'wheatyield.anu.edu.au',
                 password = askForPassword())

## get specific database tables, read into R, and give names
table_names <- dbListTables(con)
rq_tables <- c("experiments", "experimenttypes","entitytypes","locations","germinatebase","locationtypes","institutions","biologicalstatus")
tables <- lapply(FUN=dbReadTable, X=rq_tables, conn=con)
names(tables) <- rq_tables

###########
## update experiment tables with compound experiment type
comp_fls <- dir(iwyp_dir, "csv") %>% tibble %>% 
  mutate(datatype = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(datatype = sapply(strsplit(datatype, ".csv"), function(l) l[1])) %>%
  filter(datatype %in% comps)

## collate ids for experimenttype compoud 
## This may useful later to link sample ID within compound datasets to germinatebase

comp_ids <- NULL

for(i in comp_fls$.){
  a <- read_csv(file.path(iwyp_dir, i)) %>%
    select(-compound) %>%
    na.omit() %>%
    gather(sample_id, value, -experiment_name) %>%
    mutate(type = sapply(strsplit(i, "_"), function(l) l[4]))%>%
    mutate(type = sapply(strsplit(type, ".csv"), function(l) l[1]))
  
  comp_ids <- rbind(a, comp_ids)
}

r <- select(comp_ids, experiment_name, type) %>% unique %>%
  mutate(description = sub(pattern = 'Obregon2016_trial', replacement = "CIMMYT2016", x = experiment_name)) %>%
  mutate(description = sub(pattern = 'GES20', replacement = "GES", x = description)) %>%
  mutate(description = paste(description,type,sep=' ')) %>%
  mutate(experiment_id = as.integer(row_number()+22)) %>%
  mutate(experiment_name = ifelse(experiment_id > 10, 
                                  yes=paste0("IW_E00",experiment_id),
                                  no=paste0("IW_E000",experiment_id))) %>%
  mutate(experiment_type_id = as.integer(6)) %>% # compound = 'experimenttypes$id' == 6
  mutate(experiment_date = ' ') %>%
  select(experiment_name, description, experiment_type_id)

r2 <- subset(r, !(description %in% tables$experiments$description))

## append experiments table
dbWriteTable(conn = con, name = 'experiments', value = r2, row.names = NA, append = TRUE)

## check updated table
r3 <- dbReadTable(name = "experiments", conn=con)
print(r3)

#################
###
### update germinatebase table
csv_fls <- dir(iwyp_dir, "csv") %>% tibble %>% 
  mutate(datatype = sapply(strsplit(., "_"), function(l) l[4])) %>%
  mutate(datatype = sapply(strsplit(datatype, ".csv"), function(l) l[1])) %>%
  filter(datatype %in% trials)

## colate sample ids for trial data
trial_ids <- NULL
for(i in csv_fls$.){
  a <- read_csv(file.path(iwyp_dir, i)) %>%
    select(ID) %>%
    mutate(file = i)
  
  trial_ids <- rbind(a, trial_ids)
}

## link sample IDs to location_ids
trial_ids <- unique(trial_ids) %>%
  mutate(year = sapply(strsplit(file, "_"), function(l) l[1])) %>%
  mutate(site_name_short = sapply(strsplit(file, "_"), function(l) l[2])) %>%
  mutate(site_name_short = ifelse(year == 2017, 
                                  yes = sub(pattern = "GES", replacement = "GES CR04", x=site_name_short),
                                  no = sub(pattern = "GES", replacement = "GES VR11", x=site_name_short))) %>%
  mutate(location_id = tables$locations$id[match(site_name_short, tables$locations$site_name_short)]) %>%
  mutate(institution_id = ifelse(site_name_short == "Obregon", yes = 4, no = 1))

## now link location ids into germinatebase
a <- tables$germinatebase %>%
  mutate(location_id = trial_ids$location_id[match(general_identifier, trial_ids$ID)]) %>%
  mutate(location_id = ifelse(is.na(location_id) == T, 
                              yes = trial_ids$location_id[match(number, trial_ids$ID)],
                                no = location_id)) %>%
  mutate(location_id = ifelse(is.na(location_id) == T, 
                              yes = trial_ids$location_id[match(name, trial_ids$ID)],
                              no = location_id)) %>%
  mutate(institution_id = trial_ids$institution_id[match(general_identifier, trial_ids$ID)]) %>%
  mutate(institution_id = ifelse(is.na(institution_id) == T, 
                              yes = trial_ids$institution_id[match(number, trial_ids$ID)],
                              no = institution_id)) %>%
  mutate(institution_id = ifelse(is.na(institution_id) == T, 
                              yes = trial_ids$institution_id[match(name, trial_ids$ID)],
                              no = institution_id))

## turn foreign ID checsk off
# dbExecute(conn = con, statement = 'SELECT @FOREIGN_KEY_CHECKS;')
# dbExecute(conn = con, statement = 'SET FOREIGN_KEY_CHECKS = 0;')

## OVERWRITE germinatebase table with new info
# dbWriteTable(conn = con, name = 'germinatebase', value = a, overwrite = TRUE)

## turn foreign ID checks on
# dbExecute(conn = con, statement = 'SET FOREIGN_KEY_CHECKS = 1;')

## check updated table
w <- dbReadTable(name = "germinatebase", conn=con)
print(w)

## disconnect from database and clean up workspace
dbDisconnect(con)
rm(list=ls())
