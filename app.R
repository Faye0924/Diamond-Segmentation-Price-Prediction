# =========================================
# Minimal Shiny: PAM (Gower) + Saved per-cluster models
# Dataset: Diamonds (Generic Adaptation)
# =========================================
library(shiny)
library(cluster)
library(plotly)
library(randomForest)
library(gbm)
library(dplyr)
library(readr)
library(forcats)

# ----------------- Helpers -----------------
preprocess_data <- function(df) {
  # Chars -> factors (Crucial for diamonds: cut, color, clarity)
  df %>% mutate(across(where(is.character), as.factor))
}

defaults_from <- function(df, feats) {
  setNames(lapply(feats, function(f) {
    if (!f %in% names(df)) return(NA)
    v <- df[[f]]
    if (is.numeric(v)) {
      round(median(v, na.rm = TRUE), 3)
    } else if (is.factor(v)) {
      levels(v)[1]
    } else {
      sort(unique(v))[1]
    }
  }), feats)
}

ui_inputs <- function(df, feats, defs) {
  lapply(feats, function(f) {
    if (!f %in% names(df)) return(NULL)
    if (is.numeric(df[[f]])) {
      numericInput(f, f, value = as.numeric(defs[[f]]))
    } else {
      choices <- if (is.factor(df[[f]])) levels(df[[f]]) else sort(unique(df[[f]]))
      selectInput(f, f, choices = choices, selected = defs[[f]])
    }
  })
}

coerce_row <- function(input_list, ref_df, feats) {
  out <- lapply(feats, function(f) {
    val <- input_list[[f]]
    if (is.numeric(ref_df[[f]])) {
      as.numeric(val)
    } else if (is.factor(ref_df[[f]])) {
      factor(val, levels = levels(ref_df[[f]]))
    } else {
      as.character(val)
    }
  })
  df <- as.data.frame(out, check.names = FALSE, stringsAsFactors = FALSE)
  colnames(df) <- feats
  for (f in feats) {
    if (is.factor(ref_df[[f]])) df[[f]] <- factor(df[[f]], levels = levels(ref_df[[f]]))
  }
  df
}

align_types <- function(new_df, ref_df, feats) {
  for (f in feats) {
    if (!f %in% names(ref_df)) next
    if (is.factor(ref_df[[f]])) {
      new_df[[f]] <- factor(new_df[[f]], levels = levels(ref_df[[f]]))
    } else if (is.numeric(ref_df[[f]])) {
      new_df[[f]] <- suppressWarnings(as.numeric(new_df[[f]]))
    } else {
      new_df[[f]] <- as.character(new_df[[f]])
    }
  }
  new_df
}

assign_medoid <- function(one_row, medoid_profiles) {
  cf <- colnames(medoid_profiles)
  x <- one_row[, cf, drop = FALSE]
  for (nm in cf) {
    if (is.factor(medoid_profiles[[nm]])) x[[nm]] <- factor(x[[nm]], levels = levels(medoid_profiles[[nm]]))
  }
  m <- as.matrix(daisy(rbind(medoid_profiles, x), metric = "gower"))
  which.min(m[nrow(m), 1:nrow(medoid_profiles)])
}

assign_dataset <- function(df, medoid_profiles) {
  cf <- colnames(medoid_profiles)
  sub <- df[, cf, drop = FALSE]
  for (nm in cf) {
    if (is.factor(medoid_profiles[[nm]])) sub[[nm]] <- factor(sub[[nm]], levels = levels(medoid_profiles[[nm]]))
  }
  m <- as.matrix(daisy(rbind(medoid_profiles, sub), metric = "gower"))
  K <- nrow(medoid_profiles); n <- nrow(sub)
  max.col(-m[(K + 1):(K + n), 1:K, drop = FALSE])
}

# Helper to identify model type
label_model <- function(m) {
  if (inherits(m, "gbm"))          return("GBM")
  if (inherits(m, "randomForest")) return("Random Forest")
  paste(class(m)[1], collapse = "/") # Fallback for other types
}

# ----------------- UI -----------------
ui <- fluidPage(
  div(
    style = "text-align: left; margin-bottom: 20px;",
    h2("Diamond Segmentation & Price Prediction"),
    h4("Author: Xufei Lang"),
  ),
  
  titlePanel(textOutput("title_txt")),
  sidebarLayout(
    sidebarPanel(
      h4("Upload Data and Bundle"),
      fileInput("data_csv", "Upload sample Diamonds (.csv)", accept = ".csv"),
      fileInput("pam_rds",  "Upload PAM Bundle (.rds)", accept = ".rds"),
      tags$hr(),
      h4("Step 1 - Clustering Features"),
      uiOutput("cluster_inputs"),
      fluidRow(
        column(6, actionButton("assign", "Assign Cluster", class="btn-primary")),
        column(6, actionButton("reset1", "Reset Step 1"))
      ),
      uiOutput("cluster_msg"),
      
      conditionalPanel(
        condition = "output.hasCluster == true",
        tags$hr(),
        h4("Step 2 - Prediction Features"),
        uiOutput("model_inputs"),
        fluidRow(
          column(6, actionButton("predict", "Predict Target", class="btn-success")),
          column(6, actionButton("reset2", "Reset Step 2"))
        )
      )
    ),
    mainPanel(
      h4("Segmentation"), textOutput("assign_txt"),
      h4("Prediction"), textOutput("pred_txt"),
      h4("Medoid Profiles"), tableOutput("med_tbl"),
      h4("3D MDS Visualization"), plotlyOutput("plot3d", height="70vh")
    )
  )
)

# ----------------- Server -----------------
server <- function(input, output, session) {
  # Load
  bundle <- reactive({ req(input$pam_rds); readRDS(input$pam_rds$datapath) })
  data_raw <- reactive({ req(input$data_csv); read_csv(input$data_csv$datapath, show_col_types = FALSE) |> as.data.frame() })
  data_prep <- reactive({ req(data_raw()); preprocess_data(data_raw()) })
  
  target_name <- reactive({
    tn <- bundle()$target_name
    if (is.null(tn) || is.na(tn)) "Price" else as.character(tn)
  })
  
  
  # Bundle Parts
  medoids <- reactive({
    mp <- as.data.frame(bundle()$medoid_profiles, stringsAsFactors = FALSE)
    if (is.null(colnames(mp)) || any(colnames(mp) == "")) colnames(mp) <- as.character(bundle()$cluster_feature)
    mp
  })
  
  cf <- reactive({
    cf0 <- bundle()$cluster_feature
    if (is.null(cf0) || length(cf0) == 0) colnames(medoids()) else as.character(cf0)
  })
  
  f_c1 <- reactive({ as.character(bundle()$topN_c1) })
  f_c2 <- reactive({ as.character(bundle()$topN_c2) })
  mod1 <- reactive({ bundle()$model_c1 })
  mod2 <- reactive({ bundle()$model_c2 })
  nt1  <- reactive({ as.integer(bundle()$model_c1_gbm_n_trees) })
  nt2  <- reactive({ as.integer(bundle()$model_c2_gbm_n_trees) })
  
  rv <- reactiveValues(def = NULL, cl = NULL)
  
  observeEvent(list(data_prep(), bundle()), {
    feats <- sort(unique(c(cf(), f_c1(), f_c2())))
    rv$def <- defaults_from(data_prep(), feats)
    rv$cl <- NULL
  })
  
  output$cluster_inputs <- renderUI({
    req(data_prep(), rv$def)
    do.call(tagList, ui_inputs(data_prep(), cf(), rv$def))
  })
  
  observeEvent(input$assign, {
    valid_cf <- intersect(cf(), colnames(medoids()))
    req(length(valid_cf) > 0)
    row_cf <- coerce_row(input, data_prep(), valid_cf)
    rv$cl <- assign_medoid(row_cf, medoids()[, valid_cf, drop = FALSE])
    output$assign_txt <- renderText(paste("Assigned to Cluster:", rv$cl))
  })
  
  output$cluster_msg <- renderUI({
    if (is.null(rv$cl)) em("Please assign a cluster first.") else strong(paste("Current Cluster:", rv$cl))
  })
  
  output$hasCluster <- reactive(!is.null(rv$cl))
  outputOptions(output, "hasCluster", suspendWhenHidden = FALSE)
  
  model_feats <- reactive({
    req(rv$cl)
    setdiff(if (rv$cl == 1) f_c1() else f_c2(), cf())
  })
  
  output$model_inputs <- renderUI({
    req(data_prep(), rv$def, model_feats())
    do.call(tagList, ui_inputs(data_prep(), model_feats(), rv$def))
  })
  
  # Predict Logic
  observeEvent(input$predict, {
    req(rv$cl, data_prep())
    
    # 1. Get model and features from bundle
    model <- if (rv$cl == 1) mod1() else mod2()
    feats <- if (rv$cl == 1) f_c1() else f_c2()
    
    # 2. Identify the model name/type
    lbl <- label_model(model)
    
    # 3. Prepare data
    one   <- coerce_row(input, data_prep(), unique(c(cf(), feats)))
    x     <- align_types(one[, feats, drop = FALSE], data_prep(), feats)
    
    # 4. Run prediction
    y <- tryCatch({
      if (inherits(model, "gbm")) {
        nt <- if (rv$cl == 1) nt1() else nt2()
        # Fallback if n.trees is missing in bundle
        if (is.null(nt) || is.na(nt)) nt <- 100 
        predict(model, newdata = x, n.trees = nt)
      } else {
        predict(model, newdata = x)
      }
    }, error = function(e) NA_real_)
    
    # 5. Display with Model Name
    output$pred_txt <- renderText({
      if (is.na(y)[1]) {
        sprintf("Cluster %s prediction failed.", rv$cl)
      } else {
        # Format: Cluster 1 - GBM: Price = 5400.25
        sprintf("Cluster %s - %s: %s = %.2f", 
                rv$cl, lbl, target_name(), as.numeric(y))
      }
    })
  })
  
  # Visualization
  output$plot3d <- renderPlotly({
    req(data_prep(), medoids())
    cfv <- intersect(cf(), names(data_prep()))
    
    # 1. Prepare data for MDS (Full data + current user input)
    nr   <- coerce_row(input, data_prep(), cfv)
    comb <- rbind(data_prep()[, cfv, drop = FALSE], nr)
    
    # 2. Compute Gower distance and MDS coordinates
    dist_obj <- daisy(comb, metric = "gower")
    coords   <- cmdscale(dist_obj, k = 3)
    
    # 3. Separate the dataset points and the user input point
    df_plot <- data.frame(coords[1:nrow(data_prep()), ])
    colnames(df_plot) <- c("X", "Y", "Z")
    df_plot$Cluster <- factor(assign_dataset(data_prep()[, cfv], medoids()[, cfv]))
    
    usr_coord <- coords[nrow(coords), ]
    
    # 4. Build the plot
    p <- plot_ly() %>%
      # Dataset points trace (grouped by Cluster)
      add_trace(
        data = df_plot,
        x = ~X, y = ~Y, z = ~Z,
        color = ~Cluster,
        type = "scatter3d",
        mode = "markers",
        marker = list(size = 3, opacity = 0.6),
        hoverinfo = "text",
        text = ~paste("Cluster:", Cluster)
      ) %>%
      # Single "Current Input" trace
      add_trace(
        x = usr_coord[1],
        y = usr_coord[2],
        z = usr_coord[3],
        name = "Your Input",
        type = "scatter3d",
        mode = "markers",
        marker = list(
          size = 8, 
          color = "red", 
          symbol = "diamond",
          line = list(color = "black", width = 2)
        ),
        hoverinfo = "text",
        text = "Your Input"
      ) %>%
      layout(
        scene = list(
          xaxis = list(title = "Dim 1"),
          yaxis = list(title = "Dim 2"),
          zaxis = list(title = "Dim 3")
        ),
        legend = list(orientation = "h", y = -0.1)
      )
    
    p
  })
  
  output$med_tbl <- renderTable({
    req(medoids())
    cbind(Cluster = seq_len(nrow(medoids())), medoids())
  })
  
  # Resets
  observeEvent(input$reset1, { rv$cl <- NULL; output$assign_txt <- renderText(""); output$pred_txt <- renderText("") })
  observeEvent(input$reset2, { output$pred_txt <- renderText("") })
}

shinyApp(ui, server)