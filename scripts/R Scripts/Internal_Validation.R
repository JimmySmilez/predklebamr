library(tidyverse)
library(tidymodels)
library(ranger)
library(scales)

# --- 1. CONFIGURATION ---
MODEL_FILE <- "amr_model_kp.rds"
FILE_PATH  <- "klebsiella_pneumo_complex_output.txt"

# --- 2. LOAD MODEL ---
model <- readRDS(MODEL_FILE)

# Get the original features
target_features <- model$pre$actions$recipe$recipe$var_info %>% 
  filter(role == "predictor") %>% 
  pull(variable)

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

# The fix: Add genome_id and ensure it's treated as a factor if the model expects it
processed_data <- template %>%
  mutate(genome_id = as.character(model_ready$genome_id)) %>% 
  mutate(across(everything(), ~str_replace_all(., "[[:punct:]]", "_"))) %>%
  mutate(across(everything(), as.factor))

print(paste("🔍 Feature alignment check. Columns ready:", ncol(processed_data)))

# --- 5. BATCH PREDICTION ---
# Changed the logic to ensure target_features are present without strictly capping at 38
if(all(target_features %in% colnames(processed_data))) {
  print("--- Features Aligned. Running Prediction ---")
  
  preds_class <- predict(model, processed_data)
  preds_prob  <- predict(model, processed_data, type = "prob")
  
  final_results <- tibble(
    genome_id = model_ready$genome_id,
    Predicted_Phenotype = preds_class$.pred_class,
    Confidence = pmax(preds_prob$.pred_Resistant, preds_prob$.pred_Susceptible)
  ) %>%
    mutate(Confidence = percent(Confidence, accuracy = 0.1))
  
  print("✅ Success! predictions generated.")
  View(final_results)
  
} else {
  missing <- setdiff(target_features, colnames(processed_data))
  stop(paste("Mismatch! Missing features:", paste(missing, collapse = ", ")))
}









#---------------------------------------------------------------------------------------------------
# Interpretation
#---------------------------------------------------------------------------------------------------
# 1. Load metadata and FORCE genome_id to character immediately
metadata <- read_csv("metadata_validation_internal_100.csv") %>%
  mutate(genome_id = as.character(genome_id)) %>% # <--- THE FIX
  select(genome_id, Actual = resistant_phenotype)

# 2. Ensure AI results are also character (just to be 100% safe)
final_results_clean <- final_results %>%
  mutate(genome_id = as.character(genome_id))

# 3. Join the AI predictions with the Lab results
audit_data <- final_results_clean %>%
  inner_join(metadata, by = "genome_id") %>%
  # Ensure both are factors with the same levels for comparison
  mutate(Predicted_Phenotype = factor(Predicted_Phenotype, levels = c("Resistant", "Susceptible")),
         Actual = factor(Actual, levels = c("Resistant", "Susceptible")))

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
write_csv(audit_data, "Complete_Validation_Audit.csv")
write_csv(discrepancies, "Model_Discrepancies_To_Check.csv")

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

write_csv(final_output, "Final_African_Validation_Results.csv")

print("Results consolidated and saved to Final_Validation_Results.csv")


#---------------------------------------------------------------------------------------------------
#Confusion Matrix Heatmap
#---------------------------------------------------------------------------------------------------
library(ggplot2)

# 1. Convert the confusion matrix table to a data frame
conf_matrix_df <- as.data.frame(performance$table)

# 2. Create the plot
ggplot(data = conf_matrix_df, aes(x = Reference, y = Prediction, fill = Freq)) +
  geom_tile(color = "white", lwd = 1) +
  # Add the actual numbers in the center of the tiles
  geom_text(aes(label = Freq), color = "black", size = 5) +
  # Use a professional color scale (e.g., Blues)
  scale_fill_gradient(low = "white", high = "#3182bd") +
  # Formatting for a clean "Paper-Ready" look
  theme_minimal() +
  labs(
    title = "Confusion Matrix: Genomic Phenotype Prediction",
    subtitle = paste0("Overall Accuracy: ", round(performance$overall["Accuracy"] * 100, 2), "%"),
    x = "Actual Phenotype (Metadata)",
    y = "Predicted Phenotype (Model)",
    fill = "Count"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.title = element_text(face = "bold"),
    panel.grid = element_blank()
  )

# 3. Save the plot for your paper
ggsave("Confusion_Matrix_Heatmap.png", width = 6, height = 5, dpi = 300)






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
write_csv(mismatch_profiles, "Genomic_Analysis_of_Mismatches.csv")




#----------------------------------------------------------------------------------------------------
#Feature Importance Plot
#----------------------------------------------------------------------------------------------------
# Extract Feature Importance from the Ranger engine
importance_data <- model$fit$fit$fit$variable.importance %>%
  enframe(name = "Gene", value = "Importance") %>%
  arrange(desc(Importance)) %>%
  head(15) # Top 15 drivers

# Plot it
ggplot(importance_data, aes(x = reorder(Gene, Importance), y = Importance)) +
  geom_col(fill = "#00bc8c") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Top 15 Genomic Drivers of Resistance",
       subtitle = "Which markers influenced PredKlebAMR's decisions the most?",
       x = "Genomic Marker",
       y = "Importance (Gini Index)") 

ggsave("Gini_Importance.png", width = 6, height = 5, dpi = 300)
