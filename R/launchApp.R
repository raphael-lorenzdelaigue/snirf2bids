#' start snirf2bids GUI
#'
#' @return A Shiny app object (runs interactively).
#' @export
#'
#' @importFrom shiny runApp
#' @importFrom fs path_package
start_snirf2bids <- function() {
  app_dir <- system.file("shiny/myapp", package = "SNIRF2BIDS")
  print(app_dir)
  if (app_dir == "") {
    stop("Could not find Shiny app. Is the package installed correctly?")
  }

  shiny::runApp(app_dir, display.mode = "normal")
}
