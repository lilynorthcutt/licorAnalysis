packages <- c("tidyr", "readxl", "dplyr", "magrittr", "purrr", "ggplot2", "Hmisc",
              "snakecase", "lubridate") 
invisible(lapply(packages, require, character.only = TRUE ))
source('funcs.R')

# Questions for Ibrar: does FG not have rows?
# we don't know which rows are for which shu?
# 

# Notes for Ibrar : changed GIP-DATA_lynd.xlsx s.t. sheet names were consistent with other file, and removed 
# extra row in one sheet

###################################################################
###                    LICOR DATA                               ###
###################################################################

### Read in data
fg_filepath <- 'Data/GIP_F_Ibrar_2023_07_19T11_41_54_703Z_1.xlsx'
ley09_filepath <- 'Data/GIP_LYND2_IBRAR_2023_09_08T12_23_07_444Z_1.xlsx'
ley06_filepath <- 'Data/GIP-DATA_lynd.xlsx'

fabian_raw <- readLicorData(fg_filepath)  %>% mutate(row_corrected = "R1",
                                                                     row = "R1") %>% rename(genotype = genotypes)
ley09_raw <- readLicorData(ley09_filepath) 
ley06_raw <- readLicorData(ley06_filepath) %>% mutate(time = parse_date_time(time, '%H:%M:%S'),
                                                      date = as.Date(date  , format = "%Y-%m-%d"),
                                                      match_time = parse_date_time(match_time, '%H:%M:%S'),
                                                      match_date = as.Date(match_date  , format = "%Y-%m-%d"))
#which(is.na(ley06_raw$time))


# Combine into one file
licor_df <- bind_rows(fabian_raw, ley09_raw) %>% 
  bind_rows(ley06_raw ) 

###################################################################
###                        SHU DATA                             ###
###################################################################

### Read in data

hplcpath <- 'Data/hplcData.xlsx'
hplc_raw <- read_xlsx(path = hplcpath, sheet = 'shu')


### Clean/Wrangle Data
# Handle non numeric HPLC values
hplc_df <- hplc_raw %>% rename(hplcRaw = hplc) %>% mutate(
  hplc = as.numeric(hplcRaw)
)
#print((hplcDf %>% filter(is.na(hplc)))$hplcRaw)
#[1] "<50"  "<100" "<100" "<100" "<50"  "<30" 

## Add/Clean columns
hplc_df %<>% mutate(
  # Set all variable types
  hplc = case_when(hplcRaw == "<30" ~ 29,
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
    hplc <= 2000 ~ "Mild",
    (hplc <= 5000 & hplc > 2000) ~"Hot",
    (hplc <= 250000 & hplc > 5000) ~"Very Hot",
    (hplc <= 1000000 & hplc > 250000) ~"Extremely Hot",
    T ~"Superhot"
  ),
  shuLabel = factor(shuLabel, levels = c("Mild", "Hot", "Very Hot", "Extremely Hot", "Superhot"))
)

################################################################################
rm(hplc_raw)
