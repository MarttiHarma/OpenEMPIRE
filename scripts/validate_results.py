import os
import sys

# Expected files inside the Output/ folder
REQUIRED_FILES = [
    'marginal_costs.csv',
    'results_objective.csv',
    'results_co2_price_resolved.csv',
    'results_output_Operational.csv'
]

# Find the latest timestamped results directory under Results_HPC/
BASE_DIR = os.path.dirname(__file__)
RESULTS_DIR = os.path.abspath(os.path.join(BASE_DIR, '..', 'Results_HPC'))

try:
    # Step 1: Find latest results_<timestamp> folder
    all_subdirs = [os.path.join(RESULTS_DIR, d) for d in os.listdir(RESULTS_DIR)
                   if os.path.isdir(os.path.join(RESULTS_DIR, d)) and d.startswith('results_')]
    if not all_subdirs:
        raise FileNotFoundError("No results_<timestamp> directories found in Results_HPC/")

    latest_result_dir = max(all_subdirs, key=os.path.getmtime)

    print(f"🔍 Looking inside: {latest_result_dir}")

    # Step 2: Go into run_analysis/
    run_analysis_dir = os.path.join(latest_result_dir, 'run_analysis')
    if not os.path.isdir(run_analysis_dir):
        raise FileNotFoundError(f"'run_analysis' folder not found in {latest_result_dir}")

    # Step 3: Find the first job subfolder (there should usually be just one)
    job_folders = [os.path.join(run_analysis_dir, d) for d in os.listdir(run_analysis_dir)
                   if os.path.isdir(os.path.join(run_analysis_dir, d))]

    if not job_folders:
        raise FileNotFoundError(f"No job subdirectories found inside {run_analysis_dir}")

    job_dir = job_folders[0]  # Pick the first job directory
    output_dir = os.path.join(job_dir, 'Output')
    print(f"🔍 Checking output in: {output_dir}")

    if not os.path.isdir(output_dir):
        raise FileNotFoundError(f"❌ Output folder not found in {job_dir}")

    # Step 4: Validate required files
    missing = [f for f in REQUIRED_FILES if not os.path.exists(os.path.join(output_dir, f))]

    if missing:
        print(f"❌ Missing required result files in Output/:")
        for f in missing:
            print(f" - {f}")
        sys.exit(1)

    print("✅ All required result files are present.")
    sys.exit(0)

except Exception as e:
    print(f"❌ Validation error: {e}")
    sys.exit(1)
