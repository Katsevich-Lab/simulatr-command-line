# accept command line arguments
args <- commandArgs(trailingOnly = TRUE)
result_fp <- args[1]
raw_data_fps <- args[seq(2, length(args))]

result <- do.call(rbind, lapply(raw_data_fps, readRDS))
saveRDS(result, result_fp)