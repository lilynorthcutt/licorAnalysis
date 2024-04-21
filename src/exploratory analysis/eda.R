packages <- c("tidyr", "readxl", "dplyr", "magrittr", "purrr", "ggplot2", "Hmisc", # Data manipulation packages
              "snakecase", "lubridate", "plyr",
              "stats", "corrplot", 'ggpubr' #Exploratory Data Analysis Packages
              ) 
invisible(lapply(packages, require, character.only = TRUE ))
source('src/data/funcs.R')


###############################################################################
## NOTES:
# 
#
## FUTURE WORK:
# this year - combine spicy with parent, to find how that affect spiciness of child
################################################################################
#



################################################################################
###                         Read in data sources                            ####
################################################################################

# If file 'Data/processed' is empty, run:
#source('src/data/preprocess.R')
# Else:
df <- read.csv('Data/processed/data.csv') %>% select(-X, -gbs.y, -name.y) %>% 
  dplyr::rename(gbs = gbs.x, name = name.x) %>% mutate(
    label23C = convertNumTo3DigitChar(label23C)
  )

# Rename row as label23c
df %<>% rowwise() %>% 
  mutate(unique_id = paste0(label23C, "-",location, "-",rep, "-", date)) %>% as.data.frame()

rownames(df) <- df$unique_id

df %<>% select(-unique_id) 

# Because the genotypes at leyendecker have 2 days of licor sampling (once in june, and once in september)
# we don't want to double count them and over-represent these points in the data - so will filter out the 
# collection in june of some of the analysis
df_filtered <- df %>% filter(!(date == "2023-06-20" )) 

################################################################################
###                         .     Features.                                 ####
################################################################################

## Add normalized column for 

################################################################################
###                         .     Exploration                               ####
################################################################################

# Test for normality
shapiro.test(df_filtered$shu)
ggqqplot(df_filtered$shu, ylab = "SHU")
ggdensity(df_filtered$shu)


# Look at distribution of heat
ggdensity(df_filtered$shu)

# Compare differences in 



# Look at scatterplot with gbs on lower, and each licor on top



################################################################################
################################################################################
################################################################################
# Look at correlation between features and SHU
rm_for_cor <- c("avg_height", "avg_width", "avg_height_to_first_bifurcation",
                "avg_no_of_basal_branches", "row", "no_of_transplants", "no_of_floweers", 
                "no_of_fruits", "date_harvested", "plants_harvested", "yield", "red_yield", 
                "green_yield", "X10_fruit_weight_kg", "fruits_on_transplant", 
                "flowers_on_transplant", "transplanted_date", "days_from_t_to_h",                
                "transplants_with_flowers", "transplants_with_fruits")
df_filtered_cor <- df_filtered %>% select(-all_of(rm_for_cor)) %>% 
  mutate(shu = as.numeric(shu)) %>% drop_na() 


df_filtered_cor %<>% select(-label23C, -location, -rep, -gbs,-name,
                            -shuLabel, -date)

# Remove if all values are the same
df_filtered_cor <- df_filtered_cor[vapply(df_filtered_cor, function(x) length(unique(x)) > 1, logical(1L))]

#cor(df_filtered_cor ) %>% View()
correlation <- rcorr(as.matrix(df_filtered_cor )) 

heatmap(as.matrix(df_filtered_cor ))
heatmap(as.matrix(df_filtered_cor ), scale="column")

################################################################################
################################################################################
################################################################################

# Compare differences in values by date
exclude_columns <- c( "label23C", "name", "gbs", "rep", "shuLabel", "date")

prep_scale <- df %>% filter(location == "Leyendecker") %>% 
  select(-location, -all_of(rm_for_cor)) %>% #remove columns we are not interested in looking at for now
  select(label23C, name, gbs, rep, shuLabel, date, shu, everything()) %>% #rearrange columns
  filter(!is.na(shu)) 

scaled_df <- prep_scale %>%  
  mutate(across(-all_of(exclude_columns), scale)) %>% 
  dplyr::group_by(rep, label23C) %>% arrange(date) %>% 
  
  
  
  
  
  
  
  
scaled_df <- as.data.frame(scale(df_filtered))

df_diff <- scaled_df %>%
  group_by(species) %>%
  summarize_at(vars(starts_with("feature")), ~last(.) - first(.))


# Look at PCA of features



# Look at decision tree of features


