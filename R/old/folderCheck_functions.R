# Given folder list, creates data frame where each level of the path is saved into separate column of a dataframe
sub_pattern <- "^sub-[A-Za-z0-9]+$"

folderStructure_toDF <- function(folder_paths) {
    # Split paths into components
    split_paths <- lapply(folder_paths, function(path) {
      str_split(path, "/|\\\\")[[1]]  # Windows + Unix safe
    })

    # Handle the case where split_paths is empty or has only empty elements
    if (length(split_paths) == 0 || all(sapply(split_paths, length) == 0)) {
      return(data.frame())  # Return empty data frame
    }

    # Add NA to "empty" entries
    max_len <- max(sapply(split_paths, length))
    padded <- lapply(split_paths, function(x) c(x, rep(NA, max_len - length(x))))

    # Convert to data frame
    file_overview <- do.call(rbind, padded) |> as.data.frame(stringsAsFactors = FALSE)

    # Set column names (assuming you know the max number of subdirectories)
    colnames(file_overview) <- c(paste0("level", 1:(ncol(file_overview))))

    # Test commit
    return(file_overview)
}

# Check if a certain id is present in subject path (for a single id and path)
checkSubjectFolderPresent <- function (id, path) {
  expected_subfolder <- paste0("sub-", id)
  # Use basename to get last folder name, or just check if folder_path contains expected_subfolder anywhere
  return(grepl(expected_subfolder, path, fixed = TRUE))
}


subjectFolderCheck <- function(sub_ids, sub_folder_paths) {
  return(mapply(checkSubjectFolderPresent, sub_ids, sub_folder_paths))
}

snirf2bids_folderOverview <- function(sub_ids, sub_folder_paths) {
  df <- data.frame(subject = sub_ids,
                   folder_present = subjectFolderCheck(sub_ids, sub_folder_paths))
  return (df)
}
