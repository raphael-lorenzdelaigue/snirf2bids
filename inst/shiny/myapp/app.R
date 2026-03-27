# auto-install needed packages
my_packages <- c("reticulate", "shiny", "here", "tidyr", "bslib", "DT", "stringr", "purrr", "dplyr", "BiocManager", "datamods", "shinyjs", "magrittr")  # Add your packages here

new_packages <- my_packages[!(my_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

if (!require("rhdf5"))
  BiocManager::install("rhdf5", configure.args="--no-staged-install")

library(reticulate)
library(rhdf5)
library(jsonlite)
library(here)
library(shiny)
library(shinyFiles)
library(bslib)
library(shinyjs)
library(magrittr)

# Provide internally:
# BIDS Version (in datasetDescription.R)
# Load your modules
#source("R/modules/experimentalDesign.R")
#source("R/modules/datasetDescription.R")
#source("R/modules/taskMapping.R")
#source("R/modules/Readme.R")
#source("R/modules/folderCheck.R")

#source("R/functions/convert.R")

ui <- navbarPage("SNIRF2BIDS Converter",
                 tabsetPanel(
                 id = "current_tab",
                 shinyjs::useShinyjs(),
                   # In order to keep the destination path accessible to all pages of the app, I need to define corresponding UI and server in the main page
                 tabPanel("Select Input Folder",
                          card(
                            style = "background-color: #f8f9fa;",
                            div(
                              style = "font-size: 1.05rem;",
                              strong("Instruction:"),
                              br(),
                              "Please choose:",
                              br(),
                              "(1) the input folder containing the original recordings you want to convert to BIDS (must be SNIRF files).",
                              br(),
                              "(2) the output folder where you want to save the BIDS-formatted files.",
                              br(),
                              "Both folders must be located on a local hard drive as network drives might not be detected."
                            )
                          ),
                          card(radioButtons(
                            inputId = "mapping_source",
                            label = "Where is the experiment information stored?",
                            choices = c(
                              "Folder structure (subject/session subfolders)" = "folders",
                              "Metadata file (recording-name_description.json)" = "json"
                            ),
                            width = "100%"   # makes the radio buttons container full-width
                          )),
                            shinyDirButton("select_InputDirectory", "Select input folder (original recordings)", "Please select input folder"), # Button for folder browser dialog
                            shinyDirButton("select_OutputDirectory", "Select output folder (BIDS-formatted recordings)", "Please select output folder")), # Button for folder browser dialog
                 tabPanel("Modality agnostic files: Create dataset_description.json", datasetDescription_ui("page1")),
                 tabPanel("Specify experimental design", value = "experimental_design", experimentalDesign_ui("page2")),
                 tabPanel("Task mapping", value = "task_mapping", taskMapping_ui("page3")),
                 tabPanel("Modality agnostic files: Create Readme.md", Readme_ui("page4")),
                 tabPanel("Convert",
                          card(
                            style = "background-color: #f8f9fa;",
                            div(
                              style = "font-size: 1.05rem;",
                              strong("Instruction:"),
                              br(),
                              "You can now convert all detected SNIRF files from the input folder into BIDS format.",
                              br(),
                              "After that step has ended, you will find your recordings, alongside extracted metadata, in the BIDS-compliant subfolder structure (one folder per participant (\"sub-xxx\"), and then one subfolder per session within that folder (\"ses-xxx\").",
                              br(),
                              "SNIRF files that could not be mapped to your experimental structure will be placed in a separate folder called \"no_mapping\" with the session number \"999\"",
                            )
                          ),
                          actionButton("convert_button", "Convert to BIDS"))
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

  # Hide/show tabs for specifying experimental design if info is encoded in folder structure
  observe({
    if (input$mapping_source == "folders") {
      shinyjs::hide(selector = "a[data-value='experimental_design']")
      shinyjs::hide(selector = "a[data-value='task_mapping']")

      # optional: switch to a visible tab so user doesn’t get stuck
      updateTabsetPanel(session, "current_tab", selected = "page1")

    } else {
      shinyjs::show(selector = "a[data-value='experimental_design']")
      shinyjs::show(selector = "a[data-value='task_mapping']")
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

  #### Call modules, create necessary input and output variables ####
  dataset_desc <- datasetDescription_server("page1", converted_root = currentConvertedPath)
  experimental_design <- experimentalDesign_server("page2", currentConvertedPath, dataset_name_reactive = dataset_desc$dataset_name)
  task_mapping <- taskMapping_server("page3",dataset_name_reactive = dataset_desc$dataset_name)
  Readme_server("page4", converted_root = currentConvertedPath)

  #### Convert button (at the end) ####
  observeEvent(input$convert_button, {
    req(currentSourcePath(), currentConvertedPath())
    showNotification("Starting conversion...", type = "message")

    exp_desc <- if (input$mapping_source == "json") {
      here("R","experiments", paste0(dataset_desc$dataset_name(), "_tasks_mapped.csv"))
    } else {
      NULL
    }

    tryCatch({
      activate_mne_env()

      convert_root(
        source_root = currentSourcePath(),
        converted_root = currentConvertedPath(),
        experiment_description = exp_desc,
        routine = input$mapping_source# or reactive, if you like
      )
      showNotification("✅ Conversion complete!", type = "message")
    },
    error = function(e) {
      showNotification(paste("❌ Conversion failed:", e$message), type = "error")
    })
  })
}

shinyApp(ui, server)
