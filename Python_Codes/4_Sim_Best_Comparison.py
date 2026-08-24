# ============================================================
# Title: Selection and weighted analysis of the 20 best CCDDR curves (PKL version)
# Author: Bastian Veas Moyano
# Last modification: August 16, 2026
#
# Description:
#   Loads combined PKL results of CCDDR simulations,
#   filters valid cases (only MULT1, excluding files ending in E,
#   excluding suffix _C##-##), selects the 20 curves with the highest
#   conversion efficiency (PCE), and generates comparative plots.
#   Builds tables with metrics and a weighted version that considers
#   efficiency, input power, output voltage, local area, and geometric
#   size to rank the best designs.
# ============================================================

import os, re
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# ============================================================
# CONFIGURATION
# ============================================================

# Define Weights
wPCE   = 0.40
wPin   = 0.30
wVout  = 0.10
wArea  = 0.10
wSize  = 0.00
wVRF   = 0.10

print("Sum of weights:", wPCE+wPin+wVout+wArea+wSize+wVRF)

# Working folder setup
folder = r"D:\Memoria_Last\Simulaciones_Xschem"
py_folder = os.path.join(folder, "Files_PY")
os.makedirs(py_folder, exist_ok=True)
print(f"\n📂 Working folder: {py_folder}")

# Filters
INCLUDE_FILTERS = ["MULT1","C01-00"]
EXCLUDE_FILTERS = ["E"]

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

validResults = [res for res in allResults if file_matches(res["file"])]

print(f"Total valid results: {len(validResults)}")
print("Selected archives after filtering:")
for res in validResults:
    print("   -", res["file"])

# ============================================================
# SELECT TOP 20 CURVES BY MAXIMUM PCE
# ============================================================

maxPCE, validMask = [], []
for res in validResults:
    idx_sort = np.argsort(res["Pin_dBm"])
    Pin_sorted = res["Pin_dBm"][idx_sort]
    PCE_sorted = res["PCE"][idx_sort]
    VRF_sorted = res["VRFmax"][idx_sort]

    if len(PCE_sorted) > 0:
        PCE_max = np.max(PCE_sorted)
        VRF_at_max = VRF_sorted[np.argmax(PCE_sorted)]
        if VRF_at_max >= 0:
            maxPCE.append(PCE_max)
            validMask.append(True)
        else:
            maxPCE.append(-np.inf)
            validMask.append(False)
    else:
        maxPCE.append(-np.inf)
        validMask.append(False)

idx_sorted = np.argsort(maxPCE)[::-1]  # descending
top20_idx = [i for i in idx_sorted if validMask[i]][:20]

# ============================================================
# PLOT TOP 20 CURVES
# ============================================================

colors = plt.cm.tab20(np.linspace(0,1,20))
markers = ['o','s','d','^','v','>','<','p','h','+','x','*','.','|','_']

plt.figure(figsize=(10,7))
for k, f in enumerate(top20_idx):
    idx_sort = np.argsort(validResults[f]["Pin_dBm"])
    Pin_sorted = validResults[f]["Pin_dBm"][idx_sort]
    PCE_sorted = validResults[f]["PCE"][idx_sort]

    legendLabel = validResults[f]["file"]

    plt.plot(Pin_sorted, PCE_sorted,
             markers[k % len(markers)]+'-', color=colors[k],
             linewidth=1.6, markerfacecolor=colors[k],
             label=legendLabel)

    PCE_max = np.max(PCE_sorted)
    idx_max = np.argmax(PCE_sorted)
    plt.plot(Pin_sorted[idx_max], PCE_max, 'ko', markerfacecolor='r',
             markersize=6)

plt.xlabel("Pin [dBm]"); plt.ylabel("PCE = Pout/Pin")
plt.title("Top 20 curves with highest PCE (filtered MULT1, no E, no Cs Cap)")
plt.legend(loc='best', fontsize=8)
plt.grid(True); plt.ylim([0,1.1])

# ============================================================
# COMPARATIVE METRICS TABLE
# ============================================================

rows = []
for f in top20_idx:
    fname = validResults[f]["file"]
    idx_sort = np.argsort(validResults[f]["Pin_dBm"])
    Pin_sorted = validResults[f]["Pin_dBm"][idx_sort]
    PCE_sorted = validResults[f]["PCE"][idx_sort]
    Vout_sorted = validResults[f]["Vout"][idx_sort]
    VRF_sorted = validResults[f]["VRFmax"][idx_sort]

    PCE_max = np.max(PCE_sorted)
    idx_max = np.argmax(PCE_sorted)
    Pin_at_max = Pin_sorted[idx_max]
    Vout_at_max = Vout_sorted[idx_max]
    VRF_at_max  = VRF_sorted[idx_max]
    Ratio_at_max = Vout_at_max / VRF_at_max if VRF_at_max != 0 else np.nan

    mask_range = (Pin_sorted >= (Pin_at_max - 5)) & (Pin_sorted <= (Pin_at_max + 5))
    area_local = np.trapezoid(PCE_sorted[mask_range], Pin_sorted[mask_range]) if np.any(mask_range) else 0

    tokensL = re.findall(r"L(\d+)-(\d+)", fname)
    tokensW = re.findall(r"W(\d+)-(\d+)", fname)
    tokensM = re.findall(r"M(\d+)", fname)
    Lval = int(tokensL[0][0]) + int(tokensL[0][1])/100 if tokensL else np.nan
    Wval = int(tokensW[0][0]) + int(tokensW[0][1])/100 if tokensW else np.nan
    Mval = int(tokensM[0]) if tokensM else np.nan
    size_geom = Lval * Wval * Mval

    rows.append([
        fname,
        PCE_max,
        Pin_at_max,
        area_local,
        Vout_at_max,
        Ratio_at_max,
        size_geom,
        VRF_at_max
    ])

resultsTable = pd.DataFrame(
    rows,
    columns=["File","PCE_max","Pin_dBm","Area_local","Vout","Vout_VRFmax","LxWxM","VRF_at_max"]
)

# ============================================================
# WEIGHTED COMPARATIVE TABLE
# ============================================================

PCE_norm  = (resultsTable["PCE_max"]-resultsTable["PCE_max"].min())/(resultsTable["PCE_max"].max()-resultsTable["PCE_max"].min())
Pin_norm  = (resultsTable["Pin_dBm"]-resultsTable["Pin_dBm"].min())/(resultsTable["Pin_dBm"].max()-resultsTable["Pin_dBm"].min())
Vout_norm = (resultsTable["Vout"]-resultsTable["Vout"].min())/(resultsTable["Vout"].max()-resultsTable["Vout"].min())
Area_norm = (resultsTable["Area_local"]-resultsTable["Area_local"].min())/(resultsTable["Area_local"].max()-resultsTable["Area_local"].min())
Size_norm = (resultsTable["LxWxM"]-resultsTable["LxWxM"].min())/(resultsTable["LxWxM"].max()-resultsTable["LxWxM"].min())
VRF_norm  = (resultsTable["VRF_at_max"]-resultsTable["VRF_at_max"].min())/(resultsTable["VRF_at_max"].max()-resultsTable["VRF_at_max"].min())

Size_norm_inv = 1 - Size_norm
Pin_norm_inv  = 1 - Pin_norm
VRF_norm_inv  = 1 - VRF_norm

score = (wPCE*PCE_norm +
         wPin*Pin_norm_inv +
         wVout*Vout_norm +
         wArea*Area_norm +
         wSize*Size_norm_inv +
         wVRF*VRF_norm_inv)
resultsTable["Score"] = score

resultsTable_sorted = resultsTable.sort_values("Score", ascending=False)
resultsTable_top20_weighted = resultsTable_sorted.head(20)

print("\n================ WEIGHTED COMPARATIVE TABLE TOP 20 =================")
pd.set_option("display.max_rows", None)
pd.set_option("display.max_columns", None)
pd.set_option("display.width", None)
pd.set_option("display.max_colwidth", None)
print(resultsTable_top20_weighted)

# ============================================================
# BEST DESIGN SELECTION
# ============================================================

if not resultsTable_sorted.empty:
    best_row = resultsTable_sorted.iloc[0]
    best_file = best_row["File"]

    # Extraer dimensiones desde el nombre del archivo
    tokensL = re.findall(r"L(\d+)-(\d+)", best_file)
    tokensW = re.findall(r"W(\d+)-(\d+)", best_file)
    tokensM = re.findall(r"M(\d+)", best_file) or re.findall(r"MULT(\d+)", best_file)
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
    print("No designs found to select best from.")
