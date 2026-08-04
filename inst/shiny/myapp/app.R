# auto-install needed packages
my_packages <- c("reticulate", "shiny", "shinyFiles", "here", "tidyr", "bslib", "DT", "stringr", "purrr", "dplyr", "datamods", "shinyjs", "magrittr", "jsonlite")  # Add your packages here

new_packages <- my_packages[!(my_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

# Load R libraries
library(reticulate)
library(shiny)
library(shinyFiles)
library(here)
library(tidyr)
library(bslib)
library(DT)
library(stringr)
library(purrr)
library(dplyr)
library(datamods)
library(shinyjs)
library(magrittr)
library(jsonlite)

library(rhdf5)

# Activate MNE environment
env = activate_mne_env()

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
                 tabPanel("Select input and output folder - choose conversion routine",
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
                              "Both folders must be located on a local hard drive as network drives might not be detected.",
                              br(),
                              br(),
                              "Please also specify whether subject IDs, session numbers and task names should be inferred.",
                              br(),
                              "(a) from the input folder structure.",
                              br(),
                              "(b) from accompanying \"*_description.json\" files.",
                              br(),
                              "If (a), please make sure that all your recordings are stored in a hierarchical folder structure following the scheme subject-id > session-nr > task-name"
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
                            shinyDirButton("select_OutputDirectory", "Select output folder (BIDS-formatted recordings)", "Please select output folder"),
                          card(
                            style = "background-color: #eef7fb; padding: 12px",
                            div(
                              style = "font-size: 1.05rem;",
                              strong("About the input and output folder"),
                              br(),
                              "The ",
                              tags$code("input folder"),
                              " does not need to be formatted according to BIDS standards. The ",
                              tags$code("output folder"),
                              "will be structured according to BIDS nomenclature at the end of the conversion process, if it is successful. BIDS follows a specific filesystem structure, where data is placed in a separate subdirectory for each study participant. This subfolder is named “sub-<label>”, where <label> stands for the unique identifier of a participant. If data was acquired across multiple sessions, a further subdirectory of type “ses-<label>” is created for each session. In that case, a unique <label> is assigned to each measurement session. After succesful conversion, the NIRS recording data will be saved within each of these subfolders. Besides the SNIRF file containing the recorded data, a range of metadata files will be created. These contain various informations such as a description of NIRS channels, task-related events or further technical aspects of the recording in the sidecar JSON. Only some of these files are required to comply with BIDS specifications. Others are either recommended or optional.",
                              br(),
                              icon("book"),
                              " ",
                              tags$a(
                                href = "https://bids-specification.readthedocs.io/en/stable/common-principles.html#filesystem-structure",
                                "Further information on the BIDS filesystem structure: ",
                                target = "_blank",
                                style = "color:#0d6efd; text-decoration:underline; cursor:pointer;"
                              ),
                              br(),
                              icon("book"),
                              " ",
                              tags$a(
                                href = "https://bids-specification.readthedocs.io/en/stable/modality-specific-files/near-infrared-spectroscopy.html#nirs-recording-data",
                                "Further information on NIRS-specific files in the BIDS nomenclature: ",
                                target = "_blank",
                                style = "color:#0d6efd; text-decoration:underline; cursor:pointer;"
                              )), # Button for folder browser dialog
                 tabPanel("Create dataset_description.json", datasetDescription_ui("page1")),
                 tabPanel("Specify experimental design", value = "experimental_design", experimentalDesign_ui("page2")),
                 tabPanel("Task mapping", value = "task_mapping", taskMapping_ui("page3")),
                 tabPanel("Create Readme.md", Readme_ui("page4")),
                 tabPanel("Convert",
                          card(
                            style = "background-color: #f8f9fa;",
                            div(
                              style = "font-size: 1.05rem;",
                              strong("Instruction:"),
                              br(),
                              "You can now convert all detected SNIRF files from the input folder into BIDS format.",
                              br(),
                              "After that step has ended, you will find your recordings, alongside extracted metadata, in the BIDS-compliant subfolder structure (one folder per participant (\"sub-xxx\"), and then one subfolder per session within that folder (\"ses-xxx\")).",
                              br(),
                              "If retrieving metadata from the accompanying \"*_description.json\" files, SNIRF files that could not be mapped to your experimental structure will be placed in a separate folder called \"no_mapping\" with the session number \"999\"",
                            )
                          ),
                          actionButton("convert_button", "Convert to BIDS"),
                          card(
                            style = "background-color: #eef7fb; padding: 12px",
                            div(
                              style = "font-size: 1.05rem;",
                              strong("About conversion"),
                              br(),
                              "After conversion, your recordings and the extracted metadata will be organized in a BIDS-compliant folder structure. A separate subfolder will be created for each participant (",
                              tags$code("sub-<label>"),
                              ") and measurement session (",
                              tags$code("ses-<label>"),
                              "). The task name will also be included in the filenames as ",
                              tags$code("task-<label>"),
                              ".",
                              br(), br(),
                              "We recommend validating the converted dataset using the ",
                              tags$code("BIDS Validator"),
                              ", which checks whether the dataset complies with the BIDS specification and reports any errors or warnings.",
                              br(), br(),
                              icon("book"),
                              " ",
                              tags$a(
                                href = "https://bids-standard.github.io/bids-validator/",
                                "BIDS Validator documentation",
                                target = "_blank",
                                style = "color:#0d6efd; text-decoration:underline; cursor:pointer;"
                              )
                            )
                          ))
))))


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
  dataset_desc <- datasetDescription_server(
    "page1",
    converted_root = currentConvertedPath
    )

  experimental_design <- experimentalDesign_server(
    "page2",
    converted_root = currentConvertedPath,
    dataset_name_reactive = dataset_desc$dataset_name
    )

  task_mapping <- taskMapping_server(
    "page3",
    converted_root = currentConvertedPath,
    routine = reactive(input$mapping_source)
    )

  Readme_server(
    "page4",
    converted_root = currentConvertedPath
    )

  #### Convert button (at the end) ####
  observeEvent(input$convert_button, {
    req(currentSourcePath(), currentConvertedPath())
    showNotification("Conversion is running...", type = "message")

    exp_desc <- if (input$mapping_source == "json") {
      req(task_mapping$dataset_name_for_conversion())
      file.path(
        currentConvertedPath(),       # root converted folder
        "experiments",                # experiments subfolder
        paste0(task_mapping$dataset_name_for_conversion(), "_tasks_mapped.csv")
      )
    } else {
      NULL
    }

    tryCatch({
      convert_root(
        source_root = currentSourcePath(),
        converted_root = currentConvertedPath(),
        experiment_description = exp_desc,
        routine = input$mapping_source,
        py_env = env# or reactive, if you like
      )

      # Remove temporary experiments folder after successful conversion
      exp_folder <- file.path(currentConvertedPath(), "experiments")
      if (dir.exists(exp_folder)) {
        unlink(exp_folder, recursive = TRUE, force = TRUE)
      }

      # Remove Readme file automatically generated by MNE BIDS
      readme_path <- file.path(currentConvertedPath(), "README")

      if (file.exists(readme_path)) {
        file.remove(readme_path)
      }

      showNotification("✅ Conversion complete!", type = "message")
    },
    error = function(e) {
      showNotification(paste("❌ Conversion failed:", e$message), type = "error")
    })
  })
}

shinyApp(ui, server)
