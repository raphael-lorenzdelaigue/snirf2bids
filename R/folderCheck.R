library(shiny)
library(DT)
library(dplyr)
library(stringr)

folderCheck_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    titlePanel("Folder Check"),
    # DTOutput(ns("folderTable"))
  )
}

folderCheck_server <- function(id, currentConvertedPathReactive, selectedIdsReactive, sessionStructureReactive) {
  moduleServer(id, function(input, output, session) {
    # OLD: When a new path is select, display new path content
    observeEvent(currentConvertedPathReactive(), {
      cat("currentConvertedPathReactive changed!\n")
      folder_path <- currentConvertedPathReactive() # Read current bidsroot path
      folder_overview <- listBidsFolders(folder_path) # Read out info

      # Print for check
      cat("Listed BIDS subject folders:\n")
      print(folder_overview$bidsSubjFolders)
      bidsSubjOverview <- folderStructure_toDF(folder_overview$bidsSubjFolders)
      output$folderTable <- renderDT({
        datatable(bidsSubjOverview, options = list(pageLength = 20, scrollX = TRUE))
      })
    })

    # NEW: if either new ID's OR BIDS folder structure OR experimental design are specified
    observeEvent({
      list(currentConvertedPathReactive(), selectedIdsReactive(), sessionStructureReactive())
    }, {
      # Read BIDS subject folders
      folder_path <- currentConvertedPathReactive()
      req(folder_path)
      folder_overview <- listBidsFolders(folder_path)
      subj_folders <- folder_overview$bidsSubjFolders

      # Read IDs
      selected_ids <- selectedIdsReactive()

      # Read session structure
      session_structure <- sessionStructureReactive()

      # Display the results of my check
      output$folderCheckOverview <- renderDT({
      snirf2bids_folderOverview(selected_ids, subj_folders)
    })
    })

  # CHECKS
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
