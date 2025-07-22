checkFolderContent <- function(folder) {
  # Initialize results list
  # all_files <- list()
  files <- list.files(folder, full.names = TRUE)
  files <- files[file.info(files)$isdir == FALSE]
}

# For each directory, list files (can be empty)
# And saves result as a list of "full_path" and "filename"
for(d in all_dirs) {


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
max_len <- max(sapply(split_paths, length))
padded <- lapply(split_paths, function(x) c(x, rep(NA, max_len - length(x))))

# Convert to data frame
subject_file_overview <- do.call(rbind, padded) |> as.data.frame(stringsAsFactors = FALSE)

# Set column names (assuming you know the max number of subdirectories)
colnames(subject_file_overview) <- c(paste0("level", 1:(ncol(subject_file_overview) - 1)), "filename")
print(paste0("Content of subject file overview: ", subject_file_overview))
return(subject_file_overview)
}
