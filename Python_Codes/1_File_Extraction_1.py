# ============================================================
# FAST + LOW-MEMORY XSCHEM / NGSPICE CSV PROCESSOR
# ============================================================
#
# Author: Bastian Veas Moyano
# Date  : August 16, 2026
#
# Objective:
#   Efficiently process large Xschem CSV files without loading
#   the entire file into memory. Each CSV is split into blocks
#   and stored as a list of DataFrames in a .pkl file.
#
# Output:
#   One .pkl file per CSV containing:
#       [
#           DataFrame_block_1,
#           DataFrame_block_2,
#           ...
#       ]
# ============================================================

import os
import csv
import time
import multiprocessing
from concurrent.futures import ProcessPoolExecutor, as_completed

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# ============================================================
# CONFIGURATION
# ============================================================

# Folder root
folder = r"D:\Memoria_Last\Simulaction_Xschem"
csv_folder = os.path.join(folder, "Simulations_CSV")
py_folder = os.path.join(folder, "Files_PY")
os.makedirs(py_folder, exist_ok=True)

# Tags that must be present
INCLUDE_FILTERS = ["C04-00","M40","L00-20","W00-60","IMN"]

# Tags that must NOT be present
EXCLUDE_FILTERS = ["MULT1"]

# Enable plotting after processing?
PLOT_RESULTS = True

# Number of parallel workers (adjust based on RAM)
MAX_WORKERS = 2

# ============================================================
# INITIALIZATION
# ============================================================

print("\n📂 Project folders initialized")
print(f"   Base folder     : {folder}")
print(f"   CSV input folder: {csv_folder}")
print(f"   Output folder   : {py_folder}")

print("\n⚙️ Processing configuration")
print(f"   CPU cores       : {multiprocessing.cpu_count()}")
print(f"   Parallel workers: {MAX_WORKERS}")

# ============================================================
# FILE FILTER
# ============================================================

def file_matches(filename):
    return (
        filename.lower().endswith(".csv")
        and all(tag in filename for tag in INCLUDE_FILTERS)
        and all(tag not in filename for tag in EXCLUDE_FILTERS)
    )

file_list = sorted(
    f for f in os.listdir(csv_folder) if file_matches(f)
)

print("\n📂 Selected files:")
for fname in file_list:
    print("   -", fname)
print(f"\n   Total files selected: {len(file_list)}")

if not file_list:
    print("\n⚠️ No files matched the filters.")
    raise SystemExit

# ============================================================
# HELPER FUNCTIONS
# ============================================================

def get_last_field(row):
    """Return the last field of a CSV row (trimmed)."""
    if not row:
        return ""
    return row[-1].strip()

# ============================================================
# PROCESS SINGLE CSV
# ============================================================

def process_csv(filename):
    """Process one CSV file into blocks of DataFrames."""
    t0 = time.perf_counter()
    fullpath = os.path.join(csv_folder, filename)

    try:
        # ----------------------------------------------------
        # PASS 1: Extract metadata (NoVar, NoVal, var_names)
        # ----------------------------------------------------
        NoVar, NoVal, var_names = None, None, []
        found_variables, variable_count = False, 0

        with open(fullpath, "r", newline="", encoding="utf-8", errors="ignore") as f:
            reader = csv.reader(f)
            for row in reader:
                if not row: continue
                line = get_last_field(row)

                if line.startswith("No. Variables:") and NoVar is None:
                    try: NoVar = int(line.split(":", 1)[1].strip())
                    except ValueError: pass

                elif line.startswith("No. Points:") and NoVal is None:
                    try: NoVal = int(line.split(":", 1)[1].strip())
                    except ValueError: pass

                elif line == "Variables:":
                    found_variables, variable_count = True, 0

                elif found_variables and NoVar and variable_count < NoVar:
                    parts = line.split("\t")
                    name = parts[-2].strip() if len(parts) >= 2 else parts[-1].strip()
                    if "(" in name and ")" in name:
                        name = name[name.find("(")+1:name.find(")")]
                    var_names.append(name.lower())
                    variable_count += 1
                    if variable_count >= NoVar:
                        found_variables = False

                if NoVar and NoVal and len(var_names) == NoVar:
                    break

        # Validation
        if NoVar is None: return {"filename": filename, "success": False, "error": "No. Variables not found"}
        if NoVal is None: return {"filename": filename, "success": False, "error": "No. Points not found"}
        if len(var_names) != NoVar: return {"filename": filename, "success": False, "error": f"Expected {NoVar} variables, found {len(var_names)}"}

        # ----------------------------------------------------
        # PASS 2: Stream numerical values into blocks
        # ----------------------------------------------------
        blocks, current_block, current_index, block_number = [], None, 0, 0
        expected_values = NoVar * NoVal

        with open(fullpath, "r", newline="", encoding="utf-8", errors="ignore") as f:
            reader = csv.reader(f)
            for row in reader:
                if not row: continue
                line = get_last_field(row)

                # New block marker
                if line == "Values:":
                    if current_block is not None:
                        usable = (current_index // NoVar) * NoVar
                        if usable > 0:
                            block_array = current_block[:usable].reshape(-1, NoVar)
                            blocks.append(pd.DataFrame(block_array, columns=var_names))
                    block_number += 1
                    current_block = np.empty(expected_values, dtype=np.float64)
                    current_index = 0
                    continue

                # Numerical value
                if current_block is None: continue
                try:
                    token = line.rsplit("\t", 1)[-1].strip()
                    value = float(token)
                except (ValueError, IndexError):
                    continue
                if current_index < expected_values:
                    current_block[current_index] = value
                    current_index += 1

            # Finish last block
            if current_block is not None:
                usable = (current_index // NoVar) * NoVar
                if usable > 0:
                    block_array = current_block[:usable].reshape(-1, NoVar)
                    blocks.append(pd.DataFrame(block_array, columns=var_names))

        # ----------------------------------------------------
        # SAVE PICKLE
        # ----------------------------------------------------
        output_file = os.path.join(py_folder, os.path.splitext(filename)[0] + ".pkl")
        pd.to_pickle(blocks, output_file)

        elapsed = time.perf_counter() - t0
        return {"filename": filename, "success": True, "blocks": len(blocks), "variables": NoVar, "points": NoVal, "elapsed": elapsed, "output": output_file}

    except Exception as e:
        return {"filename": filename, "success": False, "error": repr(e)}

# ============================================================
# MAIN EXECUTION
# ============================================================

if __name__ == "__main__":
    print("\n🚀 Starting low-memory parallel processing...")
    total_start = time.perf_counter()
    completed, successful, failed = 0, [], []

    # ----------------------------------------------------
    # Parallel processing
    # ----------------------------------------------------
    with ProcessPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(process_csv, fname): fname for fname in file_list}
        for future in as_completed(futures):
            fname, result = futures[future], future.result()
            completed += 1

            if result["success"]:
                successful.append(result)
                print(f"\n✅ [{completed}/{len(file_list)}] {fname}")
                print(f"   Blocks    : {result['blocks']}")
                print(f"   Variables : {result['variables']}")
                print(f"   Points    : {result['points']}")
                print(f"   Time      : {result['elapsed']:.2f} s")
            else:
                failed.append(result)
                print(f"\n❌ [{completed}/{len(file_list)}] {fname}")
                print(f"   Error: {result['error']}")

    # ----------------------------------------------------
    # Summary
    # ----------------------------------------------------
    total_elapsed = time.perf_counter() - total_start
    print("\n" + "="*65)
    print("PROCESSING COMPLETE")
    print("="*65)
    print(f"Files selected   : {len(file_list)}")
    print(f"Successful       : {len(successful)}")
    print(f"Failed           : {len(failed)}")
    print(f"Total time       : {total_elapsed:.2f} s")
    if successful:
        avg = np.mean([x["elapsed"] for x in successful])
        print(f"Average file     : {avg:.2f} s")
    if failed:
        print("\n❌ Failed files:")
        for r in failed:
            print(f"   - {r['filename']}")
            print(f"     {r['error']}")

    # ----------------------------------------------------
    # OPTIONAL PLOTS
    # ----------------------------------------------------

    if PLOT_RESULTS:
        print("\n📈 Generating plots...")

        # Loop through all successfully processed files
        for result in successful:
            fname = result["filename"]
            pkl_file = result["output"]

            # Load the list of DataFrame blocks from the pickle
            blocks = pd.read_pickle(pkl_file)

            plt.figure(figsize=(8, 5))
            plotted = False

            # Plot Vout vs Time for each block
            for i, block in enumerate(blocks, start=1):
                if "time" in block.columns and "vout" in block.columns:
                    plt.plot(
                        block["time"].to_numpy(),
                        block["vout"].to_numpy(),
                        label=f"Block {i}"
                    )
                    plotted = True

            # Only finalize the plot if at least one block had time/vout
            if plotted:
                plt.xlabel("Time")
                plt.ylabel("Vout")
                plt.title(f"Vout vs Time\n{fname}")
                plt.grid(True)
                plt.legend()
                plt.tight_layout()
                plt.show(block=False)

        # Final show to render all figures
        plt.show()
