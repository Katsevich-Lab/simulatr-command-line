# accept command line arguments, load simulatr_specifier
args <- commandArgs(trailingOnly = TRUE)
library(simulatr)
simulatr_spec <- readRDS(args[1])
row_idx <- as.integer(args[2])
save_fp <- args[3]

# load extra packages (if necessary)
data_generator <- simulatr_spec@generate_data_function
packs_to_load <- data_generator@packages
if (!(identical(packs_to_load, NA_character_))) invisible(lapply(packs_to_load, function(pack) library(pack, character.only = TRUE)))

# set seed
seed <- get_param_from_simulatr_spec(simulatr_spec, row_idx, "seed")
set.seed(seed)

# obtain the ordered list of arguments to pass to data generator
ordered_args <- lapply(data_generator@arg_names, function(curr_arg)
  get_param_from_simulatr_spec(simulatr_spec, row_idx, curr_arg))

# call the data generator function; either loop or just pass all arguments
if (data_generator@loop) {
  B <- get_param_from_simulatr_spec(simulatr_spec, row_idx, "B")
  data_list <- replicate(B, do.call(data_generator@f, ordered_args), FALSE)
} else {
  data_list <- do.call(data_generator@f, ordered_args)
}

# split the data_list into n_cores equally sized chunks (for later)
# save the data_list
saveRDS(data_list, save_fp)
