library(DT)

taskMapping_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    card(fileInput(ns("csv_file"), "Load NIRS tasks CSV")),
    card(datamods::edit_data_ui(ns("mapping"))),
    card(actionButton(ns("save_csv"), "Save updated CSV"))
  )
}

taskMapping_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # Reactive to hold loaded CSV
    loaded_data <- reactiveVal(NULL)

    observeEvent(input$csv_file, {
      str(input$csv_file)
      req(input$csv_file)
      df <- read.csv(input$csv_file$datapath, stringsAsFactors = FALSE)
      loaded_data(df)
    })
    print(loaded_data)

    mapping <- datamods::edit_data_server(
      id = "mapping",
      data = reactive({
        req(loaded_data())
        loaded_data()
      })
    )

    # Save button
    observeEvent(input$save_csv, {
      req(mapping())
      save_path <- file.path("experiments", "nirs_tasks_updated.csv")
      if (!dir.exists(dirname(save_path))) dir.create(dirname(save_path), recursive = TRUE)
      write.csv(mapping(), save_path, row.names = FALSE)
      showNotification(paste("Saved to", save_path), type = "message")
    })

    return(list(tasks = mapping))
  })
}
