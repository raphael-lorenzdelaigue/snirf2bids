#### SETUP ####
library(reticulate)
library(rhdf5)
reticulate::use_virtualenv("./install/PyEnv", required = TRUE)

# Import Python modules
mne <- import("mne")
mnebids <- import("mne_bids")
h5py <- import("h5py")
pathlib <- import("pathlib")

# Access specific Python functions & classes
BIDSPath <- mnebids$BIDSPath
write_raw_bids <- mnebids$write_raw_bids

#### CONVERT ROUTINE ####
# READ SNIRF VIA R-NATIVE RHDF5
snirf_path <- "Z:/15/A_44_RL/Projekt 2 fNIRS/data/raw/aurora/2025-07-07/2025-07-07_001/2025-07-07_001.snirf"

# Read subject ID and manufacturer
rhdf5_id <- h5read(snirf_path, "/nirs/metaDataTags/SubjectID")
rhdf5_manufacturer <- h5read(snirf_path, "/nirs/metaDataTags/ManufacturerName")

if (rhdf5_id =="" & grepl("NIRx", rhdf5_manufacturer)) {
  check_description_json("snirf_path")
}

# Existing entries in Python dict can be accessed as a named list in r
# Overview of all entries: names(raw$info)
# Access single entry: raw$info["sfreq"]
# Call method: raw$plot_sensors()

# Load data
raw = mne$io$read_raw_snirf(snirf_path, preload = FALSE)
# Check for subject ID
raw$info['subject_info']$his_id


subject_id <- "BB11BB22"
task <- "Doppelter Rückwärtssalto"
bids_root <- pathlib$Path("C:/Users/siifz01/Documents/bids_processed")

bids_path <- BIDSPath(subject = subject_id, session = "01", task = task, root = bids_root)
write_raw_bids(raw, bids_path, overwrite=T)



rhdf5_AuroraVersion <- h5read(snirf_path, "/nirs/metaDataTags/AuroraVersion")

# Check if subject is saved anywhere else in the rhdf5
subject_entries <- rhdf5_structure[grepl("subject", rhdf5_structure$name, ignore.case = TRUE), ]
