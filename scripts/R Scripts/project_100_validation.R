library(tidyverse)
library(stringr)
library(tidymodels)
library(ranger)
library(scales)

# --- 1. CONFIGURATION ---
FILE_PATH  <- "klebsiella_pneumo_complex_output.txt"

# --- 2. LOAD MODEL ---
final_aggressive_model <- readRDS("amr_model_kp.rds")

# Get the original features
target_features <- final_aggressive_model$pre$mold$predictors %>% colnames()

print(paste("Model is expecting", length(target_features), "features."))


# --- 3. DATA CLEANING ---
raw_lines <- readLines(FILE_PATH, warn = FALSE)
clean_lines <- gsub("\033\\[[0-9;]*m", "", raw_lines) 
clean_lines <- gsub("\\[[0-9;]*m", "", clean_lines)
clean_lines <- gsub('"', "", clean_lines)

full_df <- read_tsv(paste(clean_lines, collapse = "\n"), comment = "#")

model_ready <- full_df %>%
  rename(genome_id = any_of("strain")) %>%
  rename_with(~sapply(str_split(., "__"), tail, 1), -any_of("genome_id")) %>% 
  mutate(across(everything(), as.character))

# --- 4. THE BRIDGE ---
blueprint_list <- setNames(
  lapply(target_features, function(x) rep("neg", nrow(model_ready))), 
  target_features
)
template <- as_tibble(blueprint_list)

for(f in target_features) {
  match_idx <- which(tolower(colnames(model_ready)) == tolower(f))
  if(length(match_idx) > 0) {
    template[[f]] <- as.character(model_ready[[match_idx[1]]])
  }
}

# Add genome_id and ensure it's treated as a factor if the model expects it
processed_data <- template %>%
  mutate(genome_id = as.character(model_ready$genome_id)) %>% 
  mutate(across(everything(), ~str_replace_all(., "[[:punct:]]", "_"))) %>%
  mutate(across(everything(), as.factor))

print(paste("🔍 Feature alignment check. Columns ready:", ncol(processed_data)))

# --- 5. BATCH PREDICTION ---
processed_data <- processed_data %>%
  # Convert genome_id to numeric to match the training data 'Double' type
  mutate(genome_id = as.numeric(as.character(genome_id)))

probs <- predict(final_aggressive_model, processed_data, type = "prob")


# --- 1. SET THE THRESHOLD ---
target_threshold <- 0.3

# --- 2. GENERATE PREDICTIONS ---
# We calculate the class based on the threshold manually
final_preds <- ifelse(probs$.pred_Resistant >= target_threshold, 
                      "Resistant", "Susceptible")

# --- 3. BUILD THE FINAL RESULTS TABLE ---
final_results <- tibble(
  genome_id = model_ready$genome_id,
  Predicted_Phenotype = factor(final_preds, levels = c("Resistant", "Susceptible")),
  # Calculate confidence based on the predicted class probability
  Confidence = percent(pmax(probs$.pred_Resistant, probs$.pred_Susceptible), accuracy = 0.1),
  # Add the raw probability so you can see how 'close' the calls are
  Resistant_Prob = round(probs$.pred_Resistant, 4)
)

# --- 4. PREVIEW THE TOP HITS ---
print("--- PREDICTION PREVIEW (TOP 10) ---")
print(head(final_results, 10))







#---------------------------------------------------------------------------------------------------
# Interpretation
#---------------------------------------------------------------------------------------------------
# 1. Load metadata and force genome_id to character immediately
metadata <- read_csv("project_100.csv") %>%
  mutate(genome_id = as.character(genome_id))%>% 
  select(genome_id, Actual = resistant_phenotype)

# 2. Ensure AI results are also character (just to be 100% safe)
final_results_clean <- final_results %>%
  mutate(genome_id = as.character(genome_id))

# 3. Join the AI predictions with the Lab results
audit_data <- final_results_clean %>%
  inner_join(metadata, by = "genome_id") %>%
  mutate(
    # str_trim removes accidental spaces; str_to_title fixes "resistant" -> "Resistant"
    Actual = str_trim(Actual),
    Actual = str_to_title(Actual), 
    Actual = factor(Actual, levels = c("Resistant", "Susceptible")),
    
    Predicted_Phenotype = factor(Predicted_Phenotype, levels = c("Resistant", "Susceptible"))
  )


# 4. Generate the Confusion Matrix and Statistics
library(caret)
performance <- confusionMatrix(audit_data$Predicted_Phenotype, 
                               audit_data$Actual, 
                               positive = "Resistant")

# 5. Print the "Paper-Ready" Results
print("--- FINAL VALIDATION METRICS ---")
print(performance$table)
cat("\nOverall Accuracy: ", round(performance$overall["Accuracy"] * 100, 2), "%\n")
cat("Sensitivity (Detection): ", round(performance$byClass["Sensitivity"] * 100, 2), "%\n")
cat("Specificity (Safety): ", round(performance$byClass["Specificity"] * 100, 2), "%\n") 

# Filter just the ones where the AI and Lab disagreed
discrepancies <- audit_data %>%
  filter(Predicted_Phenotype != Actual)

# Save the full audit and the specific discrepancies
write_csv(audit_data, "Project_100_Complete_Validation_Audit.csv")
write_csv(discrepancies, "Project_100_Model_Discrepancies_To_Check.csv")

print(paste("Audit complete. Inspect 'Model_Discrepancies_To_Check.csv' to find the", 
            nrow(discrepancies), "mismatches."))


#----------------------------------------------------------------------------------------------------
#Confusion Matrix CSV
#----------------------------------------------------------------------------------------------------

# 1. Convert the Confusion Matrix to a data frame
confusion_df <- as.data.frame(performance$table) %>%
  rename(Metric = Prediction, Detail = Reference, Value = Freq) %>%
  mutate(Category = "Confusion Matrix")

# 2. Extract specific metrics and put them in the same structure
metrics_df <- data.frame(
  Category = "Summary Statistics",
  Metric = c("Overall Accuracy (%)", "Sensitivity (%)", "Specificity (%)"),
  Detail = NA,
  Value = c(
    round(performance$overall["Accuracy"] * 100, 2),
    round(performance$byClass["Sensitivity"] * 100, 2),
    round(performance$byClass["Specificity"] * 100, 2)
  )
)

# 3. Combine them and export
final_output <- bind_rows(confusion_df, metrics_df)


print("Results consolidated and saved to Final_Validation_Results.csv")


#---------------------------------------------------------------------------------------------------
#Confusion Matrix Heatmap
#---------------------------------------------------------------------------------------------------
library(ggplot2)

# 1. Convert the confusion matrix table to a data frame
conf_matrix_df <- as.data.frame(performance$table)


# Create the heatmap
ggplot(conf_matrix_df, aes(x = Reference, y = Prediction, fill = Freq)) +
  geom_tile(color = "white", size = 1) +
  scale_fill_gradient(low = "#eff3ff", high = "#08519c") +
  geom_text(aes(label = Freq), size = 10, fontface = "bold") +
  theme_minimal() +
  labs(title = "PredKlebAMR Predictions: Global Cohort",
       subtitle = paste("N = 96 | Accuracy:", round(performance$overall['Accuracy']*100, 1), "%"),
       x = "Actual (Lab Result)",
       y = "Predicted (PredKlebAMR)") +
  theme(axis.text = element_text(size = 12, face = "bold"),
        plot.title = element_text(size = 16, face = "bold"))




#---------------------------------------------------------------------------------------------------
#Managing Discrepancies
#---------------------------------------------------------------------------------------------------
# 1. Identify the 9 Discrepancies
discrepancies_list <- audit_data %>%
  filter(Predicted_Phenotype != Actual) %>%
  pull(genome_id)

# 2. Extract the key genomic markers for these specific isolates
# We go back to model_ready because it has the original Kleborate data
mismatch_profiles <- model_ready %>%
  filter(genome_id %in% discrepancies_list) %>%
  select(genome_id, 
         ST, 
         contains("Carb"), 
         contains("ESBL"), 
         contains("Omp"), 
         resistance_score) %>%
  # Join with the audit data to see what the AI vs Lab said
  left_join(audit_data, by = "genome_id") %>%
  select(genome_id, ST, Actual, Predicted_Phenotype, everything())

# 3. Print a summary to the console
print("--- GENOMIC PROFILES OF MISMATCHED ISOLATES ---")
print(mismatch_profiles)

# 4. Save for your report
write_csv(mismatch_profiles, "Project_100_Genomic_Analysis_of_Mismatches.csv")



