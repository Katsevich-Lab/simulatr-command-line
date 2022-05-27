// params.sim_obj_fp
// params.metaparam_file
// params.B
// params.result_dir
// params.base_result_name

/*********************
PIPELINE PREPROCESSING
**********************/
// 1. Load metaparams.txt, and put the values into a map
meta_params = [:]
my_file = file(params.metaparam_file)
all_lines = my_file.readLines()
for (line : all_lines) {
    str_split = line.split(':')
    key = str_split[0]
    value = str_split[1]
    if (value.contains('-')) {
      meta_params[key] = value.split('-')
    } else {
      meta_params[key] = [value]
    }
}


// 2. Replicate the wall times (if necessary) so that all arrays are length n_param_settings
n_param_settings = meta_params["n_param_settings"][0].toInteger()
def rep_array(n_param_settings, arr) {
  return (1..(n_param_settings)).collect { arr[0] }
}
if (meta_params["data_generator"].size() == 1) {
  meta_params["data_generator"] = rep_array(n_param_settings, meta_params["data_generator"])
}
meta_params["method_names"].each {
if (meta_params[it].size() == 1) {
  meta_params[it] = rep_array(n_param_settings, meta_params[it])
  }
}

// 1. Generate data
param_idx = (1..(n_param_settings)).collect{ [it, meta_params["data_generator"][it - 1]] }
param_idx_ch = Channel.fromList(param_idx)
process generate_data {
  clusterOptions "-l m_mem_free=${task.attempt * 15}G -o \$HOME/output/\'\$JOB_NAME-\$JOB_ID-\$TASK_ID.log\' "
  errorStrategy { task.exitStatus == 137 ? 'retry' : 'terminate' }
  maxRetries 2

  echo true
  tag "grid row: $i"

  input:
  tuple val(i), val(wall_time) from param_idx_ch

  output:
  tuple val(i), file('data_list_*.rds') into data_ch

  """
  Rscript $projectDir/bin/generate_data.R $params.sim_obj_fp $i $params.B data_list_
  """
}

// 2. Create methods chanel
def my_spread(l) {
  key = l[0]
  vals = l[1]
  return vals.collect {[ key, it ]}
}
def time_lookup(l, metaparams) {
  method_name = l[0]
  i = l[1]
  return metaparams[method_name][i-1]
}
flat_data_ch = data_ch.flatMap{my_spread(it)}
method_names_ch = Channel.of(meta_params["method_names"])
method_cross_data_ch = method_names_ch.combine(flat_data_ch).map {
                       it + time_lookup(it, meta_params)
                       }
method_cross_data_ch.into{method_cross_data_ch_use; method_cross_data_ch_display}
method_cross_data_ch_display.count().view{num -> "**********\nNumber of method processes: $num \n**********"}


// 3. Run methods
process run_methods {
  echo true
  clusterOptions "-l m_mem_free=5G -o \$HOME/output/\'\$JOB_NAME-\$JOB_ID-\$TASK_ID.log\'"
  // + "${if (task.attempt == 1) " -q short.q" else ""}"
  errorStrategy { task.exitStatus == 137 ? 'retry' : 'terminate' }
  maxRetries 1

  tag "method: $method; grid row: $i"
  echo true

  input:
  tuple val(method), val(i), file('data_list.rds'), val(wall_time) from method_cross_data_ch_use

  output:
  file 'raw_result.rds' into raw_results_ch

  """
  Rscript $projectDir/bin/run_methods.R $params.sim_obj_fp data_list.rds $method $params.B raw_result.rds
  """
}


// 4. Collate results; print all files being loaded.
raw_results_ch_collect = raw_results_ch.collect()
raw_results_ch_collect.into{raw_results_ch_collect_use; raw_results_ch_collect_display}
raw_results_ch_collect_display.view{fps -> "\nCombining the following files:\n$fps" }
process collate_results {
  echo true
  // time { 10.m * task.attempt * task.attempt }
  errorStrategy  { task.attempt <= 2  ? 'retry' : 'ignore' }
  publishDir params.result_dir, mode: "copy"

  input:
  file 'raw_result' from raw_results_ch_collect_use

  output:
  file params.base_result_name into collated_results_ch

  """
  Rscript $projectDir/bin/collate_results.R $params.base_result_name raw_result*
  """
}

// 5. Finally, clean up
/*
process cleanup {
  echo true
  time "60s"

  input:
  file params.base_result_name from collated_results_ch

  """
  rm $params.metaparam_file; rm -rf $PWD/.nextflow*
  """
}
*/
