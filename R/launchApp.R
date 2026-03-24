#' start snirf2bids GUI
#'
#' @return A Shiny app object (runs interactively).
#' @export
#'
#' @importFrom shiny runApp
#' @importFrom fs path_package
start_snirf2bids <- function(x, ...)
{
  shiny::runApp(appDir = system.file("shiny","myapp", package = "NIRS2BIDS"),
                ...)
}
