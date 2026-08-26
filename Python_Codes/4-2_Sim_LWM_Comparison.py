# ============================================================
# Title: Comparative analysis of maximum metrics vs dimensions of the CCDDR (PKL version)
# Author: Bastian Veas Moyano
# Last modification: August 16, 2026
# ============================================================

import os, re
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# -------------------------------
# Working folder setup
# -------------------------------
folder = r"D:\Memoria_Last\Simulation_Xschem"
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

# ============================================================
# FILE FILTER
# ============================================================
INCLUDE_FILTERS = ["MULT1","C01-00"]
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

# ============================================================
# Extract maximum metrics per file
# ============================================================
L_vals, W_vals, M_vals = [], [], []
PCE_max_vals, Pin_at_max_vals, Vout_at_max_vals = [], [], []

for res in validResults:
    fname = res["file"]

    # Extract geometry from filename
    tokensL = re.findall(r"L(\d+)-(\d+)", fname)
    tokensW = re.findall(r"W(\d+)-(\d+)", fname)
    tokensM = re.findall(r"M(\d+)", fname)

    Lval = int(tokensL[0][0]) + int(tokensL[0][1])/100 if tokensL else np.nan
    Wval = int(tokensW[0][0]) + int(tokensW[0][1])/100 if tokensW else np.nan
    Mval = int(tokensM[0]) if tokensM else np.nan

    # Sort by Pin
    idx_sort = np.argsort(res["Pin_dBm"])
    Pin_sorted = res["Pin_dBm"][idx_sort]
    PCE_sorted = res["PCE"][idx_sort]
    Vout_sorted = res["Vout"][idx_sort]

    # Maximum values
    if len(PCE_sorted) > 0:
        idx_max = np.argmax(PCE_sorted)
        PCE_max = PCE_sorted[idx_max]
        Pin_at_max = Pin_sorted[idx_max]
        Vout_at_max = Vout_sorted[idx_max]
    else:
        PCE_max, Pin_at_max, Vout_at_max = np.nan, np.nan, np.nan

    # Store metrics
    L_vals.append(Lval)
    W_vals.append(Wval)
    M_vals.append(Mval)
    PCE_max_vals.append(PCE_max)
    Pin_at_max_vals.append(Pin_at_max)
    Vout_at_max_vals.append(Vout_at_max)

# ============================================================
# Filter out weak cases (PCE_max < 0.25)
# ============================================================
discarded_files = []
L_vals_f, W_vals_f, M_vals_f = [], [], []
PCE_max_vals_f, Pin_at_max_vals_f, Vout_at_max_vals_f = [], [], []

for i, res in enumerate(validResults):
    if PCE_max_vals[i] < 0.25 or np.isnan(PCE_max_vals[i]):
        discarded_files.append(res["file"])
        continue

    L_vals_f.append(L_vals[i])
    W_vals_f.append(W_vals[i])
    M_vals_f.append(M_vals[i])
    PCE_max_vals_f.append(PCE_max_vals[i])
    Pin_at_max_vals_f.append(Pin_at_max_vals[i])
    Vout_at_max_vals_f.append(Vout_at_max_vals[i])

print("\n⚠️ Discarded files (PCE_max < 0.25):")
for fname in discarded_files:
    print("   -", fname)


# ============================================================
# Auxiliary function to plot with trends
# ============================================================
def plotWithTrends(x, y, xlabelStr, ylabelStr, titleStr):
    x_sorted = np.array(x)
    y_sorted = np.array(y)
    idx = np.argsort(x_sorted)
    x_sorted, y_sorted = x_sorted[idx], y_sorted[idx]

    plt.scatter(x_sorted, y_sorted, s=60, c='b', label='Data')
    if np.isfinite(x_sorted).all() and np.isfinite(y_sorted).all():
        p_lin = np.polyfit(x_sorted, y_sorted, 1)
        y_lin = np.polyval(p_lin, x_sorted)
        plt.plot(x_sorted, y_lin, 'r--', linewidth=1.5, label='Linear trend')

    plt.xlabel(xlabelStr)
    plt.ylabel(ylabelStr)
    plt.title(titleStr)
    plt.grid(True)
    plt.legend(loc='best')

# ============================================================
# Comparative plots
# ============================================================
# Comparative plots L vs metrics
plt.figure(figsize=(8,10))
plt.subplot(3,1,1); plotWithTrends(L_vals_f, PCE_max_vals_f, 'L [µm]', 'PCE_max', 'L vs PCE_max')
plt.subplot(3,1,2); plotWithTrends(L_vals_f, Pin_at_max_vals_f, 'L [µm]', 'Pin_at_max [dBm]', 'L vs Pin_at_max')
plt.subplot(3,1,3); plotWithTrends(L_vals_f, Vout_at_max_vals_f, 'L [µm]', 'Vout_at_max [V]', 'L vs Vout_at_max')
plt.subplots_adjust(hspace=0.5)   # <-- spacing between rows

# Comparative plots W vs metrics
plt.figure(figsize=(8,10))
plt.subplot(3,1,1); plotWithTrends(W_vals_f, PCE_max_vals_f, 'W [µm]', 'PCE_max', 'W vs PCE_max')
plt.subplot(3,1,2); plotWithTrends(W_vals_f, Pin_at_max_vals_f, 'W [µm]', 'Pin_at_max [dBm]', 'W vs Pin_at_max')
plt.subplot(3,1,3); plotWithTrends(W_vals_f, Vout_at_max_vals_f, 'W [µm]', 'Vout_at_max [V]', 'W vs Vout_at_max')
plt.subplots_adjust(hspace=0.5)

# Comparative plots M vs metrics
plt.figure(figsize=(8,10))
plt.subplot(3,1,1); plotWithTrends(M_vals_f, PCE_max_vals_f, 'M', 'PCE_max', 'M vs PCE_max')
plt.subplot(3,1,2); plotWithTrends(M_vals_f, Pin_at_max_vals_f, 'M', 'Pin_at_max [dBm]', 'M vs Pin_at_max')
plt.subplot(3,1,3); plotWithTrends(M_vals_f, Vout_at_max_vals_f, 'M', 'Vout_at_max [V]', 'M vs Vout_at_max')
plt.subplots_adjust(hspace=0.5)

plt.show()
