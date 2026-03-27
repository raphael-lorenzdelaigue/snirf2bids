
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
        "Please now specify how the files are named in the input folder.",
      )
    ),
    card(datamods::edit_data_ui(ns("mapping"))),
    card(actionButton(ns("save_csv"), "Save updated CSV"))
  )
}

#' Helper function for task mapping server
#' @param id takes app id
#' @param dataset_name_reactive takes dataset name
#' @export
taskMapping_server <- function(id, dataset_name_reactive) {
  moduleServer(id, function(input, output, session) {

    # Reactive to hold loaded CSV
    loaded_data <- reactiveVal(NULL)

    #### Load experimental design based on current experiment name ####
    # Display error message if not working

    observe({
      req(dataset_name_reactive())
      file_path <- file.path(here(), "R", "experiments", paste0(dataset_name_reactive(), "_tasks.csv"))

      if (file.exists(file_path)) {
        df <- read.csv(file_path, stringsAsFactors = FALSE)
        df$name <- "" # Add new column for name
        df$session <- sprintf("%02d", as.numeric(stringr::str_extract(df$session, "\\d+"))) # Extract and format session number in accordance with BIDS
        loaded_data(df)
      }
      else {
        showNotification(
          "The experimental design has not been created yet. Please go back to the previous step.",
          type = "error", duration = 5
        )
        return()  # stop further processing
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
      save_path <- file.path("experiments", paste0(dataset_name_reactive(), "_tasks_mapped.csv"))
      if (!dir.exists(dirname(save_path))) dir.create(dirname(save_path), recursive = TRUE)
      write.csv(mapping(), save_path, row.names = FALSE)
      showNotification(paste("Saved to", save_path), type = "message")
    })

    return(list(tasks = mapping))
  })
}
