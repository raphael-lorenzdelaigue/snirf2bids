instructions <- readLines("Readme_instructions.md")
instructions <- paste(instructions, collapse = "\n")

Readme_ui <- function(id) {
  ns <- NS(id)
  page_fillable(
    card(
      full_screen = TRUE,
      card_header("Edit Markdown"),
      div(
        style = "height: 100%; flex-grow: 1; display: flex; flex-direction: column;", # Concerns div element
        textAreaInput(
          ns("ReadmeEditor"),
          label = NULL,
          value = instructions,
          width = "100%",
          height = "100%",  # THIS DOES NOT WORK by itself, so:
          resize = "none"
        ) %>%
          tagAppendAttributes(
            style = "flex-grow: 1; height: 100%; font-family: monospace; font-size: 14px;" #  Concerns textAreaInput
          )
        # optional: add save button here
      ),
      style = "height: 100vh; display: flex; flex-direction: column;" # Concerns the card
    ),
    card(
      actionButton(ns("save_Readme"), "Save Readme")
    )
  )
}

Readme_server <- function(id, converted_root) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_Readme, {
      req(converted_root())
      save_path <- file.path(converted_root(), "README.md")
      writeLines(input$ReadmeEditor, save_path)
      showNotification("Saved as README.md", type = "message")
      })
  })
}
