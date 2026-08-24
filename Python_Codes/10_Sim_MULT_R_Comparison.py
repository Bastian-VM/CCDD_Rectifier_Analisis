# ============================================================
# Title: Comparative analysis of resistance variations in MULT3 (C04-00, M40, L00-20) (PKL version)
# Author: Bastian Veas Moyano
# Last modification: August 21, 2026
#
# Description:
#   Loads combined PKL results of CCDDR simulations for MULT3,
#   filters files with capacitance C04-00, multiplier M40, and length L00-20,
#   builds a comparative table based on resistance.
#   Calculates metrics (PCE, Pin, Vout, VRF),
#   and generates uniformly formatted plots using a single FONT_SIZE.
# ============================================================

import os, re
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# ============================================================
# CONFIGURATION
# ============================================================

# Define Weights (if needed for normalization later)
wPCE   = 0.25
wPin   = 0.25
wVout  = 0.25
wVRF   = 0.25
print("Sum of weights:", wPCE+wPin+wVout+wVRF)

# Working folder setup
folder = r"D:\Memoria_Last\Simulaciones_Xschem"
py_folder = os.path.join(folder, "Files_PY")
os.makedirs(py_folder, exist_ok=True)
print(f"\n📂 Working folder: {py_folder}")

# Single global font size parameter (points)
FONT_SIZE = 20
plt.rcParams.update({
    "font.size": FONT_SIZE,
    "axes.titlesize": FONT_SIZE * 1.2,
    "axes.labelsize": FONT_SIZE * 1.0,
    "xtick.labelsize": FONT_SIZE * 0.9,
    "ytick.labelsize": FONT_SIZE * 0.9,
    "legend.fontsize": FONT_SIZE * 0.95,
    "figure.titlesize": FONT_SIZE * 1.2,
    "lines.linewidth": 1.6,
})

# Filters
INCLUDE_FILTERS = ["MULT3","C04-00","M40","W00-60","L00-20"]
EXCLUDE_FILTERS = ["E","IMN"]

# Plot style parameters
MARKER = 'o'
LINESTYLE = '-'
LINEWIDTH = 1.6
MARKERSIZE = 5 * (FONT_SIZE / 10.0)
COLOR = 'tab:blue'
GRID_ALPHA = 0.6

# ============================================================
# LOAD RESULTS AND FILTER
# ============================================================

filename = os.path.join(py_folder, "all_Results.pkl")
if not os.path.isfile(filename):
    raise FileNotFoundError(f"⚠️ Combined results file not found: {filename}")

allResults = pd.read_pickle(filename)
print(f"Total loaded results: {len(allResults)}")

def file_matches(filename):
    return (
        filename.lower().endswith(".pkl")
        and all(tag in filename for tag in INCLUDE_FILTERS)
        and all(tag not in filename for tag in EXCLUDE_FILTERS)
    )

validResults = [res for res in allResults if file_matches(res["file"])]
print(f"Selected files: {len(validResults)}")
for res in validResults:
    print("   -", res["file"])

# ============================================================
# EXTRACT RESISTANCES AND BUILD TABLE
# ============================================================

Rvals, labels, rows = [], [], []
for res in validResults:
    fname = res["file"]
    tokens = re.findall(r"R(\d+)([kM]?)", fname)
    if tokens:
        baseVal = int(tokens[0][0])
        suffix  = tokens[0][1]
        if suffix == "k":
            Rval = baseVal * 1e3
            label = f"R = {baseVal}kΩ"
        elif suffix == "M":
            Rval = baseVal * 1e6
            label = f"R = {baseVal}MΩ"
        else:
            Rval = baseVal
            label = f"R = {baseVal}Ω"
    else:
        Rval, label = np.nan, "Unknown R"

    Rvals.append(Rval)
    labels.append(label)

# Sort by resistance
idxSort = np.argsort(Rvals)
Rvals_sorted = np.array(Rvals)[idxSort]
labels_sorted = np.array(labels)[idxSort]
validResults_sorted = [validResults[i] for i in idxSort]

# Calculate metrics at max efficiency
for i, res in enumerate(validResults_sorted):
    idx_sort = np.argsort(res["Pin_dBm"])
    Pin_sorted = np.asarray(res["Pin_dBm"], dtype=float)[idx_sort]
    PCE_sorted = np.asarray(res["PCE"], dtype=float)[idx_sort]
    Vout_sorted = np.asarray(res["Vout"], dtype=float)[idx_sort]
    VRF_sorted = np.asarray(res["VRFmax"], dtype=float)[idx_sort]

    idx_max = int(np.nanargmax(PCE_sorted))
    PCE_max = PCE_sorted[idx_max]
    Vout_at_max = Vout_sorted[idx_max]
    VRF_at_max  = VRF_sorted[idx_max]
    Pin_at_max  = Pin_sorted[idx_max]

    rows.append([labels_sorted[i], Rvals_sorted[i], PCE_max, Pin_at_max, Vout_at_max, VRF_at_max])

tablaRComp = pd.DataFrame(rows, columns=[
    "File", "Resistance", "PCE_max", "Pin_dBm", "Vout", "VRF_at_max"
])

# ============================================================
# SHOW COMPARATIVE TABLE
# ============================================================

pd.set_option("display.max_rows", None)
pd.set_option("display.max_columns", None)
pd.set_option("display.width", None)
pd.set_option("display.max_colwidth", None)

print("\n================ COMPARATIVE TABLE MULT3 FILES (C04-00, M40, L00-20, by Resistance) =================")
print(tablaRComp)

# ============================================================
# PLOTS
# ============================================================

COLORS = plt.cm.tab10(np.linspace(0, 1, max(1, len(validResults_sorted))))

def annotate_point(ax, x, y, text, fontsize=FONT_SIZE * 0.85, dy=0.03):
    ax.text(x, y + dy, text, color='r', fontsize=fontsize, ha='center')

def plot_resistance(ax, x, y, marker, color, xlabel, ylabel, title, semilog=True):
    if semilog:
        ax.semilogx(x, y, linestyle=LINESTYLE, marker=marker,
                    color=color, linewidth=LINEWIDTH, markersize=MARKERSIZE)
    else:
        ax.plot(x, y, linestyle=LINESTYLE, marker=marker,
                color=color, linewidth=LINEWIDTH, markersize=MARKERSIZE)
    ax.set_xlabel(xlabel, fontsize=FONT_SIZE)
    ax.set_ylabel(ylabel, fontsize=FONT_SIZE)
    ax.set_title(title, fontsize=FONT_SIZE)
    ax.grid(True, alpha=GRID_ALPHA)
    ax.tick_params(axis='both', which='major', labelsize=FONT_SIZE * 0.9)

# Figure 1: PCE vs Pin
fig1, ax1 = plt.subplots(figsize=(9, 6))
for i, res in enumerate(validResults_sorted):
    idx_sort = np.argsort(res["Pin_dBm"])
    Pin_sorted = np.asarray(res["Pin_dBm"], dtype=float)[idx_sort]
    PCE_sorted = np.asarray(res["PCE"], dtype=float)[idx_sort]
    VRF_sorted = np.asarray(res["VRFmax"], dtype=float)[idx_sort]

    ax1.plot(Pin_sorted, PCE_sorted, linestyle=LINESTYLE, marker='o',
             color=COLORS[i % len(COLORS)], linewidth=LINEWIDTH, markersize=MARKERSIZE,
             label=labels_sorted[i])
    idx_max = int(np.nanargmax(PCE_sorted))
    ax1.plot(Pin_sorted[idx_max], PCE_sorted[idx_max], 'o', color='k', markersize=MARKERSIZE * 1.2)
    annotate_point(ax1, Pin_sorted[idx_max], PCE_sorted[idx_max],
                   f"VRF={VRF_sorted[idx_max]:.2f} V", dy=0.03)

ax1.set_xlabel("Pin [dBm]", fontsize=FONT_SIZE)
ax1.set_ylabel("PCE", fontsize=FONT_SIZE)
ax1.set_title("PCE vs Pin", fontsize=FONT_SIZE)
ax1.grid(True, alpha=GRID_ALPHA)
ax1.legend(loc='best', fontsize=FONT_SIZE * 0.85)
ax1.set_ylim(bottom=0)

# Figure 2: Vout vs Pin
fig2, ax2 = plt.subplots(figsize=(9, 6))
for i, res in enumerate(validResults_sorted):
    idx_sort = np.argsort(res["Pin_dBm"])
    Pin_sorted = np.asarray(res["Pin_dBm"], dtype=float)[idx_sort]
    Vout_sorted = np.asarray(res["Vout"], dtype=float)[idx_sort]
    VRF_sorted = np.asarray(res["VRFmax"], dtype=float)[idx_sort]

    ax2.plot(Pin_sorted, Vout_sorted, linestyle=LINESTYLE, marker='s',
             color=COLORS[i % len(COLORS)], linewidth=LINEWIDTH, markersize=MARKERSIZE,
             label=labels_sorted[i])
    idx_max = int(np.nanargmax(np.asarray(res["PCE"], dtype=float)))
    ax2.plot(Pin_sorted[idx_max], Vout_sorted[idx_max], 'o', color='k', markersize=MARKERSIZE * 1.2)
    annotate_point(ax2, Pin_sorted[idx_max], Vout_sorted[idx_max],
                   f"VRF={VRF_sorted[idx_max]:.2f} V", dy=0.05)

ax2.axhline(1, color='k', linestyle='--', linewidth=0.9)
ax2.set_xlabel("Pin [dBm]", fontsize=FONT_SIZE)
ax2.set_ylabel("Vout [V]", fontsize=FONT_SIZE)
ax2.set_title("Vout vs Pin", fontsize=FONT_SIZE)
ax2.grid(True, alpha=GRID_ALPHA)
ax2.legend(loc='best', fontsize=FONT_SIZE * 0.85)

# Figure 3: Vout/VRFmax vs Pin
fig3, ax3 = plt.subplots(figsize=(9, 6))
for i, res in enumerate(validResults_sorted):
    idx_sort = np.argsort(res["Pin_dBm"])
    Pin_sorted = np.asarray(res["Pin_dBm"], dtype=float)[idx_sort]
    Vout_sorted = np.asarray(res["Vout"], dtype=float)[idx_sort]
    VRF_sorted = np.asarray(res["VRFmax"], dtype=float)[idx_sort]
    with np.errstate(divide='ignore', invalid='ignore'):
        Ratio_sorted = np.where(VRF_sorted != 0, Vout_sorted / VRF_sorted, np.nan)

    ax3.plot(Pin_sorted, Ratio_sorted, linestyle=LINESTYLE, marker='^',
             color=COLORS[i % len(COLORS)], linewidth=LINEWIDTH, markersize=MARKERSIZE,
             label=labels_sorted[i])
    idx_max = int(np.nanargmax(np.asarray(res["PCE"], dtype=float)))
    ax3.plot(Pin_sorted[idx_max], Ratio_sorted[idx_max], 'o', color='k', markersize=MARKERSIZE * 1.2)
    annotate_point(ax3, Pin_sorted[idx_max], Ratio_sorted[idx_max],
                   f"VRF={VRF_sorted[idx_max]:.2f} V", dy=0.05)

ax3.set_xlabel("Pin [dBm]", fontsize=FONT_SIZE)
ax3.set_ylabel("Vout / VRFmax", fontsize=FONT_SIZE)
ax3.set_title("Vout/VRFmax vs Pin", fontsize=FONT_SIZE)
ax3.grid(True, alpha=GRID_ALPHA)
ax3.legend(loc='best', fontsize=FONT_SIZE * 0.85)

# Figure 4: Comparative subplots vs Resistance
fig4, axes = plt.subplots(2, 2, figsize=(12, 9))
axes = axes.flatten()

plot_resistance(axes[0], Rvals_sorted, tablaRComp["Pin_dBm"],
                marker='o', color='tab:blue',
                xlabel="Resistance [Ω]", ylabel="Pin@PCEmax [dBm]",
                title="Pin vs Resistance", semilog=True)

plot_resistance(axes[1], Rvals_sorted, tablaRComp["Vout"],
                marker='s', color='tab:purple',
                xlabel="Resistance [Ω]", ylabel="Vout@PCEmax [V]",
                title="Vout vs Resistance", semilog=True)

plot_resistance(axes[2], Rvals_sorted, tablaRComp["PCE_max"],
                marker='^', color='tab:green',
                xlabel="Resistance [Ω]", ylabel="PCE_max",
                title="Efficiency vs Resistance", semilog=True)

plot_resistance(axes[3], Rvals_sorted, tablaRComp["VRF_at_max"],
                marker='d', color='tab:red',
                xlabel="Resistance [Ω]", ylabel="VRF@PCEmax [V]",
                title="VRF vs Resistance", semilog=True)

plt.suptitle("Comparison of key metrics vs Resistance (MULT3, C04-00, M40, L00-20)", fontsize=FONT_SIZE * 1.05)
plt.tight_layout(rect=[0, 0.03, 1, 0.96])

# Show all figures
plt.show()
