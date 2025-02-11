#!/bin/bash

# Directory containing scripts to run
SCRIPT_DIR=".run"

# Function to run a single script
run_script() {
    local script="$1"
    echo "Running $script..."
    bash "$script"
    if [[ $? -ne 0 ]]; then
        echo "Error: $script failed to execute."
        exit 1
    fi
}

# Single-threaded execution of all scripts in the .run directory
for script in "$SCRIPT_DIR"/*.sh; do
    if [[ -f "$script" ]]; then
        run_script "$script"
    fi
done

# Placeholder for future multithreading (parallel execution)
# Example: Use GNU parallel or background jobs (&) to execute scripts in parallel
# Uncomment and modify the following lines when expanding to multithreaded execution

# for script in "$SCRIPT_DIR"/*.sh; do
#     if [[ -f "$script" ]]; then
#         run_script "$script" &
#     fi
# done
# wait # Wait for all background jobs to finish

echo "All scripts in $SCRIPT_DIR executed."
