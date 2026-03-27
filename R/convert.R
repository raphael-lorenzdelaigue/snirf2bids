#### SETUP ####
library(reticulate)
library(rhdf5)
library(jsonlite)
library(here)

vendor_hooks_path <- here("R", "functions", "vendor_hooks.R")

# Always normalize paths for Windows compatibility
vendor_hooks_path <- normalizePath(vendor_hooks_path, winslash = "/", mustWork = FALSE)

# old version (use local venv)
#reticulate::use_virtualenv(venv_path, required = TRUE)
# connect previously created python environment + packages

#' Activate MNE Python environment
#'
#' Sets up or activates the required conda environment for MNE.
#' @export
activate_mne_env <- function () {
  # Step 0: Ensure unattended install
  Sys.setenv(CONDA_ALWAYS_YES = "true")

  # Step 1: Ensure Miniconda exists
  if (reticulate::miniconda_path() == "" || !file.exists(reticulate::miniconda_path())) {
    message("Installing Miniconda...")
    reticulate::install_miniconda()

    # Accept ToS automatically
    #conda_bin <- file.path(reticulate::miniconda_path(), "condabin", "conda.bat")
    #for (ch in c("https://repo.anaconda.com/pkgs/main",
                 #"https://repo.anaconda.com/pkgs/r",
                 #"https://repo.anaconda.com/pkgs/msys2")) {
      #system2(conda_bin, c("tos", "accept", "--override-channels", "--channel", ch),
              #stdout = TRUE, stderr = TRUE, wait = TRUE)
    #}

  }

  # Step 2: Now it's safe to query conda
  conda_envs <- reticulate::conda_list()[["name"]]

  # Step 3: Create env if missing
  if (!"mne-env" %in% conda_envs) {
    message("Creating mne-env...")

    reticulate::conda_create("mne-env", packages = "python=3.10")

    reticulate::conda_install(
      "mne-env",
      packages = c("mne", "numpy", "scipy", "mne-bids", "matplotlib", "pandas"),
      channel = "conda-forge"
    )
  }

  # Step 4: Activate env
  reticulate::use_condaenv("mne-env", required = TRUE)

  # Step 5: Import Python modules
  mne <- reticulate::import("mne")
  mnebids <- reticulate::import("mne_bids")
  h5py <- reticulate::import("h5py")
  pathlib <- reticulate::import("pathlib")

  # Return objects (important!)
  list(
    mne = mne,
    mnebids = mnebids,
    h5py = h5py,
    pathlib = pathlib,
    BIDSPath = mnebids$BIDSPath,
    write_raw_bids = mnebids$write_raw_bids
  )
}

#### ACCESS THE PATH TO SAVE THE CONVERTED VALUES ####
make_output_folder <- function(file_path_reactive) {
  reactive({
    file_path <- file_path_reactive()
    if (is.null(file_path) || file_path == "") return(NULL)
    basename(dirname(file_path))
  })
}

#### CONVERT ROUTINE (ONE FILE) ####
# Function that reads a source SNIRF file, checks for manufacturer name

# If routine = "json", it checks for a description.json file in the same folder containing the SNIRF
# Reads subject ID and experiment description from there
# And then deducts the task name and session number based on task mapping

# If routine = "folder", it reads the subject ID, session number and task name from the folder structure

#' snirf2bids function for conversion
#'
#' @param source_snirf SNIRF to be converted
#' @param converted_root Output folder for converted SNIRFs
#' @param experiment_description Subject, session and task metadata - only for "json" routine
#' @param routine Switch between "json" and "folder"
#' @param py_env List. Python environment returned by activate_mne_env()
#' @export
snirf2bids <- function (source_snirf, converted_root, experiment_description = NULL, routine = c("json", "folders"), py_env) {
  routine <- match.arg(routine)
  if (routine == "json") {
    task_map <- read.csv(experiment_description, colClasses = c("session" = "character"))
    json_path <- check_description_json(source_snirf) # Use NIRx vendor hook
      # Read the JSON content
      json_content <- fromJSON(json_path)

      # Convert the JSON content to a data frame
      file_tags <- as.data.frame(t(unlist(json_content)), stringsAsFactors = FALSE)

      # Add the subfolder name as a column
      file_tags$subfolder <- basename(dirname(json_path))

      # IF the information inside description.json matches experiment description, create regular BIDS path with corresponding info
      if (any(task_map$name == file_tags$experiment)) {
        # Read task and session from the experiment overview
        file_tags$task <- task_map$task[task_map$name == file_tags$experiment]
        file_tags$session <- task_map$session[task_map$name == file_tags$experiment]

        bids_path <- py_env$BIDSPath(
          subject = file_tags$subject,
          session = file_tags$session,
          task = file_tags$task,
          root = converted_root
        )
      }

      # ELSE create BIDS path inside "no_mapping" folder with session "999"
      else {
        file_tags$task <- gsub("[-_/]", "", file_tags$experiment) # Remove BIDS non-conforming characters from the string
        file_tags$session <- "999"
        no_mapping_path <- file.path(converted_root, "no_mapping")
        dir.create(no_mapping_path, recursive = TRUE, showWarnings = FALSE)

        bids_path <- py_env$BIDSPath(
          subject = file_tags$subject,
          session = file_tags$session,
          task = file_tags$task,
          root = no_mapping_path
        )

      }
      # Load data with MNE and convert to BIDS format
      raw <- py_env$mne$io$read_raw_snirf(source_snirf, preload = FALSE)
      py_env$write_raw_bids(raw, bids_path, overwrite = TRUE)
  }

  # In "folders" routine, extract subject ID, session number and task name from folder structure
  else if (routine == "folders"){

    # Split path into components
    path_parts <- strsplit(normalizePath(source_snirf), "[/\\\\]")[[1]]

    if (length(path_parts) < 4) {
      stop("Path is too short to extract subject/session/task structure")
    }

    # Extract last elements relative to file
    task    <- path_parts[length(path_parts) - 1]
    session <- path_parts[length(path_parts) - 2]
    subject <- path_parts[length(path_parts) - 3]

    file_tags <- data.frame(
      subject = subject,
      session = session,
      task    = task
    )

    bids_path <- py_env$BIDSPath(
      subject = subject,
      session = session,
      task = task,
      root = converted_root
    )

    raw <- py_env$mne$io$read_raw_snirf(source_snirf, preload = FALSE)
    py_env$write_raw_bids(raw, bids_path, overwrite = TRUE)
  }
}

#### CONVERT ROUTINE (ONE FOLDER) ####
# Helper function that finds all .snirf files in a specific folder
get_snirf_files <- function(folder) {
  list.files(folder, pattern = "\\.snirf$", ignore.case = TRUE, full.names = TRUE)
}

# Runs SNIRF2BIDS with lapply on data directory
#' snirf2bids function for conversion
#'
#' @param source_root Input folder for raw SNIRFs
#' @param converted_root Output folder for converted SNIRFs
#' @param experiment_description Subject, session and task metadata - only for "json" routine
#' @param routine Switch between "json" and "folder"
#' @param py_env List. Python environment returned by activate_mne_env()
#' @export
convert_root <- function(source_root, converted_root, experiment_description = NULL,
                         routine = c("json", "folders"), py_env) {

  routine <- match.arg(routine)

  # Initialize an empty data frame to store the results
  file_overview <- data.frame(subfolder = character(), stringsAsFactors = FALSE)

  # Loop through folders...
  folders <- list.dirs(source_root, recursive = FALSE)
  for (folder in folders) {
    subfolders <- list.dirs(folder, recursive = TRUE)

    # And then recursively through subfolders
    for (subfolder in subfolders) {

    # Check if a SNIRF file is found
      snirfs <- get_snirf_files(subfolder)

      for (snirf_path in snirfs) {
        parent_folder <- dirname(snirf_path)
        file_name <- tools::file_path_sans_ext(basename(snirf_path))
        cat("Processing:", file_name, "in", parent_folder, "\n")

        snirf2bids(
          source_snirf = snirf_path,
          converted_root = converted_root,
          experiment_description = experiment_description,
          routine = routine,
          py_env = py_env
        )
      }

      }
    }
  }






