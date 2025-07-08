#!/bin/bash
# This script will now serve as a job launcher

# Check if empire_env is the active environment
if [[ "$CONDA_DEFAULT_ENV" != "empire_env" ]]; then
    # Check if empire_env exists among the installed environments
    conda info --envs | grep -q "empire_env"
    if [ $? -eq 0 ]; then
        echo "environment exists"      #"Activating existing conda environment: empire_env"
        # source ~/miniconda3/bin/activate empire_env
    else
        echo "Creating new conda environment: empire_env"
        conda env create -f ./environment.yml
        source ~/miniconda3/bin/activate empire_env
        conda install -c gurobi gurobi -y
    fi
fi


# Values for the arguments
NUCLEAR_CAPITAL_COSTS=("8000")    #("3000" "4000" "5000" "6000" "7000")
NUCLEAR_AVAILABILITIES=("0.95")    #("0.75")
MAX_WINDS=("200000") #("0") 
PROTECTIVE=("true")  #("false")

mkdir -p ./hpc_output/

# Submit a job for each set of parameter values
for ncc in "${NUCLEAR_CAPITAL_COSTS[@]}"; do
    for na in "${NUCLEAR_AVAILABILITIES[@]}"; do
        for w in "${MAX_WINDS[@]}"; do
            for p in "${PROTECTIVE[@]}"; do
                qsub \
                    -V \
                    -cwd \
                    -N empire_model_${ncc}_${na}_${w}_${p} \
                    -o ./hpc_output/ \
                    -e ./hpc_output/\
                    -l h_rt=12:00:00 \
                    -l mem_free=150G \
                    -l hostname="compute-4-51|compute-4-52|compute-4-54|compute-4-55|compute-4-56"\
                    -pe smp 8 \
                    ./scripts/run_analysis_sge_worker.sh $ncc $na $w $p
            done
        done
    done
done

