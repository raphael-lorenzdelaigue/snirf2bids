library(shiny)
library(DT)
library(dplyr)
library(stringr)

folderCheck_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    titlePanel("Folder Check"),
    DTOutput(ns("folderTable"))
  )
}

folderCheck_server <- function(id, currentConvertedPathReactive, selectedIdsReactive, sessionStructureReactive) {
  moduleServer(id, function(input, output, session) {
    # When a new path is select, display new path content
    observeEvent(currentConvertedPathReactive(), {
      folder_path <- currentConvertedPathReactive() # Read current bidsroot path
      folder_overview <- listBidsFolders(folder_path) # Read out info

      # Print for check
      cat("Listed BIDS folders:\n")
      print(folder_overview$bidsSubjFolders)
      bidsSubjOverview <- folderStructure_toDF(folder_overview$bidsSubjFolders)
      output$folderTable <- renderDT({
        datatable(bidsSubjOverview, options = list(pageLength = 20, scrollX = TRUE))
      })
    })

  observeEvent(selectedIdsReactive(), {
    selected_ids <- selectedIdsReactive()
    cat("Selected IDs folderCheck display:\n")
    print(selected_ids)
  })

  observeEvent(sessionStructureReactive(), {
    session_structure <- sessionStructureReactive()
    cat("Selected IDs session structure display:\n")
    print(session_structure)
  })
  })
}
