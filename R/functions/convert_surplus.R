#### SURPLUS/TBC ####
# Existing entries in Python dict can be accessed as a named list in r
# Overview of all entries: names(raw$info)
# Access single entry: raw$info["sfreq"]
# Call method: raw$plot_sensors()

# Check for subject ID
raw$info['subject_info']$his_id
# Read subject ID and manufacturer name from the snirf directly with Rhdf5
rhdf5_AuroraVersion <- h5read(source_snirf, "/nirs/metaDataTags/AuroraVersion")
# Check if subject is saved anywhere else in the rhdf5
subject_entries <- rhdf5_structure[grepl("subject", rhdf5_structure$name, ignore.case = TRUE), ]
