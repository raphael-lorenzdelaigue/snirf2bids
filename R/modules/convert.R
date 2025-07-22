#### R AND PYTHON SETUP ####
# Load R Packages
library(reticulate)

# Load Python environment
use_virtualenv("Z:/15/A_44_RL/Projekt 2 fNIRS/Messungen/RekrutierungTeilnehmerkontakt/Terminverwaltung/pythonProject/venv", required = TRUE)

# Import Python modules
mne <- import("mne")
mnebids <- import("mne_bids")
h5py <- import("h5py")
pathlib <- import("pathlib")

# Access specific Python functions & classes
BIDSPath <- mnebids$BIDSPath
write_raw_bids <- mnebids$write_raw_bids

#### CONVERT ####
# Load data
raw = mne$io$read_raw_snirf("Z:/15/A_44_RL/Projekt 2 fNIRS/data/raw/aurora/2024-10-29/2024-10-29_002/2024-10-29_002.snirf", preload = FALSE)

# Existing entries in Python dict can be accessed as a named list in r
# Overview of all entries: names(raw$info)
# Access single entry: raw$info["sfreq"]
# Call method: raw$plot_sensors()
subject_id <- "BB11BB22"
task <- "Doppelter Rückwärtssalto"
bids_root <- pathlib$Path("C:/Users/siifz01/Documents/bids_processed")

bids_root <- data_dir$with_name(paste0(data_dir$name, "-bids"))
bids_path <- BIDSPath(subject = subject_id, task = task, root = bids_root)
write_raw_bids(raw, bids_path, overwrite=T)
