library(shiny)
library(bslib)

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

ui <- navbarPage("NIRS2BIDS Converter",
                 tabsetPanel(
                   # In order to keep the destination path accessible to all pages of the app, I need to define corresponding UI and server in the main page
                 tabPanel("Select Output Folder",
                            shinyDirButton("select_directory", "Choose folder for 'converted'", "Please select a folder"), # Button for folder browser dialog
                            verbatimTextOutput("convertedPath")),
                 tabPanel("REQUIRED: Create dataset_description.json", datasetDescription_ui("page1")),
                 tabPanel("REQUIRED: Create Readme.md", Readme_ui("page2")),
                 tabPanel("REQUIRED: Create Folder Structure (Step 1: Participant Information)", participantSelection_ui("page3")),
                 tabPanel("REQUIRED: Create Folder Structure (Step 2: Experimental Design)", experimentalDesign_ui("page4")),
                 tabPanel("File Viewer", fileViewer_ui("page5")),
                 tabPanel("Folder check", folderCheck_ui("page6"))
))


server <- function(input, output, session) {
  # Shared reactive path across modules
  currentConvertedPath <- reactiveVal(NULL)

  # only returns ready-mounted, local drives -> misses Google Drive File Stream or Network-mapped drives (U:, X: etc.). Could be worked around by explicitly defining drive letters
  volumes <- shinyFiles::getVolumes()
  # Let user pick a directory
  shinyDirChoose(input, "select_directory", roots = volumes(), session = session)

  # Extract file path from selection and store reactive value (currentConvertedPath)
  observeEvent(input$select_directory, {
    path <- parseDirPath(roots = volumes(), input$select_directory) # Takes raw result from input$select_directory and converts into proper file system path
    if (length(path) > 0 && nzchar(path)) {
      currentConvertedPath(path)
      showNotification(paste("Target folder set to:", path), type = "message")
    }
  })

    # Optional: show the chosen path
    output$convertedPath <- renderText({
      req(currentConvertedPath())
      paste("Selected path:", currentConvertedPath())
    })

  # Call modules
  datasetDescription_server("page1")
  Readme_server("page2")
  participant_selection <- participantSelection_server("page3", currentConvertedPath) # selected id's for folder creation
  selectedIds <- participant_selection$selected_ids
  experimentalDesign_server("page4", selectedIds, currentConvertedPath)
  fileViewer_server("page5", currentConvertedPath)
  folderCheck_server("page6", currentConvertedPath)
}

shinyApp(ui, server)
