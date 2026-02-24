library(shiny)
library(shinyFiles)
library(jsonlite)

datasetDescription_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
  card(
    card_header("REQUIRED"),
    textInput(ns("Name"), label = "Dataset name: ", value = "")
  ),
  card(
    actionButton(ns("save_json"), "Save JSON")
  )
  )
}

datasetDescription_server <- function(id, converted_root) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_json, {
      req(converted_root())
      # Main list containing the json Content
      dataset_description <- list()

      # Output path
      save_path <- file.path(converted_root(), "dataset_description.json")

      # Build the metadata list step by step
      # In order to make sure that no empty fields are included (cleaner)
      if (nzchar(input$Name)) dataset_description$Name <- input$Name
      dataset_description$BIDSVersion <- "1.4.0"  # always included

      # Save as JSON file
      write_json(
        dataset_description,
        path = save_path,
        pretty = TRUE,
        auto_unbox = TRUE
      )

      showNotification("Saved as dataset_description.json", type = "message")
    })
  })
}
