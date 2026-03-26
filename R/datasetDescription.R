library(shiny)
library(shinyFiles)
library(jsonlite)
library(bslib)

#' Helper function for dataset description
#' @param id takes app id
#' @export
datasetDescription_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    card(
      style = "background-color: #f8f9fa;",
      div(
        style = "font-size: 1.05rem;",
        strong("Instruction:"),
        br(),
        "Please now provide a general description of the dataset. The name is required; other fields are optional according to current BIDS specifications.",
      )
    ),
  card(
    card_header("REQUIRED"),
    textInput(ns("Name"), label = "Dataset name: ", value = "", width = "100%")
  ),
  card(
    card_header("OPTIONAL"),
    textAreaInput(ns("Authors"), label = "List of individuals who contributed to the creation/curation of the dataset.", value = "", rows = 3, width = "100%"),
    textAreaInput(ns("ReferencesAndLinks"), label = "List of references to publications that contain information on the dataset. A reference may be textual or a URI.", value = "", rows = 3, width = "100%"),
    textAreaInput(ns("datasetDOI"), label = "Digital Object Identifier of the dataset (not the corresponding paper). Should be expressed as a valid URI, not bare DOI.", value = "", rows = 3, width = "100%")
  ),
  card(
    actionButton(ns("save_json"), "Save JSON")
  )
  )
}

#' Dataset Description Shiny Module Server
#'
#' This Shiny module server handles the dataset description inputs from the user
#' and saves a BIDS-compliant `dataset_description.json` file.
#'
#' @param id Character. Shiny module namespace ID.
#' @param converted_root Reactive. The path to the folder where the BIDS dataset will be saved.
#'
#' @return A list containing:
#'   \describe{
#'     \item{dataset_name}{Reactive expression returning the dataset name input by the user.}
#'   }
#' @export

datasetDescription_server <- function(id, converted_root) {
  moduleServer(id, function(input, output, session) {

    dataset_name <- reactive({ input$Name }) # Define reactive for dataset name

    observeEvent(input$save_json, {
      req(converted_root())
      # Main list containing the json Content
      dataset_description <- list()

      # Output path
      save_path <- file.path(converted_root(), "dataset_description.json")

      # Build the metadata list step by step
      # In order to make sure that no empty fields are included (cleaner)
      if (nzchar(input$Name)) dataset_description$Name <- input$Name
      if (nzchar(input$Authors)) {
        authors <- strsplit(input$Authors, split = "[,\n]")[[1]]  # split by comma or newline
        authors <- trimws(authors)  # remove leading/trailing spaces
        authors <- authors[authors != ""]  # remove empty entries
        dataset_description$Authors <- authors
      }
      if (nzchar(input$ReferencesAndLinks)) dataset_description$ReferencesAndLinks <- input$ReferencesAndLinks
      if (nzchar(input$datasetDOI)) dataset_description$datasetDOI <- input$datasetDOI
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

    return(list(dataset_name = dataset_name))
  })
}
