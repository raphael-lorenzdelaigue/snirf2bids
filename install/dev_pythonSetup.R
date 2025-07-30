install_wheels <- function() {
  wheel_dir <- "./install/wheels"

  dir.create(wheel_dir, recursive = TRUE, showWarnings = FALSE)

  # List of required Python packages
  packages <- c("mne", "mne-bids", "h5py", "numpy")

  # Path to pip (from a known virtualenv or Python install)
  pip_path <- file.path(venv_path, "Scripts", "pip.exe")

  # Combine pip arguments to download wheels
  args <- c("download", packages, "-d", wheel_dir)

  # Run the pip command to download wheels
  system2(pip_path, args = args)
}
