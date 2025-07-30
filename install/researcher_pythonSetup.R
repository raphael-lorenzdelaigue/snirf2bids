#### INSTALLER FUNCTIONS ####
venv_path <- "./install/PyEnv"
wheels_path <- "./install/wheels"

install_python_admin <- function() {
  installer <- "install/python-3.9.13-amd64.exe"
  expected_python_path <- "C:/Program Files/Python39/python.exe"

  # 1. Check if installer is present
  if (!file.exists(installer)) {
    stop("❌ Python installer not found at: ", installer)
  }

  # 2. Silent install (system-wide), assumes admin rights
  cat("⚙️ Attempting silent system-wide install of Python...\n")
  status <- system2(installer, args = c(
    "/quiet",
    "InstallAllUsers=1",
    "PrependPath=1",
    "Include_test=0",
    "Include_launcher=0"
  ))

  # 3. Check installation result
  if (status != 0) {
    stop("❌ Python installation failed with status code: ", status)
  }

  # 4. Verify Python executable exists
  if (!file.exists(expected_python_path)) {
    stop("❌ Python installation completed, but executable not found at: ", expected_python_path)
  }

  cat("✅ Python installed successfully at: ", expected_python_path, "\n")

  return(expected_python_path)
}

install_python_user <- function() {
  installer <- "install/python-3.9.13-amd64.exe"
  if (!file.exists(installer)) {
    stop("❌ Python installer not found at: ", installer)
  }

  # Get a user-writable temp path without spaces
  user_temp <- Sys.getenv("LOCALAPPDATA")
  if (user_temp == "") {
    stop("LOCALAPPDATA environment variable not found.")
  }
  target_dir <- file.path(user_temp, "Programs", "Python", "Python39")
  target_dir <- normalizePath(target_dir, winslash = "\\", mustWork = FALSE)

  expected_python <- file.path(target_dir, "python.exe")
  expected_python <- normalizePath(expected_python, winslash = "\\", mustWork = FALSE)

  cat("⚙️ Attempting silent *user* install of Python to:", target_dir, "...\n")
  dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)
  cat("Target directory succesfully created")

  target_arg <- paste0("TargetDir=", target_dir)

  status <- system2(installer, args = c(
    "/quiet",
    "InstallAllUsers=0",
    "Include_launcher=0",
    "InstallLauncherAllUsers=0",
    "PrependPath=0",
    "Include_test=0",
    target_arg
  ))

  if (status != 0) {
    stop("❌ Python installation failed with status code: ", status)
  }

  if (!file.exists(expected_python)) {
    stop("❌ Python installed, but executable not found at: ", expected_python)
  }

  cat("✅ Python installed successfully at:", expected_python, "\n")
  return(expected_python)
}

create_pyEnv <- function (python_path) {
  cat("Creating virtual environment at:\n", venv_path, "\n")
  system2(python_path, args = c("-m", "venv", shQuote(venv_path)))
}

# We update pip, setuptools and wheel to make sure that there are no compatibility issues
# Might not even necessary
# And install packages from wheels
setup_pyEnv <- function() {
  venv_python <- file.path(venv_path, "Scripts", "python.exe")
  cat("Upgrading pip, setuptools, and wheel...\n")
  system2(venv_python, args = c("-m", "pip", "install", "--upgrade", "pip", "setuptools", "wheel"))

  cat("Installing required Python packages from local wheels...\n")
  find_links_arg <- shQuote(paste0("--find-links=", normalizePath(wheels_path))) # use Shquote to ensure that paths with spaces are passed as single shell argument

  system2(
    venv_python,
    args = c(
      "-m", "pip", "install",
      "--no-index",
      find_links_arg,
      "mne", "mne-bids", "h5py"
    )
  )

  cat("Python environment setup complete.\n")

  # Returns path to the Python executable
  return(invisible(venv_python))
}

#### RUN THIS SCRIPT ####
python_path <- install_python_user()
create_pyEnv(python_path)
setup_pyEnv()

#### WORK IN PROGRESS ####
find_python <- function() {
  # Try reticulate
  if (reticulate::py_available(initialize = FALSE)) {
    config <- reticulate::py_discover_config()
    cat ("Found via py_discover_config")
    return(config$python)
  }

  # Check fallback paths
  common_paths <- c(
    Sys.which("python"),
    "C:/Program Files/Python39/python.exe",
    "C:/Users/YourUsername/AppData/Local/Programs/Python/Python39/python.exe"
  )

  for (p in common_paths) {
    if (file.exists(p)) {
      cat("Found via common paths")
      return(p)
    }
  }

  return(NULL)
}

install_python_user_insideFolder <- function() {
  installer <- "install/python-3.9.13-amd64.exe"
  target_dir <- normalizePath("install/Python39User", winslash = "\\", mustWork = FALSE)
  expected_python <- file.path(target_dir, "python.exe")

  if (!file.exists(installer)) {
    stop("❌ Python installer not found at: ", installer)
  }

  cat("⚙️ Attempting silent *user* install of Python...\n")
  dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)

  # Wrap *entire* TargetDir=... in quotes, and avoid quoting the entire arg list again
  target_arg <- paste0('TargetDir="', target_dir, '"')

  status <- system2(installer, args = c(
    "/quiet",
    "InstallAllUsers=0",
    "Include_launcher=0",
    "InstallLauncherAllUsers=0",
    "PrependPath=0",
    "Include_test=0",
    target_arg
  ))

  if (status != 0) {
    stop("❌ Python installation failed with status code: ", status)
  }

  if (!file.exists(expected_python)) {
    stop("❌ Python installed, but executable not found at: ", expected_python)
  }

  cat("✅ Python installed successfully at:", expected_python, "\n")
  return(expected_python)
}
