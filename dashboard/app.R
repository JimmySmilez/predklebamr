library(shiny)
library(bslib)
library(bsicons)
library(tidymodels)
library(ranger)
library(tidyverse)
library(scales)

# --- 1. Load Trained Model ---
model <- readRDS("amr_model_kp.rds")

# --- 2. UI Design ---
ui <- page_navbar(
  title = "PredKlebAMR: Klebsiella Resistant Predictor",
  theme = bs_theme(version = 5, bootswatch = "darkly", primary = "#00bc8c"),
  sidebar = sidebar(
    title = "Data Input",
    fileInput("file", "Upload Results", accept = c(".tabular", ".tsv", ".txt")),
    helpText("Upload your Kleborate output file."),
    hr(),
    uiOutput("download_ui")
  ),
  nav_panel(
    title = "Prediction Analysis",
    layout_column_wrap(
      width = 1/2,
      value_box(
        title = "Predicted Phenotype",
        value = textOutput("pred_text"),
        showcase = bs_icon("virus"),
        theme = "primary"
      ),
      value_box(
        title = "Model Confidence",
        value = textOutput("conf_text"),
        showcase = bs_icon("shield-check"),
        theme = "info"
      )
    ),
    
    card(
      card_header(bs_icon("search"), "Genomic Evidence Found"),
      card_body(tableOutput("evidence_table"))
    )
  ),
  
  nav_panel(
    title = "Help & Interpretation",
    card(
      card_header(bs_icon("info-circle"), "How to Read the Evidence"),
      markdown("
      ### **Understanding the Biological Drivers**
      * **Carbapenemases:** KPC-2 and KPC-3 are high-potency enzymes. Presence usually confirms resistance.
      * **Porin Mutations:** OmpK35/36 mutations restrict antibiotic entry, often working with enzymes to increase resistance levels.
      * **Sequence Type (ST):** Specific High-Risk Clones, such as ST11 or ST258, serve as the primary genetic backbone for multi-drug resistance. ST11 and ST258 are globally recognized high-risk lineages associated with outbreaks.
      * **Confidence Scores:** Scores >90% indicate very high genomic certainty.
      ")
    )
  )
)



# --- 3. Server Logic ---
server <- function(input, output, session) {
  
  processed_data <- reactive({
    # 1. Define the exact path to your summary file
    # Based on your setup, it lives inside the 'kleb_output.txt' folder
    file_path <- "kleb_output.txt/klebsiella_pneumo_complex_output.txt"
    
    # 2. Safety Check: Does the file exist and is it readable?
    if (!file.exists(file_path)) {
      print(paste("Waiting for file at:", file_path))
      return(NULL)
    }
  
    # 1. READ AND PURGE ALL RED CODES
    raw_lines <- readLines(file_path, warn = FALSE)
    clean_lines <- gsub("\033\\[[0-9;]*m", "", raw_lines) 
    clean_lines <- gsub("\\[[0-9;]*m", "", clean_lines)
    clean_lines <- gsub('"', "", clean_lines)
    
    # 2. RECONSTRUCT THE FULL TABLE
    full_df <- read_tsv(paste(clean_lines, collapse = "\n"), comment = "#")
    
    # 3. THE "UNIVERSAL ALIAS" & HEADER CLEANING
    model_ready <- full_df %>%
      # FIRST: Rename 'strain' to 'genome_id' if it exists
      rename(genome_id = any_of("strain")) %>%
      # SECOND: Strip long prefixes (e.g., 'amr__') from all other 116 columns
      rename_with(~str_remove(., ".*__"), -any_of("genome_id")) %>% 
      # THIRD: Force all to character to prevent 'double' type errors
      mutate(across(everything(), as.character)) %>%
      # FOURTH: Sanitize strings for model compatibility
      mutate(across(everything(), ~str_replace_all(., "[[:punct:]]", "_")))
    
    return(model_ready)
  })
  
  # Predict Class
  output$pred_text <- renderText({
    req(processed_data())
    res <- predict(model, processed_data())
    as.character(res$.pred_class[1]) 
  })
  
  # Predict Confidence
  output$conf_text <- renderText({
    req(processed_data())
    p_df <- predict(model, processed_data(), type = "prob")
    conf_val <- max(p_df$.pred_Resistant[1], p_df$.pred_Susceptible[1])
    scales::percent(conf_val, accuracy = 0.1)
  })
  
  # Evidence Table
  output$evidence_table <- renderTable({
    req(processed_data())
    data_row <- processed_data() %>% slice(1)
    
    top_markers <- c("Bla_Carb_acquired", "Omp_mutations", "ST")
    avail <- intersect(top_markers, colnames(data_row))
    
    data_row %>%
      select(all_of(avail)) %>%
      pivot_longer(everything(), names_to = "Mechanism", values_to = "Status") %>%
      filter(!Status %in% c("neg", "0", "absent", "_"))
  }, striped = TRUE, hover = TRUE)
}

shinyApp(ui, server)