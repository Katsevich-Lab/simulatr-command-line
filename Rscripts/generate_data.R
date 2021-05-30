# accept command line arguments, load simulatr_specifier
args <- commandArgs(trailingOnly = TRUE)
library(simulatr)
simulatr_spec <- readRDS(args[1])
row_idx <- as.integer(args[2])
base_fp <- args[3]

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

# split data_list into n_processors equally sized chunks
n_processors <- get_param_from_simulatr_spec(simulatr_spec, row_idx, "n_processors")
cuts <- cut(seq(1, length(data_list)), n_processors)
l_cuts <- levels(cuts)
for (i in seq(1, n_processors)) {
  to_save_data <- data_list[cuts == l_cuts[i]]
  to_save_object <- list(data_list = to_save_data, row_idx = row_idx, proc_id = i)
  to_save_fp <- paste0(base_fp, i, ".rds")
  saveRDS(to_save_object, to_save_fp)
}
