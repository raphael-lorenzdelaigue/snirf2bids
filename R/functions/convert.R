#### SETUP ####
library(reticulate)
library(rhdf5)
library(jsonlite)
reticulate::use_virtualenv("./install/PyEnv", required = TRUE)
source("./functions/vendor_hooks.R")

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
      json_df <- as.data.frame(t(unlist(json_content)), stringsAsFactors = FALSE)

      # Add the subfolder name as a column
      json_df$subfolder <- basename(dirname(json_path))

      # IF the information inside description.json matches experiment description, create BIDS path with corresponding info
      # ELSE copy into "unknown" folder
      if (any(task_map$name == json_df$experiment)) {
        # Read task and session from the experiment overview
        json_df$task <- task_map$task[task_map$name == json_df$experiment]
        json_df$session <- task_map$session[task_map$name == json_df$experiment]
        bids_path <- BIDSPath(subject = json_df$subject, session = json_df$session, task = json_df$task, root = converted_root)
      }
      else {
        json_df$task <- gsub("[-_/]", "", json_df$experiment) # Remove BIDS non-conforming characters from the string
        json_df$session <- "999"
        unknown_path <- file.path(converted_root, "unknown")
        dir.create(unknown_path, recursive = TRUE, showWarnings = FALSE)
        bids_path <- BIDSPath(subject = json_df$subject, session = json_df$session, task = json_df$task, root = unknown_path)
      }
      # Load data with MNE and convert to BIDS format
      raw = mne$io$read_raw_snirf(source_snirf, preload = FALSE)
      write_raw_bids(raw, bids_path, overwrite=T)
    }
    else {
      json_df <- data.frame()
    }
  }

  # To add: what happens if the id is indeed specified in the SNIRF
}

#### CONVERT ROUTINE (ONE FOLDER) ####
# Helper function that finds all .snirf files in a specific folder
get_snirf_files <- function(folder) {
  list.files(folder, pattern = "\\.snirf$", ignore.case = TRUE, full.names = TRUE)
}

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

      lapply(snirfs, function(snirf_path) {
        # Prompt for user showing which folder is being analyzed
        parent_folder <- dirname(snirf_path)
        file_name <- tools::file_path_sans_ext(basename(snirf_path))
        cat("Processing:", file_name, "in", parent_folder, "\n")

        # Move the SNIRF file to the correct position
        snirf2bids(snirf_path, converted_root, experiment_description)
        })

      }
    }
  }






