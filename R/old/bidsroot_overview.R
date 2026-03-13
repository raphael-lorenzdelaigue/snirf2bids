# Overview of folders inside of a bids_root folder
listBidsFolders <- function(bids_root) {

  # Get participant directories in the BIDS directory
  allFolders <- list.dirs(path = bids_root, recursive = TRUE, full.names = TRUE)
  # print(allFolders)
  bidsSubjFolders <- allFolders[grepl("^sub-[A-Za-z0-9]+$", basename(allFolders))]

  # Get all nested directories (including empty ones)
  bidsSubjFolders_andSub <- unlist(lapply(bidsSubjFolders, function(dir) {
    list.dirs(path = dir, recursive = TRUE, full.names = TRUE)
  }))
  return(list(
    allFolders = allFolders,
    bidsSubjFolders = bidsSubjFolders,
    bidsSubjFolders_andSub = bidsSubjFolders_andSub
  ))
}
