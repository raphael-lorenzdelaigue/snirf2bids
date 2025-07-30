install_wheels <- function() {
  wheel_dir <- "./install/wheels"
  dir.create(wheel_dir, recursive = TRUE, showWarnings = FALSE)

  pip_path <- file.path(venv_path, "Scripts", "pip.exe")

  # Create temporary requirements file
  req_file <- tempfile(fileext = ".txt")
  writeLines(c(
    "mne[nirs]",
    "mne-bids",
    "h5py",
    "numpy",
    "scipy",
    "matplotlib",
    "pandas",
    "scikit-learn",
    "statsmodels",
    "nibabel"
  ), con = req_file)

  args <- c("download", "-r", req_file, "-d", wheel_dir)
  system2(pip_path, args = args)

  cat("✅ Wheels downloaded to", normalizePath(wheel_dir), "\n")
}

install_wheels()
