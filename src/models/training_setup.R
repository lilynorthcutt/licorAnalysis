packages <- c("stats", "caret", # A little of everything
              'rpart', 'rpart.plot', # Decision Tree
              'randomForest', # RF
              'glmnet', 'ISLR', # ridge and lasso
              'e1071', #svm
              'gbm', 'h2o', 'xgboost'      #gradient boosted machines
              ) 
invisible(lapply(packages, require, character.only = TRUE ))
source('src/data/funcs.R')

# Load your data
data <- read.csv('Data/processed/data.csv') %>% select(-X, -gbs.y, -name.y) %>% 
  dplyr::rename(gbs = gbs.x, name = name.x) %>% mutate(
    label23C = convertNumTo3DigitChar(label23C)
  )

# Remove if all values are the same
same_val_col_list <- colnames(data[vapply(data, function(x) length(unique(x)) <= 1, logical(1L))])

data <- data[vapply(data, function(x) length(unique(x)) > 1, logical(1L))]

# Remove rows where SHU is NA, and keep only LICOR data
rm_col <- c("avg_height", "avg_width", "avg_height_to_first_bifurcation",
                "avg_no_of_basal_branches", "row", "no_of_transplants", "no_of_floweers", 
                "no_of_fruits", "date_harvested", "plants_harvested", "yield", "red_yield", 
                "green_yield", "X10_fruit_weight_kg", "fruits_on_transplant", 
                "flowers_on_transplant", "transplanted_date", "days_from_t_to_h",                
                "transplants_with_flowers", "transplants_with_fruits")
data %<>% filter(!is.na(shu)) %>% select(-all_of(rm_col)) %>% 
  select(-gbs, -name, # these are the same as label23C
         )

# FOR NOW: remove first date from leyendecker
data %<>% filter(!(date == "2023-06-20" ))

#### Add scaled columns
numeric_cols <- sapply(data, is.numeric)
categorical_cols <- !numeric_cols

# Scale/normalize/standardize numeric features
preprocess_params <- preProcess(data[, numeric_cols], method = c("scale", "center"))

# Apply the preprocessing to the numeric features
scaled_data <- predict(preprocess_params, newdata = data[, numeric_cols]) %>% select(-rep, -shu) 
colnames(scaled_data) <- paste0(colnames(scaled_data), "_scaled")


# Combine scaled numeric features with categorical features
processed_data <- cbind(data, scaled_data)
scaled_only_data <- cbind(data[categorical_cols], scaled_data)


################################################################################
################################################################################
################################################################################


# Set seed for reproducibility
set.seed(1)

# Split the data into training and testing sets (80% training, 20% testing)
trainIndex <- createDataPartition(processed_data$shuLabel, p = 0.8, list = FALSE)
training_data <- processed_data[trainIndex, ]
testing_data <- processed_data[-trainIndex, ]

# Define cross-validation settings
control <- trainControl(method = "cv", number = 10)

# Initialize an empty dataframe to store results
model_df <- tibble(model_type = character(),
                       trained_model = list(),
                       predictions = list(),
                       performance = numeric(),
                       stringsAsFactors = FALSE)

eval <- testing_data %>% select(shu, shuLabel)

################################################################################
################################################################################
################################################################################
### PCA ###
data_without_shu <- subset(data, select = -shu)
numeric_cols <- sapply(data_without_shu, is.numeric)
pca_result <- prcomp(data_without_shu[, numeric_cols], scale. = TRUE)
pc_data <- as_tibble(predict(pca_result))
processed_data_pca <- cbind( data[!numeric_cols], pc_data)


training_data_pca <- processed_data_pca[trainIndex, ] %>% as_tibble()
testing_data_pca <- processed_data_pca[-trainIndex, ]%>% as_tibble()






################################################################################
### DECISION TREE ###
control <- rpart.control(minsplit = 20, minbucket = 5, maxdepth=30)

fit <- rpart(shu~.,
             data = training_data %>% select(-shuLabel), 
             control=control
             )
rpart.plot(fit)
summary(fit)

eval$pred_tree <- predict(fit, testing_data)
cor(eval$pred_tree,testing_data$shu)^2
# 0.7794406

ggplot(eval)+
  geom_point(aes(x = shu, y = pred_tree, color = shuLabel))+
  geom_line(aes(x = shu, y = shu)) + 
  ggtitle("SHU vs Predicted Value using Decision Trees")+
  xlab("SHU")+ylab("Predicted SHU")

# Without label23C
control <- rpart.control(minsplit = 20, minbucket = 5, maxdepth=30)

fit <- rpart(shu~.,
             data = training_data %>% select(-shuLabel, -label23C), 
             control=control
)
rpart.plot(fit)
summary(fit)

eval$pred_tree <- predict(fit, testing_data)
cor(eval$pred_tree,testing_data$shu)^2
# 0.2195262


ggplot(eval)+
  geom_point(aes(x = shu, y = pred_tree, color = shuLabel))+
  geom_line(aes(x = shu, y = shu)) + 
  ggtitle("SHU vs Predicted Value using Decision Trees")+
  xlab("SHU")+ylab("Predicted SHU")

# with pca data
fit <- rpart(shu ~ .,
             data = training_data_pca %>% select(-shuLabel), 
             control=control)

rpart.plot(fit)
summary(fit)

eval$pred_tree <- predict(fit, testing_data)
cor(eval$pred_tree,testing_data$shu)^2
# 0.7794406

ggplot(eval)+
  geom_point(aes(x = shu, y = pred_tree, color = shuLabel))+
  geom_line(aes(x = shu, y = shu)) + 
  ggtitle("SHU vs Predicted Value using Decision Trees")+
  xlab("SHU")+ylab("Predicted SHU")



################################################################################
### RANDOM FOREST ###

rf <- randomForest(shu~., data=training_data, proximity=TRUE)
model_rf = randomForest(x = training_data %>% select(-shu, -shuLabel), 
                             y = training_data$shu, 
                             ntree = 100)

model_rf
plot(model_rf)
importance(model_rf) 
varImpPlot(model_rf)


eval$pred_rf<- predict(model_rf, newdata = testing_data) 
cor(eval$pred_rf,testing_data$shu)^2
# 0.3694097

ggplot(eval)+
  geom_point(aes(x = shu, y = pred_rf, color = shuLabel))+
  geom_line(aes(x = shu, y = shu)) + 
  ggtitle("SHU vs Predicted Value using Random Forest on Test Set")+
  xlab("SHU")+ylab("Predicted SHU")



################################################################################
### RIDGE AND LASSO ###

# Training
x = model.matrix(shu~., training_data %>% select(-shuLabel))[,-1] # trim off the first column
# leaving only the predictors
y = training_data %>%
  select(shu) %>%
  unlist() %>%
  as.numeric()
# Testing
x_test = model.matrix(shu~., testing_data %>% select(-shuLabel))[,-1]
setdiff(colnames(x), colnames(x_test))
# "label23C089" "label23C099" "label23C101" "label23C102" "label23C105"
# These labels are in training set but not test set, thus when labels are one hot encoded in mat
# we have missing values. Adding them in s.t. all cols are the same between train and test
x_test = model.matrix(shu~., testing_data %>% select(-shuLabel) %>% 
                        mutate(label23C089 = 0,label23C099 = 0, label23C101 = 0,
                               label23C102 = 0, label23C105 = 0))[,-1]

# ridge
ridge_mod = cv.glmnet(x, y, alpha = 0)
bestlambda = ridge_mod$lambda.min
bestlambda
plot(ridge_mod) 


eval$pred_ridge <- predict(ridge_mod,  x_test, s = bestlambda)
cor(as.numeric(eval$pred_ridge),as.numeric(eval$shu))^2
# 0.0001525566

# lasso
lasso_mod = cv.glmnet(x, y, alpha = 1)
bestlambda = lasso_mod$lambda.min
bestlambda
plot(lasso_mod) 


eval$pred_lasso <- predict(lasso_mod,  x_test, s = bestlambda)
cor(as.numeric(eval$pred_ridge),as.numeric(eval$shu))^2
# 0.0001525566

################################################################################



################################################################################
### SVM
svmfit = svm(shu ~ ., data = training_data %>% select(-shuLabel))
print(svmfit)

eval$pred_svr = predict(svmfit, testing_data)
cor(eval$pred_svr,eval$shu)^2
# 0.0001229905


ggplot(eval)+
  geom_point(aes(x = shu, y = pred_svr, color = shuLabel))+
  geom_line(aes(x = shu, y = shu)) + 
  ggtitle("SHU vs Predicted Value using SVM")+
  xlab("SHU")+ylab("Predicted SHU")



################################################################################
### GBM


ames_gbm1 <- gbm(
  formula = shu ~ .,
  data = training_data %>% select(-shuLabel),
  distribution = "gaussian",  # SSE loss function
  n.trees = 5000,
  shrinkage = 0.1,
  interaction.depth = 3,
  n.minobsinnode = 10,
  cv.folds = 10
)


################################################################################
################################################################################
################################################################################

# Function to train and evaluate models
train_and_evaluate <- function(model_type, formula) {
  # Train the model using cross-validation
  model <- train(shuLabel ~ . , 
                 data = training_data, 
                 method = "rpart", 
                 trControl = control)
  
  # Make predictions on the testing data
  predictions <- predict(model, testing_data)
  
  # Evaluate the model performance
  performance <- postResample(pred = predictions, obs = testing_data$shu)
  
  # Add results to model_df
  model_df[nrow(model_df) + 1, ] <- list(model_type, model, predictions, performance)
}

# Train and evaluate decision tree
train_and_evaluate("rpart", shu ~ .)

# Train and evaluate random forest
train_and_evaluate("rf", shu ~ .)

# Train and evaluate ridge regression
train_and_evaluate("ridge", shu ~ .)

# Train and evaluate lasso regression
train_and_evaluate("lasso", shu ~ .)

# Train and evaluate support vector machine
train_and_evaluate("svmLinear", shu ~ .)

# Train and evaluate naive Bayes
train_and_evaluate("nb", shu ~ .)

# Print model_df
print(model_df)
