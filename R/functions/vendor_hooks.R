# NIRx
check_description_json <- function(snirf_path) {
  # Get the directory and base filename (without extension)
  dir_path <- dirname(snirf_path)
  base_name <- tools::file_path_sans_ext(basename(snirf_path))

  # Construct expected path of description JSON file
  json_filename <- paste0(base_name, "_description.json")
  json_path <- file.path(dir_path, json_filename)
  print(json_path)

  # Check if the file exists
  if (file.exists(json_path)) {
    cat("✅ Description file found at:", json_path, "\n")
    return(json_path)
  } else {
    stop("❌ No description file found for '", base_name, "' at expected location: ", json_path)
    return(NULL)
  }
}
