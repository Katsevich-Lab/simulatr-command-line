// params.sim_obj_fp
// params.metaparam_file
// params.B
// params.result_dir
// params.code_dir

// Load metaparams.txt, and put these values into a map
meta_params = [:]
my_file = file(params.metaparam_file)
all_lines = my_file.readLines()
for (line : all_lines) {
    str_split = line.split(':')
    key = str_split[0]
    if (key == "method_names") {
      value = str_split[1].split('-')
    } else {
      value = str_split[1]
    }
    meta_params[key] = value
}

// Generate data
n_param_settings = meta_params["n_param_settings"].toInteger()
param_idx_ch = Channel.of(1..n_param_settings)
process generate_data {
  input:
  val i from param_idx_ch

  output:
  file 'data_list_*.rds' into data_ch

  """
  Rscript $projectDir/bin/generate_data.R $params.sim_obj_fp $i $params.B data_list_
  """
}

// Run methods
method_ch = Channel.of(meta_params["method_names"])
method_times_data_ch = method_ch.combine(data_ch.flatten())
process run_methods {
  input:
  tuple val(method), file('data_list.rds') from method_times_data_ch

  output:
  file 'raw_result.rds' into raw_results_ch

  """
  Rscript $projectDir/bin/run_methods.R $params.sim_obj_fp data_list.rds $method $params.B raw_result.rds
  """
}

// Collate results
process collate_results {
  publishDir params.result_dir, mode: 'copy'

  input:
  file 'raw_data' from raw_results_ch.collect()

  output:
  file 'result.rds' into collated_results_ch

  """
  Rscript $projectDir/bin/collate_results.R result.rds raw_data*
  """
}
