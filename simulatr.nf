// define pipline input parameters
params.simulatr_obj = "~/research_code/simulatr-project/ex_sim_obj.rds"
params.meta_params = "metaparams.txt"

// put the metaparams into a map
meta_params = [:]
my_file = file(params.meta_params)
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

/*************
Generate data
*************/
n_param_settings = meta_params["n_param_settings"].toInteger()
param_idx_ch = Channel.of(1..n_param_settings)
process generate_data {
  input:
  val i from param_idx_ch

  output:
  file 'data_list_*.rds' into data_ch

  """
  Rscript $PWD/Rscripts/generate_data.R $params.simulatr_obj $i data_list_
  """
}

/**********
Run methods
***********/
method_ch = Channel.of(meta_params["method_names"])
method_times_data_ch = method_ch.combine(data_ch.flatten())
process run_methods {
  input:
  tuple val(method), file('data_list.rds') from method_times_data_ch

  output:
  file 'raw_result.rds' into raw_results_ch

  """
  Rscript $PWD/Rscripts/run_methods.R $params.simulatr_obj data_list.rds $method raw_result.rds
  """
}

/**************
Collate results
***************/
process collate_results {
  publishDir "$baseDir/results"

  input:
  file 'raw_data' from raw_results_ch.collect()

  output:
  file 'result.rds' into collated_results_ch

  """
  Rscript $PWD/Rscripts/collate_results.R result.rds raw_data*
  """
}
