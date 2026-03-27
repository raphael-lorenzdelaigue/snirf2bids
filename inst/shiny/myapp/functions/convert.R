#### SETUP ####
call_rhdf <- rhdfconfig()

if (!require("rhdf5", quietly = T))
  BiocManager::install("rhdf5", configure.args="--no-staged-install")

library(reticulate)
library(rhdf5)
library(jsonlite)
library(here)

venv_path <- here("R", "install", "PyEnv")
vendor_hooks_path <- here("R", "functions", "vendor_hooks.R")

# Always normalize paths for Windows compatibility
venv_path <- normalizePath(venv_path, winslash = "/", mustWork = FALSE)
vendor_hooks_path <- normalizePath(vendor_hooks_path, winslash = "/", mustWork = FALSE)
# old version (use local venv)
#reticulate::use_virtualenv(venv_path, required = TRUE)
# connect previously created python environment + packages
if("mne-env" %in% conda_list()[["name"]])
   {
     use_condaenv("mne-env", required = TRUE)
   } else {

     # Install Miniconda into reticulate’s default location (no spaces in path)
     install_miniconda()

     # Create a new conda environment with a specific Python version
     # conda_create("mne-env", packages = c("python=3.9.13")) #future scripts call to "mne-env"
     ## MNE BIDS Require python 3.10 or later (?)
     #
     conda_create("mne-env", packages = c("python=3.10")) #future scripts call to "mne-env"

     # Install Python packages into that env via conda
     conda_install("mne-env", packages = c("mne", "numpy", "scipy", "mne-bids[full]", "matplotlib", "pandas"),
                   channel = "conda-forge")

     use_condaenv("mne-env", required = TRUE)
}


source(vendor_hooks_path)
# Import Python modules
mne <- import("mne")
mnebids <- import("mne_bids")
h5py <- import("h5py")
pathlib <- import("pathlib")

# Access specific Python functions & classes
BIDSPath <- mnebids$BIDSPath
write_raw_bids <- mnebids$write_raw_bids

#### ACCESS THE PATH TO SAVE THE CONVERTED VALUES ####
make_output_folder <- function(file_path_reactive) {
  reactive({
    file_path <- file_path_reactive()
    if (is.null(file_path) || file_path == "") return(NULL)
    basename(dirname(file_path))
  })
}

#### CONVERT ROUTINE (ONE FILE) ####
# Function that reads a source SNIRF file, checks for ID and manufacturer name
# If there is no ID and manufacturer name = NIRx, it checks for a description.json file in the same folder containing the SNIRF
# Reads subject ID and experiment entry from there
# And then deducts the task name and entered value for experiment from there, based on the experiment_description file

#' snirf2bids function for conversion
#'
#' @param source_snirf
#' @param converted_root
#' @param experiment description
#' @export
snirf2bids <- function (source_snirf, converted_root, experiment_description) {
  not_converted <- c()
  # Read ID and manufacturer from inside the SNIRF
  rhdf5_id <- h5read(source_snirf, "/nirs/metaDataTags/SubjectID")
  rhdf5_manufacturer <- h5read(source_snirf, "/nirs/metaDataTags/ManufacturerName")
  task_map <- read.csv(experiment_description, colClasses = c("session" = "character"))

  # If ID is not specified & manufacturer is NirX, check if there is a description.json
  if (rhdf5_id =="" & grepl("NIRx", rhdf5_manufacturer)) {
    json_path <- check_description_json(source_snirf)

    if (!is.null (json_path)) {
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
        bids_path <- BIDSPath(subject = file_tags$subject, session = file_tags$session, task = file_tags$task, root = converted_root)
      }

      # ELSE create BIDS path inside "no_mapping" folder with session "999"
      else {
        file_tags$task <- gsub("[-_/]", "", file_tags$experiment) # Remove BIDS non-conforming characters from the string
        file_tags$session <- "999"
        no_mapping_path <- file.path(converted_root, "no_mapping")
        dir.create(no_mapping_path, recursive = TRUE, showWarnings = FALSE)
        bids_path <- BIDSPath(subject = file_tags$subject, session = file_tags$session, task = file_tags$task, root = no_mapping_path)
      }
      # Load data with MNE and convert to BIDS format
      raw = mne$io$read_raw_snirf(source_snirf, preload = FALSE)
      write_raw_bids(raw, bids_path, overwrite=T)
    }
    else {
      file_tags <- data.frame()
    }
  }

  # TO DO: read subject, session and task from the input folder
  else {
    #subject <- ("..")
    #session <- (".")
  }

}

#### CONVERT ROUTINE (ONE FOLDER) ####
# Helper function that finds all .snirf files in a specific folder
get_snirf_files <- function(folder) {
  list.files(folder, pattern = "\\.snirf$", ignore.case = TRUE, full.names = TRUE)
}

# Runs SNIRF2BIDS with lapply on data directory
convert_root <- function (source_root, converted_root, experiment_description) {
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

        snirf2bids(snirf_path, converted_root, experiment_description)
      }

      }
    }
  }






