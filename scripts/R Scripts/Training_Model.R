#==========================================================================================================================================
# PROJECT: PredKlebAMR
# AUTHOR: James Mordecai
#==========================================================================================================================================

# =========================================================================================================================================
# PHASE 1: LIBRARIES & PARALLEL SETUP (128-Core Optimization, HPC)
# =========================================================================================================================================
library(tidyverse)
library(tidymodels)
library(themis)      
library(doParallel)  # For Multi-core processing
library(ranger)      
library(vip)

# Use 60 cores to keep RAM stable during the 12,000+ feature expansion
all_cores <- parallel::detectCores(logical = FALSE)
cl <- makePSOCKcluster(min(60, all_cores)) 
registerDoParallel(cl)

# ========================================================================================================================================
# PHASE 2: DATA PREP & THE KP-SPLIT
# ========================================================================================================================================
# Load the Dataset CSV 
ml_data <- read_csv("Model_Training_Data.csv") %>%
  mutate(across(where(is.character), as.factor)) %>%
  mutate(resistant_phenotype = factor(resistant_phenotype, levels = c("Resistant", "Susceptible"))) %>% 
  # Replace spaces, hyphens, and slashes in ALL columns with underscores
  mutate(across(where(is.factor), ~as.factor(str_replace_all(as.character(.), "[^[:alnum:]]", "_")))) %>%
  # Ensure column names are unique and clean
  setNames(make.names(names(.), unique = TRUE))

# Split the Dataset
set.seed(42)
data_split <- initial_split(ml_data, prop = 0.80, strata = resistant_phenotype)
train_data <- training(data_split)
test_data  <- testing(data_split)

set.seed(786)
folds <- vfold_cv(train_data, v = 5, strata = resistant_phenotype)  

# =======================================================================================================================================
# PHASE 3: THE BIOLOGICAL RECIPE & MODEL SPEC
# =======================================================================================================================================

amr_recipe_final <- recipe(resistant_phenotype ~ ., data = train_data) %>%
  update_role(genome_id, new_role = "ID") %>% 
  step_novel(all_nominal_predictors()) %>%
  step_other(ST, threshold = 0.005) %>% 
  
  # 1. Create Dummies using "long" naming to prevent duplicates
  step_dummy(all_nominal_predictors(), naming = function(var, lvl, ...) paste0(var, "_", lvl)) %>%
  
  # 2. Kill Zero Variance columns
  step_zv(all_predictors()) %>%
  
  # 3. Features Interactions 
  step_interact(terms = ~ starts_with("ST_"):matches("Omp_mutations|Bla_Carb|Bla_ESBL")) %>%
  
  # 4. Final Clean & SMOTE
  step_zv(all_predictors()) %>%
  step_smote(resistant_phenotype)


rf_spec <- rand_forest(
  mtry = tune(), 
  min_n = tune(), 
  trees = 3000 
) %>%
  set_engine("ranger", 
             importance = "impurity",
             num.threads = 1, # tune_bayes handles the parallelization
             class.weights = c("Resistant" = 20, "Susceptible" = 1)) %>%
  set_mode("classification")

final_workflow <- workflow() %>%
  add_recipe(amr_recipe_final) %>%
  add_model(rf_spec)

# ==========================================================================================================================================
# PHASE 4: DEEP BAYESIAN TUNING (50 ITERATIONS)
# ==========================================================================================================================================
# Setting mtry range to 150 because interactions create ~12,000 columns
amr_params <- extract_parameter_set_dials(final_workflow) %>%
  update(mtry = mtry(range = c(1, 150)))

set.seed(786)
final_tune_results <- tune_bayes(
  final_workflow,
  resamples = folds,
  param_info = amr_params,      
  initial = 15,
  iter = 50, 
  metrics = metric_set(roc_auc, sensitivity, specificity, j_index),
  control = control_bayes(save_pred = TRUE, no_improve = 15, verbose = TRUE)
)

# ==================================================================================================================================================
# PHASE 5: FINALIZE & VALIDATE 
# ==================================================================================================================================================
# Pick the best model based on J-Index (Balanced Sensitivity/Specificity)
best_params <- select_best(final_tune_results, metric = "j_index")

final_rs_killer_fit <- final_workflow %>%
  finalize_workflow(best_params) %>%
  fit(data = train_data)

# Test on the 1,200 "Blind" Genomes
final_blind_test_metrics <- final_rs_killer_fit %>%
  augment(test_data) %>%
  mutate(pred_class = factor(ifelse(.pred_Resistant >= 0.3, "Resistant", "Susceptible"), 
                             levels = c("Resistant", "Susceptible"))) %>%
  metric_set(accuracy, sensitivity, specificity, j_index)(truth = resistant_phenotype, estimate = pred_class)

# =======================================================================================================================================
# PHASE 6: SAVE & FINISH
# =======================================================================================================================================
stopCluster(cl)
saveRDS(final_rs_killer_fit, "BIOLOGICAL_KP_MODEL.rds")

print("--- FINAL BLIND TEST PERFORMANCE ---")
print(final_blind_test_metrics)
cat("\nModel saved as BIOLOGICAL_KP_MODEL.rds\n")  


# ============================================================================================================================
# PHASE 7: GENOMIC IMPORTANCE (GINI PLOT) 
# ============================================================================================================================
library(vip)

# 1. Extract the underlying engine and plot the top 20 features
importance_plot <- final_rs_killer_fit %>%
  extract_fit_engine() %>%
  vi(method = "impurity") %>% # Gini impurity is the standard for RF
  slice_max(Importance, n = 20) %>%
  ggplot(aes(x = reorder(Variable, Importance), y = Importance)) +
  geom_col(fill = "#2c3e50") +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Top 20 Genomic Predictors of Resistance",
    subtitle = "PredKlebAMR",
    x = "Genomic Feature / Interaction",
    y = "Importance (Gini Index)"
  )

# Display the plot
print(importance_plot)

