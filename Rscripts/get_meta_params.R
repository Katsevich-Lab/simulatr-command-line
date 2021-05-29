args <- commandArgs(trailingOnly = TRUE)
sim_obj <- readRDS(args[1])
meta_params_fp <- args[2]
library(simulatr)
get_params_for_nextflow(sim_obj, meta_params_fp)
