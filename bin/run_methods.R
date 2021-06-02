# accept command line arguments, load simulatr_specifier
args <- commandArgs(trailingOnly = TRUE)
library(simulatr)
simulatr_spec <- readRDS(args[1])
data_list_obj <- readRDS(args[2])
method <- args[3]
B_in <- as.integer(args[4])
raw_result_fp <- args[5]

# row_idx and proc_id
row_idx <- data_list_obj[["row_idx"]]
proc_id <- data_list_obj[["proc_id"]]

# set the method object
method_object <- simulatr_spec@run_method_functions[[method]]

# obtain ingredients for running method
out <- setup_script(simulatr_spec, B_in, method_object, row_idx)
simulatr_spec <- out$simulatr_spec
ordered_args <- c(list(NA), out$ordered_args)

# call the method; either loop or pass entire data list
data_list <- data_list_obj[["data_list"]]
if (method_object@loop) {
  result_list <- lapply(seq(1, length(data_list)), function(i) {
    curr_df <- data_list[[i]]
    ordered_args[[1]] <- curr_df
    out <- do.call(method_object@f, ordered_args)
    out$run_id <- i
    return(out)
  })
  result_df <- do.call(rbind, result_list)
} else {
  ordered_args[[1]] <- data_list
  result_df <- do.call(method_object@f, ordered_args)
}

library(dplyr)
# add the IDs, convert to factors
colnames_result_df <- colnames(result_df)
convert_to_factor <- c(c("run_id", "proc_id", "grid_row_id", "method", "id"),
                       if ("parameter" %in% colnames_result_df) "parameter" else NULL,
                       if ("target" %in% colnames_result_df) "target" else NULL)
out <- result_df %>% mutate(proc_id = proc_id,
                     grid_row_id = row_idx,
                     method = method,
                     id = paste0(method, "-",
                                 row_idx, "-",
                                 proc_id, "-",
                                 as.integer(run_id))) %>%
  mutate_at(convert_to_factor, factor)

# save result
saveRDS(out, raw_result_fp)
