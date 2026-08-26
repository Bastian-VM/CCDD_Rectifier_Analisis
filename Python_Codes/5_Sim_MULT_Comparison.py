# ============================================================
# Title: Comparison of Multiple Stages of the CCDDR (PKL version)
# Author: Bastian Veas Moyano
# Last modification: August 16, 2026
#
# Description:
#   Loads combined PKL results of CCDDR simulations,
#   filters valid cases with suffix C01-00 and selects pairs of rectifiers
#   MULT# (greater than 1 together with their MULT1 counterparts).
#   Builds a comparative table with metrics of efficiency, output voltage,
#   input power, maximum VRF, local area, and geometric size.
#   Metrics are normalized to obtain a weighted score and comparative plots
#   of the multiple stages are generated.
#   Single global parameter FONT_SIZE controls all font sizes (keeps ratios).
# ============================================================

import os, re
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# ============================================================
# CONFIGURATION
# ============================================================

# Define Weights
wPCE   = 0.25
wPin   = 0.10
wVout  = 0.45
wVRF   = 0.05
wArea  = 0.10
wSize  = 0.05
print("Sum of weights:", wPCE+wPin+wVout+wVRF+wArea+wSize)

# Working folder setup
folder = r"D:\Memoria_Last\Simulation_Xschem"
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
INCLUDE_FILTERS = ["C01-00", "M20","L00-20", "W00-60"]
EXCLUDE_FILTERS = ["E"]

# Plot style parameters
MARKER = 'o'
LINESTYLE = '-'
LINEWIDTH = 1.6
MARKERSIZE = 5 * (FONT_SIZE / 10.0)
COLOR = 'tab:blue'
GRID_ALPHA = 0.6

# ============================================================
# LOAD COMBINED RESULTS
# ============================================================

filename = os.path.join(py_folder, "all_Results.pkl")
if not os.path.isfile(filename):
    raise FileNotFoundError(f"⚠️ Combined results file not found: {filename}")

allResults = pd.read_pickle(filename)
print(f"Total loaded results: {len(allResults)}")

# ============================================================
# FILTER VALID RESULTS
# ============================================================

def file_matches(filename):
    return (
        filename.lower().endswith(".pkl")
        and all(tag in filename for tag in INCLUDE_FILTERS)
        and all(tag not in filename for tag in EXCLUDE_FILTERS)
    )

allResults = [res for res in allResults if file_matches(res["file"])]
print(f"Total valid results: {len(allResults)}")

# ============================================================
# SELECT MULT# > 1 AND THEIR MULT1 COUNTERPARTS
# ============================================================

multResults = []
for res in allResults:
    fname = res["file"]
    tokensM = re.findall(r"MULT(\d+)", fname)
    if not tokensM: continue
    multNum = int(tokensM[0])
    if multNum > 1:
        multResults.append(res)
        targetName = fname.replace(f"MULT{multNum}", "MULT1")
        match = [r for r in allResults if r["file"] == targetName]
        if match:
            multResults.append(match[0])
            print(f"Found pair: {fname} ↔ {targetName}")
        else:
            print(f"No MULT1 counterpart found for: {fname}")

# Remove duplicates and sort by stages
unique_files = {r["file"]: r for r in multResults}
multResults = list(unique_files.values())
stages = [int(re.findall(r"MULT(\d+)", r["file"])[0]) for r in multResults]
multResults = [r for _,r in sorted(zip(stages,multResults), key=lambda x:x[0])]

# ============================================================
# BUILD COMPARATIVE TABLE
# ============================================================

rows = []
for res in multResults:
    fname = res["file"]
    tokensM = re.findall(r"MULT(\d+)", fname)
    if not tokensM: continue
    stages = int(tokensM[0])

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
    area_local = np.trapezoid(PCE_sorted[mask_range], Pin_sorted[mask_range]) if np.any(mask_range) else 0

    tokensL = re.findall(r"L(\d+)-(\d+)", fname)
    tokensW = re.findall(r"W(\d+)-(\d+)", fname)
    Lval = int(tokensL[0][0]) + int(tokensL[0][1])/100 if tokensL else np.nan
    Wval = int(tokensW[0][0]) + int(tokensW[0][1])/100 if tokensW else np.nan
    Mval = stages
    size_geom = Mval*Lval*Wval

    rows.append([fname, stages, PCE_max, Pin_at_max, Vout_at_max,
                 VRF_at_max, Ratio_at_max, area_local, size_geom])

tablaMultComp = pd.DataFrame(rows, columns=[
    "File","Stages","PCE_max","Pin_dBm","Vout","VRF_at_max",
    "Vout_VRFmax","Area_local","LxWxM"
])

# ============================================================
# NORMALIZATION AND SCORE
# ============================================================

def normalize(series):
    return (series-series.min())/(series.max()-series.min()) if series.max()!=series.min() else series*0

PCE_norm  = normalize(tablaMultComp["PCE_max"])
Pin_norm  = normalize(tablaMultComp["Pin_dBm"])
Vout_norm = normalize(tablaMultComp["Vout"])
VRF_norm  = normalize(tablaMultComp["VRF_at_max"])
Area_norm = normalize(tablaMultComp["Area_local"])
Size_norm = normalize(tablaMultComp["LxWxM"])

Pin_norm_inv  = 1 - Pin_norm
Size_norm_inv = 1 - Size_norm
VRF_norm_inv  = 1 - VRF_norm

score = (wPCE*PCE_norm +
         wPin*Pin_norm_inv +
         wVout*Vout_norm +
         wVRF*VRF_norm_inv +
         wArea*Area_norm +
         wSize*Size_norm_inv)

tablaMultComp["Score"] = score
resultsTable_sorted = tablaMultComp.sort_values("Score", ascending=False)

# ============================================================
# SHOW COMPARATIVE TABLE
# ============================================================

pd.set_option("display.max_rows", None)
pd.set_option("display.max_columns", None)
pd.set_option("display.width", None)
pd.set_option("display.max_colwidth", None)

print("\n================ COMPARATIVE TABLE MULTIPLE STAGES FILES =================")
print(resultsTable_sorted.head(20))

# ============================================================
# BEST DESIGN SELECTION
# ============================================================

if not resultsTable_sorted.empty:
    best_row = resultsTable_sorted.iloc[0]
    best_file = best_row["File"]

    # Extraer dimensiones desde el nombre del archivo
    tokensL    = re.findall(r"L(\d+)-(\d+)", best_file)
    tokensW    = re.findall(r"W(\d+)-(\d+)", best_file)
    tokensM    = re.findall(r"M(\d+)", best_file)          # multiplicidad de transistores
    tokensMULT = re.findall(r"MULT(\d+)", best_file)       # número de etapas
    tokensC    = re.findall(r"C(\d+)-(\d+)", best_file)    # capacitancia de sincronización

    Lval    = int(tokensL[0][0]) + int(tokensL[0][1])/100 if tokensL else None
    Wval    = int(tokensW[0][0]) + int(tokensW[0][1])/100 if tokensW else None
    Mval    = int(tokensM[0]) if tokensM else None
    Stages  = int(tokensMULT[0]) if tokensMULT else None
    Cval    = int(tokensC[0][0]) + int(tokensC[0][1])/100 if tokensC else None

    print("\n================ BEST DESIGN SELECTION =================")
    print(f"File: {best_file}")
    if Lval is not None:    print(f"L = {Lval} µm")
    if Wval is not None:    print(f"W = {Wval} µm")
    if Mval is not None:    print(f"M = {Mval}")
    if Stages is not None:  print(f"Stages = {Stages}")
    if Cval is not None:    print(f"C = {Cval} pF")
    print(f"PCE_max = {best_row['PCE_max']:.3f}")
    print(f"Vout@PCEmax = {best_row['Vout']:.3f} V")
    print(f"Pin@PCEmax = {best_row['Pin_dBm']:.2f} dBm")
    print(f"VRF@PCEmax = {best_row['VRF_at_max']:.3f} V")
    if 'Score' in best_row:
        print(f"Score = {best_row['Score']:.4f}")
else:
    print("No designs found to select best from.")

# -------------------------------
# Comparative metrics vs Stages (4-subplot view)
# -------------------------------

# Plot style parameters (single place to change)
MARKER = 'o'
LINESTYLE = '-'
LINEWIDTH = 1.6
MARKERSIZE = 5 * (FONT_SIZE / 10.0)
COLOR = 'tab:blue'
GRID_ALPHA = 0.6

# Common plotting function to ensure identical format
def plot_vs_stages(ax, x, y, xlabel, ylabel, title):
    ax.plot(x, y, linestyle=LINESTYLE, marker=MARKER,
            color=COLOR, linewidth=LINEWIDTH, markersize=MARKERSIZE)
    ax.set_xlabel(xlabel, fontsize=FONT_SIZE)
    ax.set_ylabel(ylabel, fontsize=FONT_SIZE)
    ax.set_title(title, fontsize=FONT_SIZE)
    ax.grid(True, alpha=GRID_ALPHA)
    ax.tick_params(axis='both', which='major', labelsize=FONT_SIZE * 0.9)

# -------------------------------
# Comparative metrics vs Stages (4-subplot view)
# -------------------------------
tablaMultComp_byStages = tablaMultComp.sort_values("Stages")

fig, axes = plt.subplots(2, 2, figsize=(12, 9))
axes = axes.flatten()

plot_vs_stages(axes[0],
               tablaMultComp_byStages["Stages"],
               tablaMultComp_byStages["PCE_max"],
               "Stages", "PCE_max", "PCE_max vs Stages")

plot_vs_stages(axes[1],
               tablaMultComp_byStages["Stages"],
               tablaMultComp_byStages["Vout"],
               "Stages", "Vout@PCEmax [V]", "Vout vs Stages")

plot_vs_stages(axes[2],
               tablaMultComp_byStages["Stages"],
               tablaMultComp_byStages["Pin_dBm"],
               "Stages", "Pin@PCEmax [dBm]", "Pin vs Stages")

plot_vs_stages(axes[3],
               tablaMultComp_byStages["Stages"],
               tablaMultComp_byStages["VRF_at_max"],
               "Stages", "VRF@PCEmax [V]", "VRF vs Stages")

plt.suptitle("Comparative metrics vs Stages", fontsize=FONT_SIZE * 1.1)
plt.tight_layout(rect=[0, 0.03, 1, 0.96])
plt.show()

