packages <- c("tidyr", "readxl", "dplyr", "magrittr", "purrr", "ggplot2", "Hmisc",
              "snakecase", "lubridate") 
invisible(lapply(packages, require, character.only = TRUE ))
source('funcs.R')
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
# with other file, and removed extra row in one sheet
################################################################################

################################################################################
#########                     LICOR DATA                               #########
################################################################################

### Read in data
fg_filepath <- 'Data/licor_fg_09052023.xlsx'
ley09_filepath <- 'Data/licor_ley_09072023.xlsx'
ley06_filepath <- 'Data/licor_ley_06202023.xlsx'

fabian_raw <- readLicorData(fg_filepath, "Fabian")  %>% 
  mutate(row_corrected = "R1",row = "R1") %>% rename(genotype = genotypes)
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
licor_df %<>% mutate(label23C = convert23CToChar(genotype))

################################################################################
#########                         SHU DATA                             #########
################################################################################

### Read in data

hplcpath <- 'Data/hplcData.xlsx'
hplc_raw <- read_xlsx(path = hplcpath, sheet = 'shu')


### Clean/Wrangle Data
# Handle non numeric HPLC values
hplc_df <- hplc_raw %>% rename(hplcRaw = hplc) %>% mutate(
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
  # Each genotype has 1 to 6 samples. 
  # Number them, and flag if there is an outlier
  sampleCount = row_number(),
  #outlier = outlierCheck(hplc)
  shuLabel = case_when(
    shu <= 2000 ~ "Mild",
    (shu <= 5000 & shu > 2000) ~"Hot",
    (shu <= 250000 & shu > 5000) ~"Very Hot",
    (shu <= 1000000 & shu > 250000) ~"Extremely Hot",
    T ~"Superhot"
  ),
  shuLabel = factor(shuLabel, levels = c("Mild", "Hot", "Very Hot", "Extremely Hot", "Superhot")),
  label23C = convert23CToChar(label23C)
)

################################################################################
rm(hplc_raw, fabian_raw, ley06_raw, ley09_raw)
