library(readr)

name <- c("KODUN_localizer", "KODUN_ET", "KODUN_ET1", "KODUN_restingstate", "KODUN_session1", "KODUN_session2", "KODUN_session3", "KODUN_session4", "KODUN_session5", "KODUN_session6", "KODUN_session7", "KODUN_session8", "KODUN_restingstate2", "KODUN_ET2")
task <- c("localizer", "ET", "ET", "restingstate", "nf", "nf", "nf", "nf", "nf", "nf", "nf", "nf", "restingstate", "ET")
session <- c("01", "01", "01", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "10")

KODUN <- data.frame(name, task, session)
write_csv(KODUN, "./experiments/KODUN.csv")
