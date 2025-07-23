library(shiny)
library(shinyFiles)
library(bslib)
library(readr)
library(readxl)
library(tools)
library(DT)

participantSelection_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
  # File browser to load required file
  card(
    card_header("Please select the file containing the participant information. Valid formats are .csv, .tsv, .xls and .xlsx"),
    fileInput(ns("participant_overview"), label = NULL)),
  # Data Table display
  card(
    card_header("Please select the column of the participant IDs"),
    dataTableOutput(ns("participant_overview_ui"))),
  card(
    card_header("Selected column data"),
    dataTableOutput(ns("selected_column_data_ui"))
  ),
  card(
    actionButton(ns("confirmParticipantSelection"), "Confirm participant selection")
  ))
}

participantSelection_server <- function(id, convertedPathReactive) {
  moduleServer(id, function(input, output, session) {
  # Reactive expression to read the selected file
  participant_overview_table <- reactive({
    # Read file and extension type dynamically based on input
    req(input$participant_overview)
    file <- input$participant_overview$datapath
    extension <- tolower(file_ext(input$participant_overview$name))
    # Handle csv, tsv, xls, xlsx flexibly
    switch(extension,
           "csv"  = read_csv(file),
           "tsv"  = read_tsv(file),
           "xls"  = read_excel(file),
           "xlsx" = read_excel(file),
           stop("Unsupported file type")
    )
  })

  # Another reactive for selected ids, that is returned by the server to main app
  selected_ids <- reactive({
    # If no column is selected just return NULL
    if (is.null(input$participant_overview_ui_columns_selected)) {
      return(NULL)
    }

    # Else read ID's out of selected column
    idx <- input$participant_overview_ui_columns_selected
    df <- participant_overview_table()
    vals <- df[[idx]]

    # Clean from NA's and return
    vals <- vals[!is.na(vals)]
    vals
  })
  # Display the dataset
  # ... and allow user to select a column, which DT allows to do directly
  output$participant_overview_ui <- DT::renderDT({
    DT::datatable(
      participant_overview_table(),
      selection = list(mode = "single", target = "column"),
      options = list(scrollX = TRUE)
    )})

  # Display list of selected participants for user check
  output$selected_column_data_ui <- DT::renderDT({
    DT::datatable(data.frame(selected_ids()), colnames = input$participant_overview_ui_columns_selected)
  })

  # Create folder structure with given participants
  observeEvent(input$confirmParticipantSelection, {
    showNotification(paste("List of participants has been confirmed"), type = "message")
  })

  # Return reactives to main app for use in other modules
  return(list(
    selected_ids = selected_ids
  ))
  })
}

