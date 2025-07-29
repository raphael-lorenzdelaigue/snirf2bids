#### R AND PYTHON SETUP ####
# Load R Packages
library(reticulate)

#### FOR PHILIPP: CREATE PYTHON 3.9 VIRTUAL ENVIRONMENT FROM R ####
# Instead of using reticulate functions, we are running these commands from shell (which worked, even though I do not really understand why)
python_path <- "C:/Users/siifz01/AppData/Local/Programs/Python/Python39/python.exe" # needs to be 64bit
venv_path <- "Z:/15/A_44_RL/Projekt 3 NIRS2BIDS/Programmierung/NIRS2BIDS/py39Env"

# 1. Create virtual environment on network drive
system2(python_path, args = c("-m", "venv", shQuote(venv_path)))

# 2. Activate environment and upgrade pip, setuptools, wheel
#    Since activation scripts are shell-specific and tricky from R,
#    you can run pip directly using the venv's python.exe
venv_python <- file.path(venv_path, "Scripts", "python.exe")

# Upgrade pip, setuptools, wheel inside venv
system2(venv_python, args = c("-m", "pip", "install", "--upgrade", "pip", "setuptools", "wheel"))
# 3. Install packages in the venv
system2(venv_python, args = c("-m", "pip", "install", "mne", "mne-bids", "h5py", "pathlib"))

# Check if 64 bit
system2(python_path, args = "-c \"import struct; print(struct.calcsize('P') * 8)\"")

#### INSTALL NECESSARY R PACKAGES ####
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

BiocManager::install("rhdf5")
#### LOAD PYTHON ENVIRONMENT AND MODULES ####
reticulate::use_virtualenv("./py39Env", required = TRUE)

# Import Python modules
mne <- import("mne")
mnebids <- import("mne_bids")
h5py <- import("h5py")
pathlib <- import("pathlib")

# Access specific Python functions & classes
BIDSPath <- mnebids$BIDSPath
write_raw_bids <- mnebids$write_raw_bids

#### READ SNIRF VIA PYTHON-BASED HDF5 (CURRENTLY NOT WORKING) ####
print_hdf5_structure <- function(group, prefix = "") {
  # Convert Python iterable keys() to R character vector
  names <- reticulate::py_to_r(group$keys())

  for (name in names) {
    item <- group[[name]]
    path <- paste0(prefix, "/", name)

    # Check if 'item' is a group (has keys attribute)
    if (reticulate::py_has_attr(item, "keys")) {
      cat("📁 Group:", path, "\n")
      print_hdf5_structure(item, path)

    } else {
      # Dataset - try to read as string or numeric, then convert to R
      value <- tryCatch({
        # Try as string dataset (returns Python list of strings)
        val <- item$asstr()$tolist()
        # If length 1, unpack the single string
        if (length(val) == 1) val <- val[[1]]
        val
      }, error = function(e) {
        tryCatch({
          # Try as numeric or other array/scalar, convert to R
          val <- item[reticulate::tuple()]
          reticulate::py_to_r(val)
        }, error = function(e2) {
          "<unreadable>"
        })
      })

      # If value is a vector or list, collapse for nicer printing
      if (is.vector(value) || is.list(value)) {
        value <- paste(value, collapse = ", ")
      }

      cat("📄 Dataset:", path, "=>", value, "\n")
    }
  }
}

f <- h5py$File("Z:/15/A_44_RL/Projekt 2 fNIRS/data/raw/aurora/2024-10-29/2024-10-29_002/2024-10-29_002.snirf", "r")
print_hdf5_structure(f)

#### READ SNIRF VIA R-NATIVE RHDF5 ####
# List all paths in SNIRF file
structure <- h5ls("Z:/15/A_44_RL/Projekt 2 fNIRS/data/raw/aurora/2024-10-29/2024-10-29_002/2024-10-29_002.snirf", all = TRUE)

# Optional: show just datasets with their values
for (i in seq_len(nrow(structure))) {
  if (structure$otype[i] == "H5I_DATASET") {
    path <- paste0(structure$group[i], "/", structure$name[i])
    value <- tryCatch(h5read("your_file.snirf", path), error = function(e) "<unreadable>")
    cat("📄", path, "=>", value, "\n")
  }
}
#### READ SNIRF VIA MNE BIDS ####

# Load data
raw = mne$io$read_raw_snirf("Z:/15/A_44_RL/Projekt 2 fNIRS/data/raw/aurora/2024-10-29/2024-10-29_002/2024-10-29_002.snirf", preload = FALSE)

# Read info
info <- reticulate::py_to_r(raw$info)
for (name in names(info)) {
  cat("===", name, "===\n")
  print(info[[name]])
  cat("\n")
}

# Check for subject ID
raw$info['subject_info']$his_id


# Existing entries in Python dict can be accessed as a named list in r
# Overview of all entries: names(raw$info)
# Access single entry: raw$info["sfreq"]
# Call method: raw$plot_sensors()
subject_id <- "BB11BB22"
task <- "Doppelter Rückwärtssalto"
bids_root <- pathlib$Path("C:/Users/siifz01/Documents/bids_processed")

bids_path <- BIDSPath(subject = subject_id, session = "01", task = task, root = bids_root)
write_raw_bids(raw, bids_path, overwrite=T)
