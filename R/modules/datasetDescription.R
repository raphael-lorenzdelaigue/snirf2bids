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
    card_header("RECOMMENDED "),
    selectInput(ns("DatasetType"), label = "The interpretation of the dataset", choices = list("not specified" = "not specified", "raw" = "raw", "derivative" = "derivative"), selected = "not specified"),
    textInput(ns("License"), label = "Text acknowledging contributions of individuals or institutions beyond those listed in Authors or Funding", value = ""),
  ),
  card(
    card_header("OPTIONAL "),
    textInput(ns("Authors"), label = "List of authors involved in the project: ", value = ""),
    textInput(ns("Acknowledgements"), label = "Text acknowledging contributions of individuals or institutions beyond those listed in Authors or Funding", value = ""),
    textInput(ns("HowToAcknowledge"), label = "Instructions on how researchers using this dataset should acknowledge the original authors", value = ""),
    textInput(ns("Funding"), label = "List of sources of funding (grant numbers)", value = ""),
    textInput(ns("EthicsApprovals"), label = "List of ethics committee approvals of the research protocols and/or protocol identifiers.", value = ""),
    textInput(ns("ReferencesAndLinks"), label = "List of references to publication that contain information on the dataset, or links.", value = ""),
    textInput(ns("DatasetDOI"), label = "The Document Object Identifier of the dataset (not the corresponding paper).", value = "")
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
      dataset_description <- list()
      save_path <- file.path(converted_root(), "dataset_description.json")
      # Build the metadata list step by step
      # In order to make sure that no empty fields are included (cleaner)
      if (nzchar(input$Name)) dataset_description$Name <- input$Name
      dataset_description$BIDSVersion <- "1.4.0"  # always included

      # Dataset type, if specified
      if (input$DatasetType != "not specified") {
        dataset_description$DatasetType <- input$DatasetType
      }

      if (nzchar(input$License)) {dataset_description$License <- input$License}

      # Authors
      authors <- strsplit(input$Authors, ",\\s*")[[1]]
      if (length(authors) > 0 && any(nzchar(authors))) {
        dataset_description$Authors <- authors
      }

      # Acknowledgements
      if (nzchar(input$Acknowledgements)) {
        dataset_description$Acknowledgements <- input$Acknowledgements
      }

      if (nzchar(input$HowToAcknowledge)) {
        dataset_description$HowToAcknowledge <- input$HowToAcknowledge
      }

      # Funding
      funding <- strsplit(input$Funding, ",\\s*")[[1]]
      if (length(funding) > 0 && any(nzchar(funding))) {
        dataset_description$Funding <- funding
      }

      # Ethics Approvals
      ethics <- strsplit(input$EthicsApprovals, "\n")[[1]]
      if (length(ethics) > 0 && any(nzchar(ethics))) {
        dataset_description$EthicsApprovals <- ethics
      }

      # References
      references <- strsplit(input$ReferencesAndLinks, "\n")[[1]]
      if (length(references) > 0 && any(nzchar(references))) {
        dataset_description$ReferencesAndLinks <- references
      }

      # Dataset DOI
      if (nzchar(input$DatasetDOI)) {
        dataset_description$DatasetDOI <- input$DatasetDOI
      }

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
