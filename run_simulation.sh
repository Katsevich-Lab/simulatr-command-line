#!/bin/bash

# Take fp to simulatr_obj as command line arg
simulatr_obj_fp=$1

# obtain the metaparam_file
metaparam_file=$PWD/".metaparams.txt"
Rscript $PWD"/bin/get_meta_params.R" $simulatr_obj_fp $metaparam_file

# run the nextflow script
nextflow $PWD/"simulatr.nf" --simulatr_obj $simulatr_obj_fp --metaparams_fp $metaparam_file

# Clean up
rm -r .nextflow*
rm $metaparam_file
