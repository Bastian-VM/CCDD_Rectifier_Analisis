# ============================================================
# Title: Fast plot selected variables vs time (PKL version)
# Author: Bastian Veas Moyano
# Last modification: August 16, 2026
#
# Description:
#   Loads a PKL file containing simulation blocks.
#   Allows the user to select two variables and generates:
#
#       1. One figure per variable vs time
#       2. One figure for variable1 vs variable2
#
#   Main optimizations:
#       - Downsampling for plotting
#       - One final plt.show() (no pause per figure)
#       - NumPy arrays cached before plotting
#       - VRF calculated only once per block
#       - Avoids repeated pandas indexing
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

# Target PKL file to plot
targetFile = "Memoria_CCDD2_TRAN_MULT2_L00-20_W00-60_R100k_M20_C01-00.pkl"
filename = os.path.join(py_folder, targetFile)

# Maximum number of points plotted per curve (downsampling)
MAX_PLOT_POINTS = 5000

# ============================================================
# DOWNSAMPLING FUNCTION
# ============================================================

def downsample(x, y, max_points=5000):
    """Reduce number of points for faster plotting."""
    n = len(x)
    if n <= max_points:
        return x, y
    idx = np.linspace(0, n - 1, max_points, dtype=np.int64)
    return x[idx], y[idx]

# ============================================================
# CHECK FILE
# ============================================================

if not os.path.isfile(filename):
    print(f"\n⚠️ The file {targetFile} does not exist in {py_folder}")
    raise SystemExit

print(f"\n📄 Loading file: {targetFile}")

# ============================================================
# LOAD PKL
# ============================================================

results = pd.read_pickle(filename)
if not results:
    print("\n⚠️ PKL contains no blocks.")
    raise SystemExit

print(f"   Blocks loaded: {len(results)}")

# ============================================================
# AVAILABLE VARIABLES
# ============================================================

columns = list(results[0].columns)
print("\nAvailable variables:")
for i, col in enumerate(columns):
    print(f"{i}: {col}")

# ============================================================
# SELECT VARIABLES
# ============================================================

idx_var1 = int(input("\nEnter the index of the first variable: "))
idx_var2 = int(input("Enter the index of the second variable: "))

if not (0 <= idx_var1 < len(columns) and 0 <= idx_var2 < len(columns)):
    raise ValueError("❌ Invalid indices selected.")

var1, var2 = columns[idx_var1], columns[idx_var2]
print(f"\nSelected:\n   Variable 1: {var1}\n   Variable 2: {var2}")

# ============================================================
# CACHE DATA (convert once to NumPy for speed)
# ============================================================

print("\n⚡ Preparing plotting data...")
plot_data = []

for b, block in enumerate(results, start=1):
    # Time vector
    time_data = block["time"].to_numpy(dtype=np.float64, copy=False)
    # VRF vector and max
    vrf_data = block["vrf"].to_numpy(dtype=np.float64, copy=False)
    vrf_max = np.max(np.abs(vrf_data))
    label = f"Block {b} (VRF={vrf_max:.2f} V)"

    # Cache all variables (except first 3 columns: id, time, vrf)
    variables = {col: block[col].to_numpy(dtype=np.float64, copy=False)
                 for col in columns[3:]}

    plot_data.append((time_data, variables, label))

print("   ✔ Plotting data prepared")

# ============================================================
# PLOT ALL VARIABLES VS TIME
# ============================================================

print("\n📈 Creating variable plots...")
for col in columns[3:]:
    fig, ax = plt.subplots(figsize=(8, 5))
    for time_data, variables, label in plot_data:
        y = variables[col]
        x_plot, y_plot = downsample(time_data, y, MAX_PLOT_POINTS)
        ax.plot(x_plot, y_plot, linewidth=1.2, label=label)

    ax.set_title(f"{col} vs time ({targetFile})")
    ax.set_xlabel("Time [s]")
    ax.set_ylabel(col)
    ax.grid(True)
    ax.legend(loc="best")
    fig.tight_layout()

# ============================================================
# VARIABLE 1 VS VARIABLE 2
# ============================================================

print("\n📈 Creating variable1 vs variable2 plot...")
fig, ax = plt.subplots(figsize=(8, 5))
for time_data, variables, label in plot_data:
    x = variables[var1]
    y = variables[var2]
    x_plot, y_plot = downsample(x, y, MAX_PLOT_POINTS)
    ax.plot(x_plot, y_plot, linewidth=1.2, label=label)

ax.set_title(f"{var1} vs {var2} ({targetFile})")
ax.set_xlabel(var1)
ax.set_ylabel(var2)
ax.grid(True)
ax.legend(loc="best")
fig.tight_layout()

# ============================================================
# DISPLAY EVERYTHING ONCE
# ============================================================

print("\n✅ Plot generation complete.\n   Showing figures...")
plt.show()
