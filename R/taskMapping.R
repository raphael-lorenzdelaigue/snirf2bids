library(DT)

#' Helper function for task mapping
#' @param id takes app id
#' @export
taskMapping_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    card(
      style = "background-color: #f8f9fa;",
      div(
        style = "font-size: 1.05rem;",
        strong("Instruction:"),
        br(),
        "Please map each experiment entry from the \"*_description.json\" files in your input folder to the corresponding session and task in your experimental design.",
      )
    ),
    card(
      textInput(
        ns("dataset_name"),
        label = "Dataset name:"
      )),
    card(datamods::edit_data_ui(ns("mapping"))),
    card(actionButton(ns("save_csv"), "Confirm task mapping"))
  )
}

#' Helper function for task mapping server
#' @param id takes app id
#' @param routine either "json" or "folders"
#' @export
taskMapping_server <- function(id, converted_root, routine) {
  moduleServer(id, function(input, output, session) {

    # Reactive to hold loaded CSV
    loaded_data <- reactiveVal(NULL)

    # Dataset name reactive
    dataset_name_for_conversion <- reactive({
      req(input$dataset_name)  # your new textInput in taskMapping_ui
      input$dataset_name
    })

    #### Load experimental design based on current experiment name ####

    observe({
      req(input$dataset_name)
      req(converted_root())
      req(routine())  # Ensure the routine reactive is available

      # Only run if "json" routine is selected
      if (routine() != "json") return()

      file_path <- file.path(
        converted_root(),
        "experiments",
        paste0(input$dataset_name, "_tasks.csv")
      )

      message("Trying to load: ", file_path)

      if (file.exists(file_path)) {
        df <- read.csv(file_path, stringsAsFactors = FALSE)
        df$name <- "" # Add new column for name
        df$session <- sprintf("%02d", as.numeric(stringr::str_extract(df$session, "\\d+"))) # Extract and format session number in accordance with BIDS
        loaded_data(df)
      }
    })

    #### Open datamods editing window ####
    mapping <- datamods::edit_data_server(
      id = "mapping",
      data = reactive({
        req(loaded_data())
        loaded_data()
      }),
      download_csv = FALSE,
      download_excel = FALSE,
      add = FALSE
    )

    #### Save button ####
    observeEvent(input$save_csv, {
      req(mapping())
      req(converted_root())
      save_path <- file.path(
        converted_root(),
        "experiments",
        paste0(input$dataset_name, "_tasks_mapped.csv")
      )
      if (!dir.exists(dirname(save_path))) dir.create(dirname(save_path), recursive = TRUE)
      write.csv(mapping(), save_path, row.names = FALSE)
      showNotification(paste("Saved to", save_path), type = "message")
    })

    return(list(
      tasks = mapping,
      dataset_name_for_conversion = dataset_name_for_conversion))
  })
}
