library(shiny)
library(shinyFiles)
library(bslib)
library(readr)
library(readxl)
library(tools)
library(DT)

#### MULTIPAGE STUFF ####
fileEditor_ui <- fluidPage(
  shinyFilesButton("file", "Select a file", "Please select a file", multiple = FALSE),
  verbatimTextOutput("filepath")
)

# Define UI for app that draws a histogram ----
ui <- page_navbar(
  title = "NIRS2BIDS Converter",
  sidebar = sidebar("Data Folder", position = "right"),
  nav_panel("Choose data structure"),
  nav_panel("File Editor")
)

#### EXPERIMENTAL DESIGN ####
experimentalDesign_ui <- page_sidebar(
  title = "Experimental design",
  sidebar = sidebar("Data Folder", position = "right"),
  # Specify experimental design
  card(
    card_header("How many sessions take place in your experiment?"),
    numericInput("total_sessions", label = "Number of sessions: ", value = 1)
    ),
  # Specify sessions with NIRS measurements
  card(
    card_header("Which of this sessions contains a NIRS measurement?"),
    checkboxGroupInput(
      "nirs_sessions",
      label = "Please select the sessions containing a NIRS measurement: ",
      choices = NULL,
      selected = NULL)),
  # Name the tasks for each of this sessions
  # The uiOutput is being generated dynamically depending on the selected NIRS sessions
  # (in output$nirs_task_inputs)
    card(
      card_header("You can now name the tasks taking place in each session. These names will serve as the filenames"),
      uiOutput("nirs_task_inputs")
    ),
  )

# Define server logic required to draw a histogram ----
experimentalDesign_server <- function(input, output, session) {
  # Update number of choices for NIRS sessions
  # ... if the value of input$total_sessions changes
  observeEvent(input$total_sessions, {
    # Create names for each session
    nirs_sessions_choices <- paste0("Session ", seq_len(input$total_sessions))

    # Update the nirs_sessions input
    updateCheckboxGroupInput(session, "nirs_sessions",
                             choices = nirs_sessions_choices,
                             selected = NULL)  # Optional: select first by default
  })

  # Creates varying number of text inputs depending on the number of NIRS sessions
  # ! currently this creates a dynamic number of variables "nirsTasks_session"
  output$nirs_task_inputs <- renderUI({
    req(input$nirs_sessions)

    # Vector of strings of type "Session 1", "Session 4", etc.
    selected_sessions <- input$nirs_sessions

    lapply(selected_sessions, function(session) {
      textInput(
        inputId = paste0("nirsTasks_session", session),
        label = paste(session, ":"),
        value = ""
      )
    })
  })
}

#### PARTICIPANT INFORMATION ####
participantInfo_ui <- page_sidebar(
  sidebar = sidebar("Data Folder", position = "right"),
  # File browser to load required file
  card(
    card_header("Please select the file containing the participant information. Valid formats are .csv, .tsv, .xls and .xlsx"),
    fileInput("participant_overview", label = NULL)),
  # Data Table display
  card(
      card_header("Please select the column of the participant IDs"),
      dataTableOutput("participant_overview_ui")),
  card(
      card_header("Selected column data"),
      dataTableOutput("selected_column_data_ui")
))


participantInfo_server <- function(input, output, session) {
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

  output$participant_overview_ui <- DT::renderDT({
    DT::datatable(
      # Display the dataset
      participant_overview_table(),
      # ... and allow user to select a column, which DT allows to do directly
      selection = list(mode = "single", target = "column"),
      options = list(scrollX = TRUE)
    )})

  # **Display only the selected column as a new data table**
  output$selected_column_data_ui <- DT::renderDT({
    req(input$participant_overview_ui_columns_selected)
    idx <- input$participant_overview_ui_columns_selected
    df <- participant_overview_table()
    DT::datatable(data.frame(df[[idx]]), colnames = names(df)[idx])  # **Wrap vector as data.frame**
  })
}

shinyApp(ui = experimentalDesign_ui, server = experimentalDesign_server)
