# accept command line arguments, load simulatr_specifier
args <- commandArgs(trailingOnly = TRUE)
library(simulatr)
simulatr_spec <- readRDS(args[1])
data_list <- readRDS(args[2])
method <- args[3]
raw_result_fp <- args[4]

# row_idx and proc_id
row_idx <- data_list[["row_idx"]]
proc_id <- data_list[["proc_id"]]

# load extra packages (if necessary)
method_object <- simulatr_spec@run_method_functions[[method]]
packs_to_load <- method_object@packages
if (!(identical(packs_to_load, NA_character_))) invisible(lapply(packs_to_load, function(pack)
  library(pack, character.only = TRUE)))

# set seed
seed <- get_param_from_simulatr_spec(simulatr_spec, row_idx, "seed")
set.seed(seed)

# obtain the ordered list of arguments to pass to method
if (identical(method_object@arg_names, NA_character_)) {
  arg_list <- list(NULL)
} else {
  ordered_args <- lapply(method_object@arg_names, function(curr_arg)
    get_param_from_simulatr_spec(simulatr_spec, row_idx, curr_arg))
  arg_list <- c(list(NULL), ordered_args)
}

# call the method; either loop or pass entire data list
data_list_pure <- data_list[["data_list"]]
if (method_object@loop) {
  result_list <- lapply(seq(1, length(data_list_pure)), function(i) {
    curr_df <- data_list_pure[[i]]
    arg_list[[1]] <- curr_df
    out <- do.call(method_object@f, arg_list)
    out$run_id <- i
    return(out)
  })
  result_df <- do.call(rbind, result_list)
} else {
  arg_list[[1]] <- data_list_pure
  result_df <- do.call(method_object@f, arg_list)
}

# add the IDs, convert to factors
result_df$proc_id <- factor(proc_id)
result_df$grid_row_id <- factor(row_idx)
result_df$method_id <- factor(method)
result_df$id <- factor(paste0(method, "-", row_idx, "-", proc_id, "-", as.integer(result_df$run_id)))
result_df$run_id <- factor(result_df$run_id)
result_df$parameter <- factor(result_df$parameter)
result_df$target <- factor(result_df$target)

# save result
saveRDS(result_df, raw_result_fp)
