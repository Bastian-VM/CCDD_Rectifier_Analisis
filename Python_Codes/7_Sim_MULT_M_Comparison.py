# ============================================================
# Title: Comparative analysis of M variations in MULT3 (C04-00, R100k) (PKL version)
# Author: Bastian Veas Moyano
# Last modification: August 16, 2026
#
# Description:
#   Loads combined PKL results of CCDDR simulations for MULT3,
#   filters files with capacitance C04-00 and resistance R100k,
#   builds a comparative table based on multiplier M.
#   Calculates metrics (PCE, Pin, Vout, VRF, area, size),
#   normalizes them with defined weights, and generates plots.
#   Single global parameter FONT_SIZE controls all font sizes (keeps ratios).
# ============================================================

import os, re
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# ============================================================
# CONFIGURATION
# ============================================================

# Weights
wPCE   = 0.35
wPin   = 0.20
wVout  = 0.20
wVRF   = 0.15
wArea  = 0.05
wSize  = 0.05
print("Sum of weights:", wPCE+wPin+wVout+wVRF+wArea+wSize)

# Filters
INCLUDE_FILTERS = ["MULT3","C04-00","R100k","L00-20","W00-60"]
EXCLUDE_FILTERS = ["E","IMN"]

# Working folder
folder = r"D:\Memoria_Last\Simulation_Xschem"
py_folder = os.path.join(folder, "Files_PY")
os.makedirs(py_folder, exist_ok=True)

filename = os.path.join(py_folder, "all_Results.pkl")
if not os.path.isfile(filename):
    raise FileNotFoundError(f"⚠️ Combined results file not found: {filename}")

allResults = pd.read_pickle(filename)
print(f"Total loaded results: {len(allResults)}")

# Font size (single global parameter)
FONT_SIZE = 20
plt.rcParams.update({
    "font.size": FONT_SIZE,
    "axes.titlesize": FONT_SIZE * 1.2,
    "axes.labelsize": FONT_SIZE * 1.0,
    "xtick.labelsize": FONT_SIZE * 0.6,
    "ytick.labelsize": FONT_SIZE * 0.6,
    "legend.fontsize": FONT_SIZE * 0.95,
    "figure.titlesize": FONT_SIZE * 1.2,
    "lines.linewidth": 1.6,
})

# Plot style parameters
MARKER = 'o'
LINESTYLE = '-'
LINEWIDTH = 1.6
MARKERSIZE = 5 * (FONT_SIZE / 10.0)
COLOR = 'tab:blue'
GRID_ALPHA = 0.6

# ============================================================
# FILTER VALID RESULTS
# ============================================================

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
# BUILD COMPARATIVE TABLE
# ============================================================

rows = []
for res in validResults:
    fname = res["file"]
    tokensM = re.findall(r"M(\d+)", fname)
    if not tokensM: continue
    M_val = int(tokensM[0])

    idx_sort = np.argsort(res["Pin_dBm"])
    Pin_sorted = res["Pin_dBm"][idx_sort]
    PCE_sorted = res["PCE"][idx_sort]
    Vout_sorted = res["Vout"][idx_sort]
    VRF_sorted = res["VRFmax"][idx_sort]

    PCE_max = np.max(PCE_sorted)
    idx_max = np.argmax(PCE_sorted)
    Pin_at_max = Pin_sorted[idx_max]
    Vout_at_max = Vout_sorted[idx_max]
    VRF_at_max  = VRF_sorted[idx_max]
    Ratio_at_max = Vout_at_max/VRF_at_max if VRF_at_max!=0 else np.nan

    mask_range = (Pin_sorted >= (Pin_at_max-5)) & (Pin_sorted <= (Pin_at_max+5))
    try: trapz_func = np.trapz
    except AttributeError: trapz_func = np.trapezoid
    area_local = trapz_func(PCE_sorted[mask_range], Pin_sorted[mask_range]) if np.any(mask_range) else 0

    tokensL = re.findall(r"L(\d+)-(\d+)", fname)
    tokensW = re.findall(r"W(\d+)-(\d+)", fname)
    Lval = int(tokensL[0][0]) + int(tokensL[0][1])/100 if tokensL else np.nan
    Wval = int(tokensW[0][0]) + int(tokensW[0][1])/100 if tokensW else np.nan
    size_geom = 3*Lval*Wval*M_val

    rows.append([fname, M_val, PCE_max, Pin_at_max, Vout_at_max,
                 VRF_at_max, Ratio_at_max, area_local, size_geom])

tablaMComp = pd.DataFrame(rows, columns=[
    "File","M","PCE_max","Pin_dBm","Vout","VRF_at_max",
    "Vout_VRFmax","Area_local","LxWxM"
])

# ============================================================
# NORMALIZATION AND SCORE
# ============================================================

def normalize(series):
    return (series-series.min())/(series.max()-series.min()) if series.max()!=series.min() else series*0

PCE_norm  = normalize(tablaMComp["PCE_max"])
Pin_norm  = normalize(tablaMComp["Pin_dBm"])
Vout_norm = normalize(tablaMComp["Vout"])
VRF_norm  = normalize(tablaMComp["VRF_at_max"])
Area_norm = normalize(tablaMComp["Area_local"])
Size_norm = normalize(tablaMComp["LxWxM"])

Pin_norm_inv  = 1 - Pin_norm
Size_norm_inv = 1 - Size_norm
VRF_norm_inv  = 1 - VRF_norm

score = (wPCE*PCE_norm +
         wPin*Pin_norm_inv +
         wVout*Vout_norm +
         wVRF*VRF_norm_inv +
         wArea*Area_norm +
         wSize*Size_norm_inv)

tablaMComp["Score"] = score
tablaMComp_sorted = tablaMComp.sort_values("Score", ascending=False)

# ============================================================
# SHOW COMPARATIVE TABLE
# ============================================================

pd.set_option("display.max_rows", None)
pd.set_option("display.max_columns", None)
pd.set_option("display.width", None)
pd.set_option("display.max_colwidth", None)

print("\n================ COMPARATIVE TABLE MULT3 FILES (C04-00, by M) =================")
print(tablaMComp_sorted.head(20))

# ============================================================
# BEST DESIGN SELECTION
# ============================================================

if not tablaMComp_sorted.empty:
    best_row = tablaMComp_sorted.iloc[0]
    best_file = best_row["File"]

    tokensL = re.findall(r"L(\d+)-(\d+)", best_file)
    tokensW = re.findall(r"W(\d+)-(\d+)", best_file)
    tokensM = re.findall(r"M(\d+)", best_file)
    tokensC = re.findall(r"C(\d+)-(\d+)", best_file)

    Lval = int(tokensL[0][0]) + int(tokensL[0][1])/100 if tokensL else None
    Wval = int(tokensW[0][0]) + int(tokensW[0][1])/100 if tokensW else None
    Mval = int(tokensM[0]) if tokensM else None
    Cval = int(tokensC[0][0]) + int(tokensC[0][1])/100 if tokensC else None

    print("\n================ BEST DESIGN SELECTION =================")
    print(f"File: {best_file}")
    if Lval is not None: print(f"L = {Lval} µm")
    if Wval is not None: print(f"W = {Wval} µm")
    if Mval is not None: print(f"M = {Mval}")
    if Cval is not None: print(f"C = {Cval} pF")
    print(f"PCE_max = {best_row['PCE_max']:.3f}")
    print(f"Vout@PCEmax = {best_row['Vout']:.3f} V")
    print(f"Pin@PCEmax = {best_row['Pin_dBm']:.2f} dBm")
    print(f"VRF@PCEmax = {best_row['VRF_at_max']:.3f} V")
    if 'Score' in best_row:
        print(f"Score = {best_row['Score']:.4f}")
else:
    print("No valid designs found.")

# ============================================================
# METRICS VS M 
# ============================================================

tablaMComp_byM = tablaMComp.sort_values("M")

fig, axes = plt.subplots(2, 2, figsize=(12, 9))
axes = axes.flatten()

# Common plotting function to ensure identical format
def plot_vs_M(ax, x, y, xlabel, ylabel, title, semilog=False):
    if semilog:
        ax.semilogx(x, y, linestyle=LINESTYLE, marker=MARKER,
                    color=COLOR, linewidth=LINEWIDTH, markersize=MARKERSIZE)
    else:
        ax.plot(x, y, linestyle=LINESTYLE, marker=MARKER,
                color=COLOR, linewidth=LINEWIDTH, markersize=MARKERSIZE)
    ax.set_xlabel(xlabel, fontsize=FONT_SIZE)
    ax.set_ylabel(ylabel, fontsize=FONT_SIZE)
    ax.set_title(title, fontsize=FONT_SIZE)
    ax.grid(True, alpha=GRID_ALPHA)
    ax.tick_params(axis='both', which='major', labelsize=FONT_SIZE * 0.9)

# Subplot 1: PCE_max vs M
plot_vs_M(axes[0],
          tablaMComp_byM["M"],
          tablaMComp_byM["PCE_max"],
          "M", "PCE_max", "PCE_max vs M", semilog=False)

# Subplot 2: Vout@PCEmax vs M
plot_vs_M(axes[1],
          tablaMComp_byM["M"],
          tablaMComp_byM["Vout"],
          "M", "Vout@PCEmax [V]", "Vout vs M", semilog=False)

# Subplot 3: Pin@PCEmax vs M
plot_vs_M(axes[2],
          tablaMComp_byM["M"],
          tablaMComp_byM["Pin_dBm"],
          "M", "Pin@PCEmax [dBm]", "Pin vs M", semilog=False)

# Subplot 4: VRF@PCEmax vs M
plot_vs_M(axes[3],
          tablaMComp_byM["M"],
          tablaMComp_byM["VRF_at_max"],
          "M", "VRF@PCEmax [V]", "VRF vs M", semilog=False)

# Shared layout and title
plt.suptitle("Comparison of metrics vs M", fontsize=FONT_SIZE * 1.1)
plt.tight_layout(rect=[0, 0.03, 1, 0.96])
plt.show()
