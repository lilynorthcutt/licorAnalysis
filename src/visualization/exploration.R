source("preprocess.R")

#####################
### Visualize Data
#####################
# 1. LICOR #####################################################################


# 2. SHU #######################################################################
genoList <- unique(hplcRaw$label23C)
geno <- genoList[1]

# Graph 1 - count of samples per genotype
ggplot(hplcDf) + 
  geom_bar(aes(x = label23C))+ facet_wrap(.~location)
ggplot(hplcDf) + 
  geom_bar(aes(x = label23C, color = location, fill = location))

# Graph 2 - number of each type of spicy
ggplot(hplcDf)+
  geom_bar(aes(x = shuLabel, color = location, fill = location), position = position_dodge())



# Graph 2 - all shu for each individual genotype as basic point graph
ggplot(hplcDf %>% filter(label23C == geno))+
  geom_point(aes(x = sampleCount, y = hplc, color = shuLabel)) + 
  facet_wrap(.~ location)

# Graph 3 - all shu for each individual genotype as basic boxplot 
ggplot(hplcDf %>% filter(label23C == genoList[1])) +
  geom_boxplot(aes(x = label23C, y = hplc, group = label23C)) +
  geom_hline(yintercept=2000, linetype="dashed", color = "red")+
  geom_hline(yintercept=5000, linetype="dashed", color = "red")+
  facet_wrap(.~location)



ggplot(hplcDf ) +
  geom_boxplot(aes(x = label23C, y = hplc, group = label23C)) +
  geom_hline(yintercept=2000, linetype="dashed", color = "red")+
  geom_hline(yintercept=5000, linetype="dashed", color = "red")


# Graph 4 - Comparing Average HPLC by genotype at by location
df_all <- hplcDf %>% group_by(label23C) %>% summarise(avgHplc = mean(hplc, na.rm = T), count = n())
df_loc <- hplcDf %>% group_by(label23C, location) %>% summarise(avgHplc = mean(hplc, na.rm = T), count = n())

ggplot(df_loc) + 
  geom_bar(aes(x = label23C, y = avgHplc, color = location, fill = location), 
           stat='identity', position = position_dodge()) +
  
  geom_hline(yintercept=2000, linetype="dashed", color = "red")+
  geom_hline(yintercept=5000, linetype="dashed", color = "red")

# Graph 5 - histogram of spicy
ggplot(hplcDf) + 
  geom_histogram(aes(x = hplc))
ggplot(hplcDf) + 
  geom_histogram(aes(x = hplc), binwidth = 550)+
  facet_wrap(.~location, nrow =2)


# 3. HARVEST ###################################################################
# Look at # fruits / flowers vs harvesting date/harvest data



