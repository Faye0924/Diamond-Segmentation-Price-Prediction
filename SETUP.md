# Setting Up R and RStudio

---

## Prerequisites

- **Environment:** Windows/Mac
- **RStudio availability:** Not installed by default

---

## RStudio Recommendation

- **Recommended IDE:** RStudio Desktop
- **Purpose:** Running all R scripts and R markdown files developed by the author
- RStudio is the **recommended environment** for executing this project’s code due to:
  - Integrated package management
  - Native support for pipeline workflows
  - Built‑in tools for debugging, visualization, and reproducibility
- **RStudio is required** to run the **Shiny UI application**
  - The Shiny app relies on RStudio’s “**Run App**” functionality
  - Running the app outside RStudio is not supported for this project

---

## Install R and RStudio

- **Download link:**
  - RStudio Desktop — https://posit.co/download/rstudio-desktop/

---

## R Markdown Support

- **Required package:** rmarkdown
- **Purpose:**
  - Running .Rmd files used for Pipeline
  - Rendering R scripts
- Install the package in RStudio if it is not already available:
  - Run install.packages("rmarkdown") in RStudio Console

---

## Running the Shiny Application

- **Required package:** shiny
- Install if needed: 
  - Run install.packages("shiny") in RStudio Console
- Note: Required packages may also be installed automatically when the app runs
- **Do not rename app.R**
  - Renaming the file may cause the “**Run App**” button in RStudio to disappear

---

Maintained by Xufei Lang  
Last updated: 2026‑04‑24

