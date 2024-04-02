packages <- c("tidyr", "readxl", "dplyr", "magrittr", "purrr", "ggplot2", "Hmisc") 
invisible(lapply(packages, require, character.only = TRUE ))



#####################
### READ IN DATA 
#####################
hplcPath <- 'Data/hplcData.xlsx'
hplcRaw <- read_xlsx(path = hplcPath, sheet = 'shu')

shuLabel <- tibble(
  category = c("Mild", "Hot", "Very Hot", "Extremely Hot", "Superhot"),
  min = c(0, 2000, 50000, 250000, 1000000),
  max = c(2000, 50000,250000,1000000, (1000000^2))
)
######################
### CLEAN DATA
######################

### Handle non numeric HPLC values
hplcDf <- hplcRaw %>% rename(hplcRaw = hplc) %>% mutate(
  hplc = as.numeric(hplcRaw)
)
print((hplcDf %>% filter(is.na(hplc)))$hplcRaw)
#[1] "<50"  "<100" "<100" "<100" "<50"  "<30" 

### Add/Clean columns
hplcDf %<>% mutate(
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
