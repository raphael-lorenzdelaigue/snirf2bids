# Takes a path as input, that might contain BIDS-formatted files and folders (located by subject directories sub-)
# And outputs a file overview with information (e.g. on path) on each of the files
# Returns empty data frame is no "sub-" folder is found
generate_file_overview <- function(bids_root) {

  # Get participant directories in the BIDS directory
  dirs <- list.dirs(path = bids_root, recursive = TRUE, full.names = TRUE)
  participant_dirs <- grep("sub-[a-zA-Z]{2}[0-9]{2}[a-zA-Z]{2}[0-9]{2}$", dirs, value = TRUE)

  #print(paste0("Content of dirs variable: ", dirs))
  print(paste0("Content of participant_dirs variable: ", participant_dirs))

  # Check number of "sub-" folders and act accordingly
  if (length(participant_dirs) == 0) {
    subject_file_overview <- data.frame()
  } else {
    # Get all nested directories (including empty ones)
    all_dirs <- unlist(lapply(participant_dirs, function(dir) {
      list.dirs(path = dir, recursive = TRUE, full.names = TRUE)
    }))
    #print(paste0("Content of all_dirs variable: ", all_dirs))

    # Initialize results list
    all_files <- list()

    # For each directory, list files (can be empty)
    # And saves result as a list of "full_path" and "filename"
    for(d in all_dirs) {
      files <- list.files(d, full.names = TRUE)
      files <- files[file.info(files)$isdir == FALSE]
      if (length(files) == 0) {
        # No files, just show the path with NA for filename
        all_files[[length(all_files) + 1]] <- list(path = d, filename = NA)
      } else {
        for (f in files) {
          all_files[[length(all_files) + 1]] <- list(path = f, filename = basename(f))
        }
      }
    }
    print(paste0("Content of all_files variable: ", all_files))

    # Extract path components
    split_paths <- lapply(all_files, function(entry) {
      parts <- str_split(entry$path, "/|\\\\")[[1]]  # Windows + Unix safe
      c(parts, entry$filename)
    })

    print(paste0("Content of split_paths variable: ", split_paths))

    # Pad to equal length
    max_len <- max(unlist(lapply(split_paths, length)))
    padded <- lapply(split_paths, function(x) c(x, rep(NA, max_len - length(x))))

    # Convert to data frame
    subject_file_overview <- do.call(rbind, padded) |> as.data.frame(stringsAsFactors = FALSE)

    # Set column names (assuming you know the max number of subdirectories)
    colnames(subject_file_overview) <- c(paste0("level", 1:(ncol(subject_file_overview) - 1)), "filename")
  }

  return(subject_file_overview)
}
