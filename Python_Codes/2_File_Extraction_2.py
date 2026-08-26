# ============================================================
# Title: Construction and verification of Pout, Pin, Vout and VRF tables (PKL version)
# Author: Bastian Veas Moyano
# Last modification: August 15, 2026
#
# Description:
#   This script loads PKL files generated from simulation CSVs,
#   calculates average input/output power, output voltage, maximum RF voltage,
#   and conversion efficiency. It then saves combined results and generates
#   verification plots to check the correctness of the conversion process.
# ============================================================

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# ============================================================
# CONFIGURATION
# ============================================================

# Working folder setup
folder = r"D:\Memoria_Last\Simulation_Xschem"
py_folder = os.path.join(folder, "Files_PY")
os.makedirs(py_folder, exist_ok=True)

print(f"\n📂 Working folder: {py_folder}")

# Fundamental period of RF signal
F = 900e6
T = 1 / F

# Extended filters (only for plotting)
PLOT_INCLUDE_FILTERS = ["MULT3","C04-00","M40","L00-20","W00-60","R100k","IMN"]
PLOT_EXCLUDE_FILTERS = ["E"]

# Batch size for grouped plots
BATCH_SIZE = 20

# ============================================================
# SEARCH FOR PKL FILES
# ============================================================

pklFiles = [
    f for f in os.listdir(py_folder)
    if f.endswith(".pkl") and f != "all_Results.pkl"
]

print(f"\n🔍 Found {len(pklFiles)} PKL files (skipping all_Results.pkl)")

# ============================================================
# PROCESS EACH PKL FILE
# ============================================================

allResults = []

for fname in pklFiles:
    print(f"\n📄 Processing PKL: {fname}")
    blocks = pd.read_pickle(os.path.join(py_folder, fname))

    Pin_avg_all, Pout_avg_all, Vout_avg_all, VRF_max_all = [], [], [], []

    for b, block in enumerate(blocks, start=1):
        if not {"time","vrf","irf","vout","ir"}.issubset(block.columns):
            print(f"   ⚠️ Block {b} missing required signals, skipping")
            continue

        time = block["time"].values
        Vrf  = block["vrf"].values
        Irf  = block["irf"].values
        Vout = block["vout"].values
        Ir   = block["ir"].values

        # Select last period
        t_end = np.max(time)
        mask = (time >= t_end - T)
        Vout_T = Vout[mask]
        Vrf_T  = Vrf[mask]

        # Calculations
        Pin_avg_all.append(abs((1/T) * np.trapezoid(Vrf[mask]*Irf[mask], time[mask])))
        Pout_avg_all.append((1/T) * np.trapezoid(Vout[mask]*Ir[mask], time[mask]))
        Vout_avg_all.append(np.mean(Vout_T))
        VRF_max_all.append(round(np.max(np.abs(Vrf_T)), 2))

    # Store results
    result_dict = {
        "file": fname,
        "Pin": np.array(Pin_avg_all),
        "Pout": np.array(Pout_avg_all),
        "Vout": np.array(Vout_avg_all),
        "VRFmax": np.array(VRF_max_all),
        "PCE": np.array(Pout_avg_all) / np.array(Pin_avg_all),
        "Pin_dBm": 10*np.log10(np.array(Pin_avg_all)*1000),
        "Pout_dBm": 10*np.log10(np.array(Pout_avg_all)*1000),
    }
    allResults.append(result_dict)

# Save combined results
out_pickle = os.path.join(py_folder, "all_Results.pkl")
pd.to_pickle(allResults, out_pickle)
print(f"\n💾 Combined results saved to: {out_pickle}")
print(f"\n💾 Processed {len(allResults)} files successfully")

# ============================================================
# FILTER RESULTS FOR PLOTTING
# ============================================================

def file_matches(filename):
    return (
        filename.lower().endswith(".pkl")
        and all(tag in filename for tag in PLOT_INCLUDE_FILTERS)
        and all(tag not in filename for tag in PLOT_EXCLUDE_FILTERS)
    )

plotResults = [res for res in allResults if file_matches(res["file"])]

print(f"\n📊 Plotting {len(plotResults)} filtered files")
for res in plotResults:
    print("   -", res["file"])

# ============================================================
# VERIFICATION PLOTS
# ============================================================

batch_counter = 0

for idx, res in enumerate(plotResults, start=1):
    fname = res["file"]
    print(f"   ✔ Plotting file: {fname} (meets filters)")

    fig, axs = plt.subplots(2,2, figsize=(10,7))
    fig.suptitle(f"Verification: {fname}")

    # Subplot 1: Vout waveform with avg lines
    ax1 = axs[0,0]
    blocks = pd.read_pickle(os.path.join(py_folder, fname))
    for b_idx, block in enumerate(blocks):
        time = block["time"].values
        Vout_wave = block["vout"].values
        Vout_avg = res["Vout"][b_idx]
        ax1.plot(time, Vout_wave, label=f"Block {b_idx+1} Vout(t)")
        ax1.axhline(Vout_avg, color="r", linestyle="--")
    ax1.set_xlabel("Time [s]")
    ax1.set_ylabel("Vout [V]")
    ax1.set_title("Vout waveform (all blocks) with avg lines")
    ax1.grid(True)
    ax1.legend()

    # Subplot 2: Efficiency
    axs[0,1].plot(res["PCE"], "-d", color=(0.2,0.6,0.2))
    axs[0,1].set_xlabel("Block"); axs[0,1].set_ylabel("Efficiency")
    axs[0,1].set_title("Power Conversion Efficiency (PCE)")
    axs[0,1].grid(True)

    # Subplot 3: Powers in dBm
    axs[1,0].plot(res["Pin_dBm"], "-o", label="Pin")
    axs[1,0].plot(res["Pout_dBm"], "-s", label="Pout")
    axs[1,0].set_xlabel("Block"); axs[1,0].set_ylabel("Power [dBm]")
    axs[1,0].set_title("Powers in dBm")
    axs[1,0].legend(); axs[1,0].grid(True)

    # Subplot 4: Vout avg and VRF max
    ax4 = axs[1,1]
    ax4.plot(res["Vout"], "-^", color=(0,0.4,0.8), label="Vout avg")
    ax4.set_ylabel("Average Vout [V]")
    ax4.set_xlabel("Block")
    ax4.set_title("Characteristic voltages")
    ax4.grid(True)
    ax4b = ax4.twinx()
    ax4b.plot(res["VRFmax"], "-v", color=(0.8,0,0), label="VRF max")
    ax4b.set_ylabel("Maximum VRF [V]")
    ax4.legend(loc="upper left")
    ax4b.legend(loc="upper right")

    plt.tight_layout()

    batch_counter += 1
    if batch_counter >= BATCH_SIZE:
        print(f"\n⏸ Showing batch of {BATCH_SIZE} figures... close them to continue.")
        plt.show(block=True)
        batch_counter = 0

if batch_counter > 0:
    print(f"\n⏸ Showing final batch of {batch_counter} figures... close them to finish.")
    plt.show(block=True)
