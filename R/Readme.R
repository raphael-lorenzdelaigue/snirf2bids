#file_path <- system.file("extdata/Readme_instructions.md", package = "SNIRF2BIDS")
#instructions <- cat(readLines("extdata/Readme_instructions.md"), sep="\n")
#instructions <- paste(instructions, collapse = "\n")

#' Helper function to open readme ui
#' @param id takes app id
#' @export
Readme_ui <- function(id) {
  ns <- NS(id)
  page_fillable(
    card(
      style = "background-color: #f8f9fa;",
      div(
        style = "font-size: 1.05rem;",
        strong("Instruction:"),
        br(),
        "You can now create the README file for your dataset. The GUI provides guidance based on the BIDS specification to help you include the recommended information.",
      )
    ),
    card(
      full_screen = TRUE,
      card_header("Readme Editor"),
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

#' Readme Shiny Module Server
#'
#' @param id Character. Shiny module namespace ID.
#' @param converted_root Reactive. The path to the folder where the BIDS dataset will be saved.
#' @export
Readme_server <- function(id, converted_root) {
  instructions <- readLines("extdata/Readme_instructions.md")
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_Readme, {
      req(converted_root())
      save_path <- file.path(converted_root(), "README.md")
      writeLines(input$ReadmeEditor, save_path)
      showNotification("Saved as README.md", type = "message")
      })
  })
}
