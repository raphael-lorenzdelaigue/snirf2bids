library(shiny)
library(DT)
library(dplyr)
library(stringr)

fileViewer_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
  titlePanel("Folder Structure Viewer"),
  DTOutput(ns("folderTable"))
)
}
fileViewer_server <- function(id, currentConvertedPathReactive) {
  moduleServer(id, function(input, output, session) {
  observeEvent(currentConvertedPathReactive(), {
    folder_path <- currentConvertedPathReactive()
    overview_df <- generate_file_overview(folder_path)
    if (ncol(overview_df) == 0) {
      showNotification("Output folder does not contain any BIDS-formatted folder", type = "message")
    }
    output$folderTable <- renderDT({
      datatable(overview_df, options = list(pageLength = 20, scrollX = TRUE))
    })

  })
  })
}
