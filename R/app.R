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
                 tabPanel("Select Input Folder",
                            shinyDirButton("select_InputDirectory", "Select input folder (original recordings)", "Please select input folder"), # Button for folder browser dialog
                            verbatimTextOutput("convertedPath")),
                 tabPanel("Select Output Folder",
                            shinyDirButton("select_OutputDirectory", "Select output folder (BIDS-formatted recordings)", "Please select output folder"), # Button for folder browser dialog
                            verbatimTextOutput("convertedPath")),
                 tabPanel("REQUIRED: Create dataset_description.json", datasetDescription_ui("page1")),
                 tabPanel("REQUIRED: Create Readme.md", Readme_ui("page2")),
                 tabPanel("REQUIRED: Specify experimental design", experimentalDesign_ui("page4")),
                 tabPanel("File Viewer", fileViewer_ui("page5")),
                 tabPanel("Folder check", folderCheck_ui("page6")),
                 tabPanel("EXTRA: Read participant information from existing folder structure)", participantSelection_ui("page3"))
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

    # Optional: show the chosen path
    output$convertedPath <- renderText({
      req(currentConvertedPath())
      paste("Selected path:", currentConvertedPath())
    })

  # Call modules, create necessary input and output variables
  datasetDescription_server("page1")
  Readme_server("page2")
  participant_selection <- participantSelection_server("page3", currentConvertedPath) # selected id's for folder creation
  selectedIds <- participant_selection$selected_ids
  experimental_design <- experimentalDesign_server("page4", selectedIds, currentConvertedPath)
  sessionStructure <- experimental_design$session_structure
  fileViewer_server("page5", currentConvertedPath)
  folderCheck_server("page6", currentConvertedPath, selectedIds, sessionStructure)
}

shinyApp(ui, server)
