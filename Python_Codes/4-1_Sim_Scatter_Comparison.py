# ============================================================
# Title: Comparative analysis of CCDDR results (PKL version)
# Author: Bastian Veas Moyano
# Last modification: August 16, 2026
#
# Description:
#   Loads combined PKL results of CCDDR simulations,
#   filters valid cases, and generates comparative plots:
#       - PCE vs Pin
#       - Vout vs Pin
#       - Vout/VRFmax vs Pin
#   Also builds a 3D scatter plot of geometry (W,L,M) vs max efficiency.
#   Single global parameter FONT_SIZE controls all font sizes (keeps ratios).
# ============================================================

import os, re
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# -------------------------------
# Single global font size parameter (points)
# -------------------------------
FONT_SIZE = 15.0

# Apply to matplotlib rcParams (keeps ratios consistent)
plt.rcParams.update({
    "font.size": FONT_SIZE,
    "axes.titlesize": FONT_SIZE * 1.6,
    "axes.labelsize": FONT_SIZE * 1.1,
    "xtick.labelsize": FONT_SIZE * 0.9,
    "ytick.labelsize": FONT_SIZE * 0.9,
    "legend.fontsize": FONT_SIZE * 0.95,
    "figure.titlesize": FONT_SIZE * 1.6,
})

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

# -------------------------------
# Helper: build legend label
# -------------------------------
def buildLegendLabel(fname):
    tokensL = re.findall(r"L(\d+)-(\d+)", fname)
    tokensW = re.findall(r"W(\d+)-(\d+)", fname)
    tokensM = re.findall(r"M(\d+)", fname)
    tokensC = re.findall(r"C(\d+)-(\d+)", fname)

    Lstr = f"{int(tokensL[0][0]) + int(tokensL[0][1])/100:.2f}" if tokensL else "N/A"
    Wstr = f"{int(tokensW[0][0]) + int(tokensW[0][1])/100:.2f}" if tokensW else "N/A"
    Mstr = f"{int(tokensM[0])}" if tokensM else "N/A"
    Cstr = f"{int(tokensC[0][0]) + int(tokensC[0][1])/100:.2f}" if tokensC else "N/A"

    return f"L={Lstr}, W={Wstr}, M={Mstr}, C={Cstr}"

# -------------------------------
# Plot styling (no transparency)
# -------------------------------
markers = ['o','s','d','^','v','>','<','p','h','+','x','*','.','|','_']
colors = plt.cm.tab20(np.linspace(0,1,len(validResults)))
marker_area_base = 80  # base marker area (points^2)
marker_area = marker_area_base * (FONT_SIZE / 10.0)**2  # scale marker area with font size

# -------------------------------
# Figure 1: PCE vs Pin
# -------------------------------
plt.figure(figsize=(9,6))
for f,res in enumerate(validResults):
    idx_sort = np.argsort(res["Pin_dBm"])
    Pin_sorted = res["Pin_dBm"][idx_sort]
    PCE_sorted = res["PCE"][idx_sort]
    VRF_sorted = res["VRFmax"][idx_sort]
    VRF_rounded = np.round(VRF_sorted/0.05)*0.05
    legendLabel = buildLegendLabel(res["file"])
    plt.plot(Pin_sorted, PCE_sorted,
             markers[f % len(markers)]+'-', color=colors[f],
             linewidth=1.4, markerfacecolor=colors[f], alpha=1.0,
             label=legendLabel)
    for i in range(len(Pin_sorted)):
        plt.text(Pin_sorted[i], PCE_sorted[i], f"{VRF_rounded[i]:.2f}",
                 fontsize=FONT_SIZE * 0.85, color='k', ha='left')
handles, labels = plt.gca().get_legend_handles_labels()
if labels: plt.legend()
plt.xlabel("Average Pin [dBm]"); plt.ylabel("PCE = Pout/Pin")
plt.title("Comparison PCE vs Pin (rounded VRFmax)")
plt.grid(True); plt.ylim([0,1.5])

# -------------------------------
# Figure 2: Vout vs Pin
# -------------------------------
plt.figure(figsize=(9,6))
for f,res in enumerate(validResults):
    idx_sort = np.argsort(res["Pin_dBm"])
    Pin_sorted = res["Pin_dBm"][idx_sort]
    Vout_sorted = res["Vout"][idx_sort]
    VRF_sorted = res["VRFmax"][idx_sort]
    VRF_rounded = np.round(VRF_sorted/0.05)*0.05
    legendLabel = buildLegendLabel(res["file"])
    plt.plot(Pin_sorted, Vout_sorted,
             markers[f % len(markers)]+'-', color=colors[f],
             linewidth=1.4, markerfacecolor=colors[f], alpha=1.0,
             label=legendLabel)
    for i in range(len(Pin_sorted)):
        plt.text(Pin_sorted[i], Vout_sorted[i], f"{VRF_rounded[i]:.2f}",
                 fontsize=FONT_SIZE * 0.85, color='k', ha='left')
handles, labels = plt.gca().get_legend_handles_labels()
if labels: plt.legend()
plt.xlabel("Average Pin [dBm]"); plt.ylabel("Average Vout [V]")
plt.title("Comparison Vout vs Pin (rounded VRFmax)")
plt.grid(True); plt.ylim([0,1.5])

# -------------------------------
# Figure 3: Vout/VRFmax vs Pin
# -------------------------------
plt.figure(figsize=(9,6))
for f,res in enumerate(validResults):
    idx_sort = np.argsort(res["Pin_dBm"])
    Pin_sorted = res["Pin_dBm"][idx_sort]
    Ratio_sorted = res["Vout"][idx_sort] / res["VRFmax"][idx_sort]
    VRF_sorted = res["VRFmax"][idx_sort]
    VRF_rounded = np.round(VRF_sorted/0.05)*0.05
    legendLabel = buildLegendLabel(res["file"])
    plt.plot(Pin_sorted, Ratio_sorted,
             markers[f % len(markers)]+'-', color=colors[f],
             linewidth=1.4, markerfacecolor=colors[f], alpha=1.0,
             label=legendLabel)
    for i in range(len(Pin_sorted)):
        plt.text(Pin_sorted[i], Ratio_sorted[i], f"{VRF_rounded[i]:.2f}",
                 fontsize=FONT_SIZE * 0.85, color='k', ha='left')
handles, labels = plt.gca().get_legend_handles_labels()
if labels: plt.legend()
plt.xlabel("Average Pin [dBm]"); plt.ylabel("Vout / VRFmax")
plt.title("Comparison Vout/VRFmax vs Pin (rounded VRFmax)")
plt.grid(True)

# -------------------------------
# 3D Scatter: Dimensions vs PCE_max (Pin > -40 dBm) — robust, no transparency
# -------------------------------
# Build arrays from validResults (self-contained)
L_vals, W_vals, M_vals, C_vals, PCE_max_vals, Pin_at_max_vals = [], [], [], [], [], []
for res in validResults:
    fname = res["file"]
    tokensL = re.findall(r"L(\d+)-(\d+)", fname)
    tokensW = re.findall(r"W(\d+)-(\d+)", fname)
    tokensM = re.findall(r"M(\d+)", fname)
    tokensC = re.findall(r"C(\d+)-(\d+)", fname)
    Lval = int(tokensL[0][0]) + int(tokensL[0][1])/100 if tokensL else np.nan
    Wval = int(tokensW[0][0]) + int(tokensW[0][1])/100 if tokensW else np.nan
    Mval = int(tokensM[0]) if tokensM else np.nan
    Cval = int(tokensC[0][0]) + int(tokensC[0][1])/100 if tokensC else np.nan
    Pin_vals = np.asarray(res["Pin_dBm"], dtype=float)
    PCE_vals = np.asarray(res["PCE"], dtype=float)
    mask_valid = Pin_vals > -40
    if np.any(mask_valid):
        PCE_max_filtered = np.max(PCE_vals[mask_valid])
        Pin_at_max = Pin_vals[mask_valid][np.argmax(PCE_vals[mask_valid])]
    else:
        PCE_max_filtered, Pin_at_max = np.nan, np.nan
    L_vals.append(Lval); W_vals.append(Wval); M_vals.append(Mval); C_vals.append(Cval)
    PCE_max_vals.append(PCE_max_filtered); Pin_at_max_vals.append(Pin_at_max)

# Convert to numpy arrays
W_vals = np.array(W_vals, dtype=float)
L_vals = np.array(L_vals, dtype=float)
M_vals = np.array(M_vals, dtype=float)
pce_arr = np.array(PCE_max_vals, dtype=float)

# Prepare figure
fig = plt.figure(figsize=(9,7))
ax = fig.add_subplot(111, projection='3d')

# Colormap and normalization (handle NaNs)
nan_mask = np.isnan(pce_arr)
valid_mask = ~nan_mask
cmap = plt.get_cmap('jet')
if np.any(valid_mask):
    vmin = np.nanmin(pce_arr)
    vmax = np.nanmax(pce_arr)
    norm = plt.Normalize(vmin=vmin, vmax=vmax)
    colors = np.zeros((len(pce_arr), 4), dtype=float)
    colors[valid_mask] = cmap(norm(pce_arr[valid_mask]))
else:
    colors = np.tile(np.array([0.7,0.7,0.7,1.0]), (len(pce_arr),1))

# Force full opacity
colors[:, 3] = 1.0

# Marker area scaled with FONT_SIZE (defined earlier)
s = marker_area

# Scatter with explicit facecolors and no depth shading
# Use unfilled marker 'o' with facecolors set; for some backends edgecolors='k' on unfilled markers raises a warning.
# To avoid warnings, set marker to 'o' (filled) and provide facecolors and edgecolors explicitly.
sc = ax.scatter(
    W_vals, L_vals, M_vals,
    facecolors=colors,
    edgecolors='k',
    linewidths=0.3,
    s=s,
    depthshade=False
)

### Highlight best (opaque)
##if np.any(valid_mask):
##    idx_best = np.nanargmax(pce_arr)
##    ax.scatter(
##        [W_vals[idx_best]], [L_vals[idx_best]], [M_vals[idx_best]],
##        c='k', s=s * 2.5, marker='o', depthshade=False, label='Best PCEmax'
##    )

# Colorbar using same norm/cmap
if np.any(valid_mask):
    mappable = plt.cm.ScalarMappable(norm=norm, cmap=cmap)
    mappable.set_array(pce_arr)
    cbar = plt.colorbar(mappable, ax=ax)
    cbar.set_label("PCEmax", fontsize=FONT_SIZE)
    cbar.ax.tick_params(labelsize=FONT_SIZE * 0.9)

# Defensive: ensure full opacity on all collections
for pathcoll in ax.collections:
    try:
        pathcoll.set_alpha(1.0)
    except Exception:
        pass

# Labels and legend
ax.set_xlabel("W [µm]")
ax.set_ylabel("L [µm]")
ax.set_zlabel("M")
handles, labels = ax.get_legend_handles_labels()
if labels:
    ax.legend()

plt.show()
