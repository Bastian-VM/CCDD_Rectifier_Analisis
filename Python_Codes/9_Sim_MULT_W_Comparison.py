# ============================================================
# Title: Comparative analysis of W variations in MULT3 (C04-00, R100k, M40, L00-20) (PKL version)
# Author: Bastian Veas Moyano
# Last modification: August 21, 2026
#
# Description:
#   Loads combined PKL results of CCDDR simulations for MULT3,
#   filters files with capacitance C04-00, resistance R100k, multiplier M40,
#   and L00-20. Builds a comparative table based on width W.
#   Calculates metrics (PCE, Pin, Vout, VRF, area, size),
#   normalizes them with defined weights, and generates uniformly formatted plots.
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
wPCE   = 0.40
wPin   = 0.25
wVout  = 0.25
wVRF   = 0.0
wArea  = 0.05
wSize  = 0.05
print("Sum of weights:", wPCE + wPin + wVout + wVRF + wArea + wSize)

# Working folder
folder = r"D:\Memoria_Last\Simulation_Xschem"
py_folder = os.path.join(folder, "Files_PY")
os.makedirs(py_folder, exist_ok=True)

filename = os.path.join(py_folder, "all_Results.pkl")
if not os.path.isfile(filename):
    raise FileNotFoundError(f"⚠️ Combined results file not found: {filename}")

allResults = pd.read_pickle(filename)
print(f"Total loaded results: {len(allResults)}")

# Filters
INCLUDE_FILTERS = ["MULT3","C04-00","R100k","M40","L00-20"]
EXCLUDE_FILTERS = ["E","IMN"]

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
# BUILD COMPARATIVE TABLE
# ============================================================

rows = []
for res in validResults:
    fname = res["file"]
    tokensW = re.findall(r"W(\d+)-(\d+)", fname)
    if not tokensW: continue
    Wval = int(tokensW[0][0]) + int(tokensW[0][1]) / 100.0

    idx_sort = np.argsort(res["Pin_dBm"])
    Pin_sorted = np.asarray(res["Pin_dBm"], dtype=float)[idx_sort]
    PCE_sorted = np.asarray(res["PCE"], dtype=float)[idx_sort]
    Vout_sorted = np.asarray(res["Vout"], dtype=float)[idx_sort]
    VRF_sorted = np.asarray(res["VRFmax"], dtype=float)[idx_sort]

    PCE_max = np.nanmax(PCE_sorted)
    idx_max = int(np.nanargmax(PCE_sorted))
    Pin_at_max = Pin_sorted[idx_max]
    Vout_at_max = Vout_sorted[idx_max]
    VRF_at_max = VRF_sorted[idx_max]
    Ratio_at_max = Vout_at_max / VRF_at_max if VRF_at_max != 0 else np.nan

    mask_range = (Pin_sorted >= (Pin_at_max - 5)) & (Pin_sorted <= (Pin_at_max + 5))
    try: area_local = np.trapz(PCE_sorted[mask_range], Pin_sorted[mask_range]) if np.any(mask_range) else 0.0
    except Exception: area_local = 0.0

    tokensL = re.findall(r"L(\d+)-(\d+)", fname)
    tokensM = re.findall(r"M(\d+)", fname)
    Lval = int(tokensL[0][0]) + int(tokensL[0][1]) / 100.0 if tokensL else np.nan
    Mval = int(tokensM[0]) if tokensM else np.nan
    size_geom = Lval * Wval * Mval

    rows.append([fname, Wval, Lval, Mval, PCE_max, Pin_at_max, Vout_at_max,
                 VRF_at_max, Ratio_at_max, area_local, size_geom])

tablaWComp = pd.DataFrame(rows, columns=[
    "File","W","L","M","PCE_max","Pin_dBm","Vout","VRF_at_max",
    "Vout_VRFmax","Area_local","LxWxM"
])

# ============================================================
# NORMALIZATION AND SCORE
# ============================================================

def normalize(series):
    if series.dtype == object: series = series.astype(float)
    if series.max() == series.min(): return np.zeros_like(series, dtype=float)
    return (series - series.min()) / (series.max() - series.min())

PCE_norm  = normalize(tablaWComp["PCE_max"])
Pin_norm  = normalize(tablaWComp["Pin_dBm"])
Vout_norm = normalize(tablaWComp["Vout"])
VRF_norm  = normalize(tablaWComp["VRF_at_max"])
Area_norm = normalize(tablaWComp["Area_local"])
Size_norm = normalize(tablaWComp["LxWxM"])

Pin_norm_inv  = 1.0 - Pin_norm
Size_norm_inv = 1.0 - Size_norm
VRF_norm_inv  = 1.0 - VRF_norm

score = (wPCE * PCE_norm +
         wPin * Pin_norm_inv +
         wVout * Vout_norm +
         wVRF * VRF_norm_inv +
         wArea * Area_norm +
         wSize * Size_norm_inv)

tablaWComp["Score"] = score
tablaWComp_sorted = tablaWComp.sort_values("Score", ascending=False).reset_index(drop=True)

# ============================================================
# SHOW COMPARATIVE TABLE
# ============================================================

pd.set_option("display.max_rows", None)
pd.set_option("display.max_columns", None)
pd.set_option("display.width", None)
pd.set_option("display.max_colwidth", None)

print("\n================ COMPARATIVE TABLE MULT3 FILES (C04-00, by W, M40, L00-20) =================")
print(tablaWComp_sorted.head(20))

# ============================================================
# METRICS VS W (CONSISTENT FORMATTING)
# ============================================================

tablaWComp_byW = tablaWComp.sort_values("W").reset_index(drop=True)

fig, axes = plt.subplots(2, 2, figsize=(12, 9))
axes = axes.flatten()

def plot_uniform(ax, x, y, xlabel, ylabel, title, semilog=False):
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

# Subplot 1: PCE_max vs W
plot_uniform(axes[0], tablaWComp_byW["W"], tablaWComp_byW["PCE_max"],
             "W [µm]", "PCE_max", "PCE_max vs W", semilog=False)

# Subplot 2: Vout@PCEmax vs W
plot_uniform(axes[1], tablaWComp_byW["W"], tablaWComp_byW["Vout"],
             "W [µm]", "Vout@PCEmax [V]", "Vout vs W", semilog=False)

# Subplot 3: Pin@PCEmax vs W
plot_uniform(axes[2], tablaWComp_byW["W"], tablaWComp_byW["Pin_dBm"],
             "W [µm]", "Pin@PCEmax [dBm]", "Pin vs W", semilog=False)

# Subplot 4: VRF@PCEmax vs W
plot_uniform(axes[3],
             tablaWComp_byW["W"],
             tablaWComp_byW["VRF_at_max"],
             "W [µm]", "VRF@PCEmax [V]", "VRF vs W", semilog=False)

# Shared layout and title
plt.suptitle("Comparison of metrics vs W", fontsize=FONT_SIZE * 1.1)
plt.tight_layout(rect=[0, 0.03, 1, 0.96])
plt.show()

# ============================================================
# BEST DESIGN SELECTION
# ============================================================

if not tablaWComp_sorted.empty:
    best_row = tablaWComp_sorted.iloc[0]
    best_file = best_row["File"]

    tokensL = re.findall(r"L(\d+)-(\d+)", best_file)
    tokensW = re.findall(r"W(\d+)-(\d+)", best_file)
    tokensM = re.findall(r"M(\d+)", best_file)
    tokensC = re.findall(r"C(\d+)-(\d+)", best_file)

    Lval = int(tokensL[0][0]) + int(tokensL[0][1]) / 100.0 if tokensL else None
    Wval = int(tokensW[0][0]) + int(tokensW[0][1]) / 100.0 if tokensW else None
    Mval = int(tokensM[0]) if tokensM else None
    Cval = int(tokensC[0][0]) + int(tokensC[0][1]) / 100.0 if tokensC else None

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

