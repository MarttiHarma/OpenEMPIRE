#!/bin/bash
# This script submits a single test job

# Define parameter values
ncc="4000"
na="0.95"
w="200000"
p="true"
AVAILABLE_NODES=$(./scripts/filter_idle_hosts.sh "compute-4-50|compute-4-51|compute-4-52|compute-4-53|compute-4-54|compute-4-55|compute-4-56|compute-4-57|compute-4-58")

mkdir -p ./hpc_output/

# Submit a single job
qsub \
    -V \
    -cwd \
    -N ensolve_run${ncc}_${na}_${w}_${p} \
    -o ./hpc_output/ \
    -e ./hpc_output/ \
    -l h_rt=12:00:00 \
    -l mem_free=150G \
    -l hostname="$AVAILABLE_NODES" \
    -pe smp 8 \
    ./scripts/ensolve_worker.sh $ncc $na $w $p
