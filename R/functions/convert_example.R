#### EXAMPLES ####
KODUN_task_map <- "./R/experiments/KODUN.csv"
converted_root <- pathlib$Path("./converted")
# Example of using snirf2bids with a single file
source_snirf <- "Z:/15/A_44_RL/Projekt 2 fNIRS/data/raw/aurora/2025-09-10/2025-09-10_002/2025-09-10_002.snirf"
snirf2bids(source_snirf, converted_root, KODUN_task_map)

# Or with a multiple file
source_path <- "Z:/15/A_44_RL_KODUN/Hiwi/datacheck/to_analyze"

convert_root(source_path, converted_root, KODUN_task_map)

json_df_example <- fromJSON("Z:/15/A_44_RL_KODUN/Hiwi/datacheck/to_analyze/2025-05-26_002/2025-05-26_002_description.json")
