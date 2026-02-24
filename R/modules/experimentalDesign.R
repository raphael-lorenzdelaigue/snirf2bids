library(stringr)
library(purrr)
#### EXPERIMENTAL DESIGN ####
experimentalDesign_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    # Specify experimental design
    card(
      style = "background-color: #f8f9fa;",
      div(
        style = "font-size: 1.05rem;",
        strong("Instruction:"),
        br(),
        "Please now specify the study design of your experiment. A session is generally defined by a day on which data – whether NIRS or not – has been recorded for a specific participant. You are free, however, to declare two sessions which took place on the same day as separate, if that corresponds better to the specific study design (for example, if a recording takes place in the morning, the participant then sleeps and then another recording takes place in the afternoon).",
      )
    ),
    card(
      card_header("How many sessions take place in your experiment?"),
      numericInput(ns("total_sessions"), label = "Number of sessions: ", value = 1)
    ),
    # Specify sessions with NIRS measurements
    card(
      card_header("Which of this sessions contains a NIRS measurement?"),
      checkboxGroupInput(
        ns("nirs_sessions"),
        label = "Please select the sessions containing a NIRS measurement: ",
        choices = NULL,
        selected = NULL)),
    # Name the tasks for each of this sessions
    # The uiOutput is being generated dynamically depending on the selected NIRS sessions
    # (in output$nirs_task_inputs)
    card(
      card_header("You can now name the tasks taking place in each session. These names will serve as the filenames"),
      uiOutput(ns("nirs_task_inputs"))
    ),
    card(
      actionButton(ns("createParticipantFolders"), "Create Folder Structure")
    )
  )
}



# Define server logic required to draw a histogram ----
experimentalDesign_server <- function(id, selectedIdsReactive, currentConvertedPathReactive) {
  moduleServer(id, function(input, output, session) {
    # Update number of choices for NIRS sessions
    # ... if the value of input$total_sessions changes
    observeEvent(input$total_sessions, {
      # Create names for each session
      nirs_sessions_choices <- paste0("Session ", seq_len(input$total_sessions))

      # Update the nirs_sessions input
      updateCheckboxGroupInput(session, "nirs_sessions",
                               choices = nirs_sessions_choices,
                               selected = nirs_sessions_choices)  # Optional: select first by default
    })

    # Creates varying number of text inputs depending on the number of NIRS sessions
    # ! currently this creates a dynamic number of variables "nirsTasks_session"
    output$nirs_task_inputs <- renderUI({
      req(input$nirs_sessions)

      # Vector of strings of type "Session 1", "Session 4", etc.
      selected_sessions <- input$nirs_sessions

      lapply(selected_sessions, function(session_label) {
        textInput(
          inputId = session$ns(paste0("nirsTasks_", session_label)),  # Use full label
          label = paste(session_label, ":"),
          value = ""
        )
      })
    })

    # Create folder structure upon pressing the button
    observeEvent(input$createParticipantFolders, {
      cat("Button clicked: createParticipantFolders\n")
      cat("Calling path\n")
      bids_motherFolder <- currentConvertedPathReactive()
      cat("Path loaded\n")
      cat("Calling ids\n")
      ids <- selectedIdsReactive()
      cat("ids content:", paste(ids, collapse = ", "), "\n")
      # Filter out empty and NA entries
      valid_ids <- ids[nzchar(ids) & !is.na(ids)]

      total_sessions <- input$total_sessions
      nirs_sessions <- input$nirs_sessions

      # Check if folder has been selected in first step
      if (is.null(bids_motherFolder) || !dir.exists(bids_motherFolder)) {
        showNotification("Please select an output folder first", type = "error")
        return()
      }

      print(paste("Currently selected IDs:", valid_ids))  # Debug print to R console
      if (is.null(valid_ids)) {
        showNotification("No participants have been specified. Folder structure will be empty", type = "error")
        return()
      }
      cat("Nulls checked\n")

      walk(valid_ids, function(id) {
        participant_folder <- file.path(bids_motherFolder, paste0("sub-", id))
        dir.create(participant_folder, recursive = TRUE, showWarnings = FALSE)
        cat("Created", participant_folder, "\n")
        walk(seq_len(total_sessions), function(session_num) {
          session_label <- paste0("Session ", session_num)
          session_folder <- file.path(participant_folder, sprintf("ses-%02d", session_num))
          dir.create(session_folder, recursive = TRUE, showWarnings = FALSE)
          cat("Created", session_folder, "\n")
          if (session_label %in% nirs_sessions) {
            dir.create(file.path(session_folder, "nirs"), showWarnings = FALSE)
            cat("Created", file.path(session_folder, "nirs"), "\n")
            }
          })
        })
      showNotification(paste("Folders created sucessfully", type = "message"))
    })

    # Read session structure and return it
    session_structure <- reactive({
      req(input$total_sessions)
      req(input$nirs_sessions)

      nirs_numbers <- str_extract(input$nirs_sessions, "\\d+")
      nirs_folders <- paste0("ses-", str_pad(nirs_numbers, width = 2, side = "left", pad = "0"))

      all_folders <- paste0("ses-", str_pad(seq_len(input$total_sessions), width = 2, pad = "0"))
      list(
        all_folders = all_folders,
        nirs_folders = nirs_folders
      )
    })
    return(list(
      session_structure = session_structure
    ))
  })
}
