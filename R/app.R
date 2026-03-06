library(shiny)
library(bslib)
library(here)
library(dplyr)
library(tidyr)
library(stringr)

# Provide internally:
# BIDS Version (in datasetDescription.R)
# Load your modules
source("modules/experimentalDesign.R")
source("modules/participantSelection.R")
source("modules/datasetDescription.R")
source("modules/Readme.R")
source("modules/fileViewer.R")
source("modules/folderCheck.R")

source("generate_file_overview.R")
source("bidsroot_overview.R")
source("folderCheck_functions.R")
source("functions/convert.R")

ui <- navbarPage("NIRS2BIDS Converter",
                 tabsetPanel(
                   # In order to keep the destination path accessible to all pages of the app, I need to define corresponding UI and server in the main page
                 tabPanel("1 - Select Input Folder",
                            shinyDirButton("select_InputDirectory", "Select input folder (original recordings)", "Please select input folder"), # Button for folder browser dialog
                            shinyDirButton("select_OutputDirectory", "Select output folder (BIDS-formatted recordings)", "Please select output folder")), # Button for folder browser dialog
                 tabPanel("2 - Provide list of participant IDs", participantSelection_ui("page1")),
                 tabPanel("3 - Specify experimental design", experimentalDesign_ui("page2")),
                 tabPanel("4 - Modality agnostic files: Create dataset_description.json", datasetDescription_ui("page3")),
                 tabPanel("5 - Modality agnostic files: Create Readme.md", Readme_ui("page4")),
                 tabPanel("6 - Convert",actionButton("convert_button", "Convert to BIDS"))

))


server <- function(input, output, session) {
  # Shared reactive path across modules
  currentSourcePath <- reactiveVal(NULL)
  currentConvertedPath <- reactiveVal(NULL)
  # only returns ready-mounted, local drives -> misses Google Drive File Stream or Network-mapped drives (U:, X: etc.). Could be worked around by explicitly defining drive letters
  volumes <- shinyFiles::getVolumes()
  # Let user pick a directory
  shinyDirChoose(input, "select_InputDirectory", roots = volumes(), session = session)
  shinyDirChoose(input, "select_OutputDirectory", roots = volumes(), session = session)

  observeEvent(input$select_InputDirectory, {
    path <- parseDirPath(roots = volumes(), input$select_InputDirectory) # Takes raw result from input$select_OutputDirectory and converts into proper file system path
    if (length(path) > 0 && nzchar(path)) {
      currentSourcePath(path)
      showNotification(paste("Source folder set to:", path), type = "message")
    }
  })

  # Extract file path from selection and store reactive value (currentConvertedPath)
  observeEvent(input$select_OutputDirectory, {
    path <- parseDirPath(roots = volumes(), input$select_OutputDirectory) # Takes raw result from input$select_OutputDirectory and converts into proper file system path
    if (length(path) > 0 && nzchar(path)) {
      currentConvertedPath(path)
      showNotification(paste("Target folder set to:", path), type = "message")
    }
  })

  observeEvent(input$convert_button, {
    req(currentSourcePath(), currentConvertedPath())
    showNotification("Starting conversion...", type = "message")
    tryCatch({
      convert_root(
        source_root = currentSourcePath(),
        converted_root = currentConvertedPath(),
        experiment_description = here("R","experiments", "KODUN.csv")  # or reactive, if you like
      )
      showNotification("✅ Conversion complete!", type = "message")
    },
    error = function(e) {
      showNotification(paste("❌ Conversion failed:", e$message), type = "error")
    })
  })


  # Call modules, create necessary input and output variables
  participant_selection <- participantSelection_server("page1", currentConvertedPath) # selected id's for folder creation

  # Save csv from experimental Design
  experimental_design <- experimentalDesign_server("page2", selectedIds, currentConvertedPath)

  datasetDescription_server("page3", converted_root = currentConvertedPath)
  Readme_server("page4", converted_root = currentConvertedPath)
  selectedIds <- participant_selection$selected_ids
}

shinyApp(ui, server)
