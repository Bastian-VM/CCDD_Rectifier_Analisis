# ============================================================
# Title: Magnitude and Phase Error in Distributed CMOS RC Gate
# Author: Bastian Veas Moyano
# Last modification: August 24, 2026
#
# Description:
#   Performs RC analysis of a distributed CMOS gate.
#   Evaluates magnitude error, phase error, phase shift,
#   relative magnitude, and settling error across technology cases.
#   Generates seven homogeneous plots with all scenarios together.
# ============================================================

import numpy as np
import matplotlib.pyplot as plt

# ============================================================
# CONFIGURATION
# ============================================================

f0 = 900e6                  # frequency [Hz]
w = 2 * np.pi * f0          # angular frequency [rad/s]
T = 1/f0

# Settling time
t_settle = 1/(16*f0)
print(f"t_settle = {t_settle * 1e12:.6g} ps")

threshold = 0.01             # 1%

print("\n====================================================")
print("Distributed CMOS Gate - RC Analysis")
print("====================================================")
print(f"f0 = {f0 / 1e6:.6g} MHz")

cases = [
    {"name": "Best",    "Rsheet": 2.0,  "Cox": 0.005},
    {"name": "Average", "Rsheet": 10.0, "Cox": 0.01},
    {"name": "Worst",   "Rsheet": 20.0, "Cox": 0.02}
]

Wum = np.linspace(0.13, 1000.0, 4000)   # [µm]
W = Wum * 1e-6                          # [m]

FONT_SIZE = 20
LINEWIDTH = 2
plt.rcParams.update({
    "font.size": FONT_SIZE,
    "axes.titlesize": FONT_SIZE * 1.1,
    "axes.labelsize": FONT_SIZE,
    "legend.fontsize": FONT_SIZE * 0.9,
    "lines.linewidth": LINEWIDTH,
})
GRID_ALPHA = 0.6
colors = plt.cm.tab10(np.linspace(0, 1, len(cases)))

# ============================================================
# PREPARE FIGURES
# ============================================================

fig1, ax1 = plt.subplots(figsize=(7,6))
fig2, ax2 = plt.subplots(figsize=(7,6))
fig3, ax3 = plt.subplots(figsize=(7,6))
fig4, ax4 = plt.subplots(figsize=(7,6))
fig5, ax5 = plt.subplots(figsize=(7,6))   # Settling error vs W (t=T/16)
fig6, ax6 = plt.subplots(figsize=(7,6))   # Gate width vs Settling time

# ============================================================
# SIMULATION LOOP
# ============================================================

for i, case in enumerate(cases):
    Rsheet = case["Rsheet"]
    Cox = case["Cox"]

    aW = W**2 * np.sqrt(w * Rsheet * Cox / 2)
    gammaW = (1.0 + 1.0j) * aW

    denom = 1.0 + np.exp(-2.0 * gammaW)
    eps = np.finfo(float).eps
    denom = np.where(np.abs(denom) < eps, eps, denom)
    H = 2.0 * np.exp(-gammaW) / denom

    mag_ratio = np.abs(H)
    eM = np.abs(1.0 - H)

    DeltaPhi = np.angle(H)
    DeltaPhi_unwrapped = np.unwrap(DeltaPhi)
    ePhi = np.abs(DeltaPhi_unwrapped) / (2.0 * np.pi)

    RgCg = (Rsheet * Cox / 3.0) * W**2

    # Settling error for t = T/16 vs W
    er_fixed = (4.0 / np.pi) * np.exp(-(np.pi**2 * t_settle) / (4.0 * RgCg))

    # Plot all scenarios together
    ax1.plot(Wum, 100.0*eM, color=colors[i], label=case["name"], linewidth=LINEWIDTH)
    ax2.plot(Wum, 100.0*ePhi, color=colors[i], label=case["name"], linewidth=LINEWIDTH)
    ax3.plot(Wum, DeltaPhi_unwrapped*180.0/np.pi, color=colors[i], label=case["name"], linewidth=LINEWIDTH)
    ax4.plot(Wum, mag_ratio, color=colors[i], label=case["name"], linewidth=LINEWIDTH)
    ax5.plot(Wum, er_fixed, color=colors[i], label=case["name"], linewidth=LINEWIDTH)

    # Gate width vs Settling time constraint
    t_range = np.linspace(T/16, 16*T, 200)
    Wmax = np.sqrt((np.pi**2 * t_range) / (4 * Rsheet * Cox * np.log(4/(np.pi*threshold))))
    ax6.plot(t_range*1e9, Wmax*1e6, color=colors[i], label=case["name"], linewidth=LINEWIDTH)

# ============================================================
# LABELS AND LEGENDS
# ============================================================

ax1.set_xlabel("W [µm]"); ax1.set_ylabel("Magnitude Error [%]")
ax1.set_title("Relative Magnitude Error"); ax1.legend(); ax1.grid(True,alpha=GRID_ALPHA)

ax2.set_xlabel("W [µm]"); ax2.set_ylabel("Phase Error [% of period]")
ax2.set_title("Relative Phase Error"); ax2.legend(); ax2.grid(True,alpha=GRID_ALPHA)

ax3.set_xlabel("W [µm]"); ax3.set_ylabel("Phase [deg]")
ax3.set_title("Phase between V(0) and V(W)"); ax3.legend(); ax3.grid(True,alpha=GRID_ALPHA)

ax4.set_xlabel("W [µm]"); ax4.set_ylabel("|V(W)| / |V(0)|")
ax4.set_title("Relative Magnitude |V(W)|/|V(0)|"); ax4.legend(); ax4.grid(True,alpha=GRID_ALPHA)

ax5.set_xlabel("W [µm]"); ax5.set_ylabel("Settling error e_r(t)")
ax5.set_title("Settling Error vs W (t = T/16)")
ax5.set_ylim([-0.1e-6, 3.5e-6]); ax5.set_xlim([0, 10])
ax5.legend(); ax5.grid(True,alpha=GRID_ALPHA)

ax6.set_xlabel("Settling time [ns]"); ax6.set_ylabel("Maximum gate width W [µm]")
ax6.set_title("Gate width vs Settling time constraint")
ax6.legend(); ax6.grid(True,alpha=GRID_ALPHA)

# ============================================================
# SHOW FIGURES
# ============================================================

plt.tight_layout()
plt.show()
print("\nScript finished successfully.")
