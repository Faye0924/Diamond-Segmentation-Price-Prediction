## Diamond Segmentation & Price Prediction 

---

## Project Overview

Due to NDA restrictions on the original sponsor dataset, this repository uses the built-in `diamonds` dataset as a substitute to demonstrate the end-to-end modeling workflow without exposing confidential business data. The project preserves the original PAM (Gower distance) clustering and per-cluster prediction framework while adapting the preprocessing pipeline and Shiny application to fit the new dataset structure.

The Shiny UI was simplified by removing sponsor-specific components such selected account_id highlighting, dataset download features, and the interactive hover display of account_id in the 3D visualization. These changes result in a cleaner and more reproducible demonstration of segmentation and prediction modeling.

---

## Project Structure

To simplify reproducibility and avoid including sponsor-specific file paths, all files in this repository are organized within a single folder rather than the original multi-folder project structure used in the sponsor environment. This allows the project to run more easily as a standalone demonstration while preserving the core modeling and Shiny application workflow.

```text
Diamond Segmentation & Price Prediction/ 
│ 
├── README.md      # Project overview (this file) 
├── README.html    # Project overview preview (open in browser) 
│ 
├── SETUP.md       # Setting up R and RStudio 
├── SETUP.html     # Setting up R and RStudio preview (open in browser)
│ 
├── diamonds_sample1000.csv    # Sample dataset used by pipeline & shiny UI 
│ 
├── segmented_predictive_modeling_pipeline.rmd    # Pipeline 
│ 
├── segmented_predictive_modeling_pipeline.html    # Rendered HTML file from pipeline 
│
├── pam_bundle.rds    # Serialized `.rds` artifact used by Shiny UI 
│
└── app.R    # Shiny UI application 
```

---

## Data Sources

- The `diamonds` dataset from R ggplot2 package, sampled 1000 rows to match the scale of the sponsor’s dataset.

- **File:** `diamonds_sample1000.csv`

---

## Data Cleaning & Integration Process

The original practicum project included a dedicated data cleaning, integration and merging stage to combine multiple sponsor datasets from Snowflake and prepare the final modeling dataset for multiple targets. Due to NDA restrictions, those source files and workflows are not included in this repository.

For this public version, the built-in `diamonds` dataset is used as a substitute, so **the original multi-source data integration step is omitted**. 

---

## Cluster Analysis

The original practicum project included a more detailed cluster analysis phase, including cluster interpretation and business-focused profiling of customer segments. This portion of the work was primarily led by another team member and therefore **is not included in this repository**.

This public version focuses on the clustering implementation, cluster assignment, and per-cluster prediction workflow within the Shiny application, rather than the full business interpretation of cluster results.

---

## Analytical Pipeline Overview

- **Pipeline Structure:** The original sponsor workflow consisted of three separate pipelines for different tasks. In this repository, they have been merged into a single unified pipeline to improve clarity, reproducibility, and ease of demonstration.

- Original Pipeline 1 - Feature Selection and Clustering: Feature selection and clustering are applied to identify meaningful segments and generate cluster assignments.

- Original Pipeline 2 - Predictive Models Comparison: Multiple predictive models are trained and evaluated within each cluster to identify the best‑performing configurations.

- Original Pipeline 3 - Optimal Models for Shiny: Final clustering results and selected models are consolidated into serialized artifacts for use in the Shiny application.

- **File:** `segmented_predictive_modeling_pipeline.rmd`

- Detailed outputs are stored in `segmented_predictive_modeling_pipeline.html`.

---

## Shiny App (Segmentation & Prediction)

- An interactive Shiny app for **cluster assignment, cluster‑aware prediction, and 3D MDS visualization** using PAM (Gower) and pre‑trained per‑cluster models.

- **File:** `app.R`

- **Inputs:** `diamonds_sample1000.csv`, `pam_bundle.rds`

**Prerequisites:** Refer to `SETUP.md` for environment setup and required R packages.

**Note:** This code was generated with the assistance of **Google Gemini (AI)** and refined by the author through iterative guidance, adjustments, and validation.

---

## Execution Order (High Level)

### Prerequisites

- Refer to `SETUP.md` for environment setup and dependency details

- Required R packages are loaded directly in the code  

### Standard Usage (Recommended)

Launch the Shiny app: 

- Open `app.R` in RStudio

- Click the **Run App** button in the editor 

All required intermediate datasets, models, and artifacts have already been generated and saved.

This is the intended path for most users.

---

Last updated: 2026‑04‑24

