packages <- c("tidyr", "readxl", "dplyr", "magrittr", "purrr", "ggplot2", "Hmisc",
              "snakecase", "lubridate", "plyr") 
invisible(lapply(packages, require, character.only = TRUE ))
source('src/funcs.R')

###############################################################################
## NOTES:
# We have 4 data sources for this project. They are the following:
# 1. LICOR Data collected from LI600. Data was collected on 3 different 
#.   days, each one with their own file. Contains porometry and fluorometry data
# 2. SHU Data collected from HPLC. Contains scoville heat unit data
# 3. Plant data collected from human entry. Contains data taken at harvest such 
#.   as pepper weight, yield, number of mature/unripe fruit, etc.
# 4. Environmental data

# Questions for Ibrar: does FG not have rows?
# we don't know which rows are for which shu?
# 

# Notes for Ibrar : changed GIP-DATA_lynd.xlsx s.t. sheet names were consistent 
# with other file, and removed extra row in one sheet.
# Edited two errors within the "date harvested" column: 
#   1. @Ley 23C096 rep 1: 09.22.23 => 09.22.2023
#   2. @FG 23C090 rep 3: 10.13.2033 => 10.13.2023
# Changed no_basal_branches NA -> 0 for 23C104 rep 2 @Ley
# NEED TO DO: get 23C109 gbs and name

################################################################################
#


#
################################################################################
###                         Read in data sources                            ####
################################################################################

# 1. LICOR #####################################################################
 
### Read in data
fg_filepath <- 'Data/raw/Licor/licor_fg_09052023.xlsx'
ley09_filepath <- 'Data/raw/Licor/licor_ley_09072023.xlsx'
ley06_filepath <- 'Data/raw/Licor/licor_ley_06202023.xlsx'

fabian_raw <- readLicorData(fg_filepath, "Fabian")  %>% 
  mutate(rep_corrected = rep) %>% 
  dplyr::rename(genotype = genotypes)
ley09_raw <- readLicorData(ley09_filepath, "Leyendecker") 
ley06_raw <- readLicorData(ley06_filepath, "Leyendecker") %>% 
  mutate(time = parse_date_time(time, '%H:%M:%S'),
         date = as.Date(date  , format = "%Y-%m-%d"),
         match_time = parse_date_time(match_time, '%H:%M:%S'),
         match_date = as.Date(match_date  , format = "%Y-%m-%d"))
#which(is.na(ley06_raw$time))


# Combine into one file
licor_df <- bind_rows(fabian_raw, ley09_raw) %>% 
  bind_rows(ley06_raw ) 

### Clean/Wrangle Data

# Make cols consistent with other data sources
licor_df %<>% dplyr::rename(label23C = genotype) %>% mutate(
  label23C = convertNumTo3DigitChar(label23C),
  rep = case_when(
    rep_corrected=="R1" ~1,
    rep_corrected=="R2" ~2,
    T ~3
  )
  )

# Make avg time by label23C, rep, location, and date column

# Remove columns we don't want
rm_cols <- c("rep_corrected", "obs", "config_name", 
                     "config_author", "remark", "plant_number","na", "row")
licor_df %<>% select(-all_of(rm_cols)) %>% select("label23C", "location","rep", everything())


# Create summary dataframe - average by label23C, location, and rep for all features
licor_df_summary <- licor_df %>% dplyr::group_by(label23C, rep, location, date) %>% 
  dplyr::summarise_if(is.numeric , mean)

# 2. SHU #######################################################################

### Read in data
hplcpath <- 'Data/raw/SHU/hplcData.xlsx'
hplc_raw <- read_xlsx(path = hplcpath, sheet = 'shu')


### Clean/Wrangle Data
# Handle non numeric HPLC values
hplc_df <- hplc_raw %>% dplyr::rename(hplcRaw = hplc) %>% mutate(
  hplc = as.numeric(hplcRaw)
)
#print((hplc_df %>% filter(is.na(hplc)))$hplcRaw)
#[1] "<50"  "<100" "<100" "<100" "<50"  "<30" 

## Add/Clean columns
hplc_df %<>% mutate(
  # Set all variable types
  shu = case_when(hplcRaw == "<30" ~ 29,
                   hplcRaw == "<50" ~ 49,
                   hplcRaw == "<100" ~ 100,
                   T ~ hplc), 
  label23C = as.numeric(label23C),
  gbs = as.character(gbs),
  name = as.character(name),
  location = as.character(location),
  replication = as.numeric(replication),
  shuLabel = case_when(
    shu <= 2000 ~ "Mild",
    (shu <= 5000 & shu > 2000) ~"Hot",
    (shu <= 250000 & shu > 5000) ~"Very Hot",
    (shu <= 1000000 & shu > 250000) ~"Extremely Hot",
    T ~"Superhot"
  ),
  shuLabel = factor(shuLabel, levels = c("Mild", "Hot", "Very Hot", "Extremely Hot", "Superhot")),
  label23C = convertNumTo3DigitChar(label23C),
  location = case_when(
    location == "Leyendecker" ~"Leyendecker",
    T ~"Fabian")
)

# Make all columns uniform between data sources
hplc_df %<>% dplyr::rename(rep = replication) %>% 
  mutate(label23C = convertNumTo3DigitChar(label23C))

# Clean up cases where we have 2 samples for one group (rep, location, label23C)
# note - each gbs and name are specific for label23C
hplc_df_summary <- hplc_df %>% dplyr::group_by(label23C, gbs, name, location, rep) %>% 
  dplyr::summarise(shu = mean(shu, na.rm = T)) %>% mutate(
    shuLabel = case_when(
      shu <= 2000 ~ "Mild",
      (shu <= 5000 & shu > 2000) ~"Hot",
      (shu <= 250000 & shu > 5000) ~"Very Hot",
      (shu <= 1000000 & shu > 250000) ~"Extremely Hot",
      T ~"Superhot"
    ),
    shuLabel = factor(shuLabel, levels = c("Mild", "Hot", "Very Hot", "Extremely Hot", "Superhot"))
  )



# 3. HARVEST ###################################################################

### Read in data
harvest_filepath <- 'Data/raw/Harvest/ALL_2023_ FIELDBOOKS.xlsx'
harvest_fg_sheet <- 'GIP_FGarcia'
harvest_ley_sheet <- 'GIP_LPSRC'

harvest_raw_fg <- read_excel(path = harvest_filepath, sheet = harvest_fg_sheet, skip = 1)
harvest_raw_ley <- read_excel(path = harvest_filepath, sheet = harvest_ley_sheet, skip = 1) 


### Clean Data
# Snakecase all columns
colnames(harvest_raw_fg) <- to_any_case(colnames(harvest_raw_fg)) 
colnames(harvest_raw_ley) <- to_any_case(colnames(harvest_raw_ley)) 


# Remove columns that are all NA
harvest_raw_fg %<>% select(-findNACols(harvest_raw_fg)) %>% dplyr::rename(label23C  = "23_c")
harvest_raw_ley %<>% select(-findNACols(harvest_raw_ley)) %>% dplyr::rename(label23C  = "23_c")

# Rename columns that represent the same thing s.t. they are the same in both dfs
harvest_raw_ley %<>% dplyr::rename(yield = yield_kg, 
                            red_yield = red_yield_kg,
                            green_yield = green_yield_kg,
                            "10_fruit_weight_kg" = "10_pod_weight_kg") 

# Remove columns we are not interested in 
rm_cols_univ <- c("no", "plot_score_july_5", "plot_score_june_9", "plot_score_june_26", 
                  "plot_score_july_11", "remove_col")
harvest_raw_fg %<>% select(-any_of(rm_cols_univ)) 
harvest_raw_ley %<>% select(-any_of(rm_cols_univ)) 

# Correct GBS to be consistent labeling with other dataframes
harvest_raw_fg$gbs <- gsub("\\D+", "", harvest_raw_fg$gbs)
harvest_raw_fg$gbs[harvest_raw_fg$gbs == ""] <- harvest_raw_fg$name[harvest_raw_fg$gbs == ""]
harvest_raw_ley$gbs <- gsub("\\D+", "", harvest_raw_ley$gbs)
harvest_raw_ley$gbs[harvest_raw_ley$gbs == ""] <- harvest_raw_ley$name[harvest_raw_ley$gbs == ""]

# Create cols to condense different ones in FG an Ley
# FG has cols "transplants with flowers" and "transplants with fruit" this 
#   represents # of transplanted plants with each
# Ley has cols "number of flowers" and "number of fruits" this represents # of 
#   each in TOTAL in all the transplanted plants 
# Because we cannot infer one for the other, to merge dataframes and columns we
# will create new columns (boolean) to represent whether fruits/flowers exist at all on the plants
harvest_raw_ley %<>%  mutate(
  fruits_on_transplant = case_when(
    transplants_with_fruits >0 ~1,
    T ~0
  ),
  flowers_on_transplant = case_when(
    transplants_with_flowers > 0 ~1,
    T ~0
  )) #%>% select(-transplants_with_fruits, -transplants_with_flowers )

harvest_raw_fg %<>%  mutate(
  fruits_on_transplant = case_when(
    no_of_fruits >0 ~1,
    T ~0
  ),
  flowers_on_transplant = case_when(
    no_of_floweers > 0 ~1,
    T ~0
  )) #%>% select(-transplants_with_fruits, -transplants_with_flowers )

# Housekeeping before merging (changing label 23C to char, adding transplant date+location)
harvest_raw_ley %<>% rowwise() %>% 
  mutate(transplanted_date = as.Date("04/26/2023", format = "%m/%d/%Y"),
         date_harvested = as.Date(date_harvested, format = "%m.%d.%Y"),
         days_from_t_to_h = date_harvested - transplanted_date,
         label23C = convertNumTo3DigitChar(label23C),
         location = "Leyendecker"
  )

harvest_raw_fg %<>% rowwise() %>% 
  mutate(transplanted_date = as.Date("04/27/2023", format = "%m/%d/%Y"),
         date_harvested = as.Date(date_harvested, format = "%m.%d.%Y"),
         days_from_t_to_h = date_harvested - transplanted_date,
         label23C = convertNumTo3DigitChar(label23C),
         location = "Fabian"
  )
checkDates(harvest_raw_fg)
checkDates(harvest_raw_ley)


# Pivot longer columns 
# Ex: [plantheight_1, plantheight_2, plantheight_3] => [plantNum, height] )
cols_to_pivot <- c("plant_height", "plant_width", "height_to_first_bifurcation",
                   "no_of_basal_branches")
grouping_cols <- c("label23C", "rep")

harvest_fg <- pivotLongerPlantData(harvest_raw_fg, cols_to_pivot , grouping_cols ) 
harvest_ley <- pivotLongerPlantData(harvest_raw_ley, cols_to_pivot , grouping_cols ) 


# Create summary dataframe, with all of the columns, except that height, width, 
# height_to_first_bifurcation and no_of_basal_branches are averages (with stdevs)
harvest_fg_summary <- harvest_fg %>% dplyr::group_by(label23C, rep, .add = FALSE) %>% 
  dplyr::summarise(avg_height = mean(plant_height, na.rm = T),
            avg_width = mean(plant_width, na.rm = T),
            avg_height_to_first_bifurcation = mean(height_to_first_bifurcation, na.rm = T),
            avg_no_of_basal_branches = mean(no_of_basal_branches, na.rm = T)) %>% 
  ungroup() %>% merge(getDfWithoutCols(harvest_raw_fg, cols_to_pivot) , by = c("label23C", "rep"), all = TRUE) 


harvest_ley_summary <- harvest_ley %>% dplyr::group_by(label23C, rep) %>% 
  dplyr::summarise(avg_height = mean(plant_height, na.rm = T),
            avg_width = mean(plant_width, na.rm = T),
            avg_height_to_first_bifurcation = mean(height_to_first_bifurcation, na.rm = T),
            avg_no_of_basal_branches = mean(no_of_basal_branches, na.rm = T)
  ) %>% ungroup() %>% 
  merge(getDfWithoutCols(harvest_raw_ley, cols_to_pivot) , by = c("label23C", "rep"), all = TRUE) 

# Combine by location
harvest_all <- plyr::rbind.fill(harvest_fg, harvest_ley)
harvest_summary <- plyr::rbind.fill(harvest_fg_summary, harvest_ley_summary)


# 4. ENIRONMENTAL/WEATHER ######################################################





#

################################################################################
###                         Combine data sources                            ####
################################################################################
grouping_cols <- c("rep", "label23C", "location")

# 1. Check all df meet criteria for merge ######################################
# licor_df
#licor_df_ley <- licor_df_summary %>% filter(location == "Leyendecker")

# hplc_df
#hplc_df_summary_ley <- hplc_df_summary %>% filter(location == "Leyendecker")


# harvest_summary
# check
#harvest_summary_ley <- harvest_summary %>% filter(location == "Leyendecker")

hplc_df_summary %>% mutate(inHplc = 1) %>% 
  merge(harvest_summary %>% mutate(inHarvest = 1) , by = grouping_cols) %>% 
  merge(licor_df_summary %>% mutate(inLicor = 1) , by = grouping_cols, all = TRUE) %>% 
  select(label23C, rep, location, inHplc, inHarvest, inLicor) %>% View()


# 2. Merge all df ##############################################################
df_summary <- hplc_df_summary %>% merge(harvest_summary, by = grouping_cols) %>% 
  merge(licor_df_summary, by = grouping_cols, all = TRUE) 



################################################################################
rm(hplc_raw, fabian_raw, ley06_raw, ley09_raw, fg_filepath, hplcpath, ley06_filepath, ley09_filepath,
   harvest_fg, harvest_fg_summary, harvest_ley, harvest_ley_summary, harvest_raw_fg, harvest_raw_ley)
