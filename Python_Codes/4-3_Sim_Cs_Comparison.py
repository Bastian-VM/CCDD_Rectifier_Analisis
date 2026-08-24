# ============================================================
# Title: Comparative analysis of Cs variations in the CCDDR (PKL version)
# Author: Bastian Veas Moyano
# Last modification: August 18, 2026
#
# Description:
#   Loads combined PKL results of CCDDR simulations,
#   filters valid cases (only MULT1, geometry L00-20_W00-60, M20,
#   no files ending with E, and with suffix _C##-##),
#   builds a comparative table of files with Cs variations.
#   Metrics such as efficiency, output voltage, input power,
#   maximum VRF, local area, and geometric size are calculated.
#   Metrics are normalized to obtain a weighted score,
#   and comparative plots are generated as a function of Cs.
# ============================================================

import os, re
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# -------------------------------
# Define Weights
# -------------------------------
wPCE   = 0.20   # maximum efficiency
wPin   = 0.15   # input power
wVout  = 0.10   # output voltage
wVRF   = 0.50   # maximum VRF
wArea  = 0.05   # local area
wSize  = 0.00   # geometric size

print("Sum of weights:", wPCE+wPin+wVout+wVRF+wArea+wSize)

# -------------------------------
# Working folder setup
# -------------------------------
folder = r"D:\Memoria_Last\Simulaciones_Xschem"
py_folder = os.path.join(folder, "Files_PY")
os.makedirs(py_folder, exist_ok=True)

print(f"\n📂 Working folder: {py_folder}")

# -------------------------------
# Load combined results
# -------------------------------
filename = os.path.join(py_folder, "all_Results.pkl")
if not os.path.isfile(filename):
    raise FileNotFoundError(f"⚠️ Combined results file not found: {filename}")

allResults = pd.read_pickle(filename)
print(f"Total loaded results: {len(allResults)}")

# -------------------------------
# Filter valid results
# -------------------------------
INCLUDE_FILTERS = ["MULT1","L00-20","W00-60","M20"]
EXCLUDE_FILTERS = ["E"]

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

# -------------------------------
# Build comparative table
# -------------------------------
rows = []
for res in validResults:
    fname = res["file"]

    tokensC = re.findall(r"C(\d+)-(\d+)", fname)
    if not tokensC: 
        continue
    Cs_val = int(tokensC[0][0]) + int(tokensC[0][1])/100

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
    Ratio_at_max = Vout_at_max/VRF_at_max if VRF_at_max != 0 else np.nan

    mask_range = (Pin_sorted >= (Pin_at_max-5)) & (Pin_sorted <= (Pin_at_max+5))
    if np.any(mask_range):
        try:
            trapz_func = np.trapz
        except AttributeError:
            trapz_func = np.trapezoid
        area_local = trapz_func(PCE_sorted[mask_range], Pin_sorted[mask_range])
    else:
        area_local = 0

    tokensL = re.findall(r"L(\d+)-(\d+)", fname)
    tokensW = re.findall(r"W(\d+)-(\d+)", fname)
    tokensM = re.findall(r"M(\d+)", fname)
    Lval = int(tokensL[0][0]) + int(tokensL[0][1])/100 if tokensL else np.nan
    Wval = int(tokensW[0][0]) + int(tokensW[0][1])/100 if tokensW else np.nan
    Mval = int(tokensM[0]) if tokensM else np.nan
    size_geom = Lval*Wval*Mval

    rows.append([fname, Cs_val, PCE_max, Pin_at_max, Vout_at_max,
                 VRF_at_max, Ratio_at_max, area_local, size_geom,
                 Lval, Wval, Mval])

tablaCsComp = pd.DataFrame(rows, columns=[
    "File","Cs_pF","PCE_max","Pin_dBm","Vout","VRF_at_max",
    "Vout_VRFmax","Area_local","LxWxM","L","W","M"
])

# -------------------------------
# Normalization and Weighted Score
# -------------------------------
def normalize(series):
    return (series-series.min())/(series.max()-series.min()) if series.max()!=series.min() else series*0

PCE_norm  = normalize(tablaCsComp["PCE_max"])
Pin_norm  = normalize(tablaCsComp["Pin_dBm"])
Vout_norm = normalize(tablaCsComp["Vout"])
VRF_norm  = normalize(tablaCsComp["VRF_at_max"])
Area_norm = normalize(tablaCsComp["Area_local"])
Size_norm = normalize(tablaCsComp["LxWxM"])

Pin_norm_inv  = 1 - Pin_norm
Size_norm_inv = 1 - Size_norm
VRF_norm_inv  = 1 - VRF_norm

score = (wPCE*PCE_norm +
         wPin*Pin_norm_inv +
         wVout*Vout_norm +
         wVRF*VRF_norm_inv +
         wArea*Area_norm +
         wSize*Size_norm_inv)

tablaCsComp["Score"] = score
tablaCsComp_sorted = tablaCsComp.sort_values("Score", ascending=False)

# -------------------------------
# Show comparative table
# -------------------------------
pd.set_option("display.max_rows", None)
pd.set_option("display.max_columns", None)
pd.set_option("display.width", None)
pd.set_option("display.max_colwidth", None)

print("\n================ COMPARATIVE TABLE FILES WITH Cs =================")
print(tablaCsComp_sorted.head(20))

# ============================================================
# Extract dimensions (L, W, M, C) of best design
# ============================================================
best_row = tablaCsComp_sorted.iloc[0]
best_file = best_row["File"]

print("\n================ BEST DESIGN DIMENSIONS =================")
print(f"File: {best_file}")
print(f"L = {best_row['L']} µm")
print(f"W = {best_row['W']} µm")
print(f"M = {best_row['M']}")
print(f"C = {best_row['Cs_pF']} pF")

# ============================================================
# Comparative metrics vs Cs (4-subplot view)
# ============================================================
tablaCsComp_byCs = tablaCsComp.sort_values("Cs_pF")

plt.figure(figsize=(10,8))

plt.subplot(2,2,1)
plt.semilogx(tablaCsComp_byCs["Cs_pF"], tablaCsComp_byCs["PCE_max"], '-o')
plt.xlabel("Cs [pF] (log)"); plt.ylabel("PCE_max"); plt.title("PCE_max vs Cs"); plt.grid(True)

plt.subplot(2,2,2)
plt.semilogx(tablaCsComp_byCs["Cs_pF"], tablaCsComp_byCs["Vout"], '-s')
plt.xlabel("Cs [pF] (log)"); plt.ylabel("Vout@PCEmax [V]"); plt.title("Vout vs Cs"); plt.grid(True)

plt.subplot(2,2,3)
plt.semilogx(tablaCsComp_byCs["Cs_pF"], tablaCsComp_byCs["VRF_at_max"], '-d')
plt.xlabel("Cs [pF] (log)"); plt.ylabel("VRF@PCEmax [V]"); plt.title("VRF vs Cs"); plt.grid(True)

plt.subplot(2,2,4)
plt.semilogx(tablaCsComp_byCs["Cs_pF"], tablaCsComp_byCs["Pin_dBm"], '-^')
plt.xlabel("Cs [pF] (log)"); plt.ylabel("Pin@PCEmax [dBm]"); plt.title("Pin vs Cs"); plt.grid(True)

plt.suptitle("Comparative metrics vs Cs", fontsize=14)
plt.tight_layout(rect=[0,0,1,0.96])
plt.show()
