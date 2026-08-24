# ============================================================
# Title: 4D Sweep with 12 Plots (Python version)
# Author: Bastian Veas Moyano
# Last modification: August 24, 2026
#
# Description:
#   Translation of MATLAB script "barrido_VnVp_Ptot_12graficas.m"
#   into Python. Performs a 4D sweep of L12, L34, W1, W3,
#   computes NMOS/PMOS currents with WI/SI blending,
#   records results, selects the global minimum, and
#   generates 12 homogeneous plots.
# ============================================================

import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import fsolve

# ============================================================
# CONFIGURATION
# ============================================================

# General parameters
Vo = 1.0
Vth_n = 0.442
Vth_p = 0.442
n = 1.05

kB = 1.380649e-23
q  = 1.602176634e-19
T  = 300.0
VT = kB * T / q

# Current parameters
I0_unit = 1e-7
Kn_default = 1e-10
lambda_default = 0.0
delta_blend = 0.01

# Solver parameters
FSOLVE_XTOL = 1e-14
FSOLVE_MAXFEV = 500

# Sweep range
Npoints = 15
range_um = np.linspace(0.15, 1.0, Npoints)
L12_vec = range_um * 1e-6
L34_vec = range_um * 1e-6
W12_vec = range_um * 1e-6
W34_vec = range_um * 1e-6

# Plot style parameters
FONT_SIZE = 20
plt.rcParams.update({
    "font.size": FONT_SIZE,
    "axes.titlesize": FONT_SIZE * 1.1,
    "axes.labelsize": FONT_SIZE,
    "xtick.labelsize": FONT_SIZE * 0.6,
    "ytick.labelsize": FONT_SIZE * 0.6,
    "legend.fontsize": FONT_SIZE * 0.95,
    "figure.titlesize": FONT_SIZE * 1.2,
    "lines.linewidth": 1.6,
})
MARKER = 'o'
LINESTYLE = '-'
LINEWIDTH = 1.6
MARKERSIZE = 5 * (FONT_SIZE / 10.0)
GRID_ALPHA = 0.6

# ============================================================
# CURRENT FUNCTION
# ============================================================
def calc_Icond(VGS, VDS, p):
    VGT = VGS - p["VTH"]

    I_WI = p["ID0"] * (p["w"]/p["l"]) * np.exp(VGT/(p["n"]*p["VT"])) * (1 - np.exp(-abs(VDS)/(p["n"]*p["VT"])))
    I_WI = max(I_WI, 0.0)

    VGT_eff = max(VGT, 1e-15)
    I_LIN = p["Kn"] * (p["w"]/p["l"]) * VGT_eff * abs(VDS) * (1 - abs(VDS)/(2*VGT_eff))
    I_LIN = max(I_LIN, 0.0)

    I_SAT = 0.5 * p["Kn"] * (p["w"]/p["l"]) * max(VGT,0.0)**2 * (1 + p["lambda"]*abs(VDS))
    I_SAT = max(I_SAT, 0.0)

    w_WI = 1/(1+np.exp(VGT/p["delta"]))
    w_SI = 1 - w_WI
    w_LIN = 1/(1+np.exp((abs(VDS)-VGT)/p["delta"]))
    w_SAT = 1 - w_LIN

    Icond = w_WI*I_WI + w_SI*(w_LIN*I_LIN + w_SAT*I_SAT)
    if not np.isfinite(Icond): Icond = 0.0
    return max(Icond,0.0)

# ============================================================
# MAIN LOOP
# ============================================================
logData = []
Global = {"Pmin": np.inf}
count_ok, count_fail = 0, 0

for L12 in L12_vec:
    for L34 in L34_vec:
        for W1 in W12_vec:
            for W3 in W34_vec:

                p_n = {"VTH":Vth_n,"ID0":I0_unit,"w":W1,"l":L12,"n":n,"VT":VT,
                       "Kn":Kn_default,"lambda":lambda_default,"delta":delta_blend}
                p_p = p_n.copy(); p_p.update({"VTH":Vth_p,"w":W3,"l":L34})

                geom_ratio = (p_p["w"]/p_p["l"]) / (p_n["w"]/p_n["l"])
                Vn_guess = 0.5*(Vo + Vth_n - Vth_p + n*VT*np.log(geom_ratio)) if geom_ratio>0 else Vo/2
                Vn_guess = np.clip(Vn_guess,0,Vo)
                Vp_guess = Vo - Vn_guess

                def F(x): return [calc_Icond(x[0],x[0],p_n)-calc_Icond(x[1],x[1],p_p), x[0]+x[1]-Vo]

                try:
                    sol = fsolve(F,[Vn_guess,Vp_guess],xtol=FSOLVE_XTOL,maxfev=FSOLVE_MAXFEV)
                except: count_fail+=1; continue

                Vn,Vp = sol
                if not np.isfinite(Vn) or not np.isfinite(Vp) or Vn<0 or Vn>Vo or Vp<0 or Vp>Vo:
                    count_fail+=1; continue

                In = calc_Icond(Vn,Vn,p_n); Ip = calc_Icond(Vp,Vp,p_p)
                Ptot = 2*(In*Vn + Ip*Vp)

                logData.append([L12*1e6,L34*1e6,W1*1e6,W3*1e6,Ptot,Vn,Vp,Vn-Vp,In,Ip])

                if Ptot < Global["Pmin"]:
                    Global.update({"Pmin":Ptot,"L12":L12,"L34":L34,"W1":W1,"W3":W3,"Vn":Vn,"Vp":Vp,"In":In,"Ip":Ip})
                count_ok+=1

logData = np.array(logData)

# ============================================================
# RESULTS
# ============================================================
print("\n================ GLOBAL RESULT ================")
print(f"L12 = {Global['L12']*1e6:.4f} um, L34 = {Global['L34']*1e6:.4f} um")
print(f"W1  = {Global['W1']*1e6:.4f} um, W3  = {Global['W3']*1e6:.4f} um")
print(f"Ptot = {Global['Pmin']:.6e} W")
print(f"Vn = {Global['Vn']:.6f} V, Vp = {Global['Vp']:.6f} V")
print(f"Vn-Vp = {1e3*(Global['Vn']-Global['Vp']):.6f} mV")
print(f"In = {Global['In']:.6e} A, Ip = {Global['Ip']:.6e} A")
print(f"OK = {count_ok}, FAIL = {count_fail}")

# ============================================================
# PLOTTING HELPERS
# ============================================================
def plot_scatter(x,y,c,xlabel,ylabel,title,cbarlabel,cmap="viridis"):
    fig, ax = plt.subplots(figsize=(7,6))
    sc = ax.scatter(x,y,c=c,s=40,cmap=cmap)
    ax.set_xlabel(xlabel); ax.set_ylabel(ylabel)
    ax.set_title(title); ax.grid(True,alpha=GRID_ALPHA)
    plt.colorbar(sc,label=cbarlabel)
    plt.tight_layout()

def plot_line(x,y,xlabel,ylabel,title,color='b'):
    fig, ax = plt.subplots(figsize=(7,6))
    ax.plot(x,y,color+'-o',linewidth=LINEWIDTH,markersize=MARKERSIZE)
    ax.set_xlabel(xlabel); ax.set_ylabel(ylabel)
    ax.set_title(title); ax.grid(True,alpha=GRID_ALPHA)
    plt.tight_layout()


# ============================================================
# HOMOGENEOUS PLOTS (12)
# ============================================================

# Subsets for plotting
tol = 1e-9
maskL = (np.abs(logData[:,0] - Global["L12"]*1e6) < tol) & (np.abs(logData[:,1] - Global["L34"]*1e6) < tol)
dataW = logData[maskL,:]

maskW = (np.abs(logData[:,2] - Global["W1"]*1e6) < tol) & (np.abs(logData[:,3] - Global["W3"]*1e6) < tol)
dataL = logData[maskW,:]

if dataW.size == 0:
    maskL = (np.abs(logData[:,0] - Global["L12"]*1e6) < 1e-6) & (np.abs(logData[:,1] - Global["L34"]*1e6) < 1e-6)
    dataW = logData[maskL,:]
if dataL.size == 0:
    maskW = (np.abs(logData[:,2] - Global["W1"]*1e6) < 1e-6) & (np.abs(logData[:,3] - Global["W3"]*1e6) < 1e-6)
    dataL = logData[maskW,:]

# -------------------------------
# Ptot plots (6)
# -------------------------------
plot_scatter(dataW[:,3], dataW[:,2], dataW[:,4],
             "W3=W4 [um]", "W1=W2 [um]", "Ptot map W1-W3", "Ptot [W]", cmap="turbo")

maskW3 = np.isclose(dataW[:,3], Global["W3"]*1e6, atol=1e-6)
if np.any(maskW3):
    plot_line(dataW[maskW3,2], dataW[maskW3,4],
              "W1=W2 [um]", "Ptot [W]", "Ptot vs W1 (W3 optimal)", color='b')

maskW1 = np.isclose(dataW[:,2], Global["W1"]*1e6, atol=1e-6)
if np.any(maskW1):
    plot_line(dataW[maskW1,3], dataW[maskW1,4],
              "W3=W4 [um]", "Ptot [W]", "Ptot vs W3 (W1 optimal)", color='r')

plot_scatter(dataL[:,1], dataL[:,0], dataL[:,4],
             "L3=L4 [um]", "L1=L2 [um]", "Ptot map L12-L34", "Ptot [W]", cmap="turbo")

maskL34 = np.isclose(dataL[:,1], Global["L34"]*1e6, atol=1e-6)
if np.any(maskL34):
    plot_line(dataL[maskL34,0], dataL[maskL34,4],
              "L1=L2 [um]", "Ptot [W]", "Ptot vs L12 (L34 optimal)", color='b')

maskL12 = np.isclose(dataL[:,0], Global["L12"]*1e6, atol=1e-6)
if np.any(maskL12):
    plot_line(dataL[maskL12,1], dataL[maskL12,4],
              "L3=L4 [um]", "Ptot [W]", "Ptot vs L34 (L12 optimal)", color='r')

# -------------------------------
# Vn-Vp plots (6)
# -------------------------------
plot_scatter(dataW[:,3], dataW[:,2], 1e3*dataW[:,7],
             "W3=W4 [um]", "W1=W2 [um]", "Vn-Vp map W1-W3", "Vn-Vp [mV]", cmap="jet")

if np.any(maskW3):
    plot_line(dataW[maskW3,2], 1e3*dataW[maskW3,7],
              "W1=W2 [um]", "Vn-Vp [mV]", "Vn-Vp vs W1 (W3 optimal)", color='b')

if np.any(maskW1):
    plot_line(dataW[maskW1,3], 1e3*dataW[maskW1,7],
              "W3=W4 [um]", "Vn-Vp [mV]", "Vn-Vp vs W3 (W1 optimal)", color='r')

plot_scatter(dataL[:,1], dataL[:,0], 1e3*dataL[:,7],
             "L3=L4 [um]", "L1=L2 [um]", "Vn-Vp map L12-L34", "Vn-Vp [mV]", cmap="jet")

if np.any(maskL34):
    plot_line(dataL[maskL34,0], 1e3*dataL[maskL34,7],
              "L1=L2 [um]", "Vn-Vp [mV]", "Vn-Vp vs L12 (L34 optimal)", color='b')

if np.any(maskL12):
    plot_line(dataL[maskL12,1], 1e3*dataL[maskL12,7],
              "L3=L4 [um]", "Vn-Vp [mV]", "Vn-Vp vs L34 (L12 optimal)", color='r')

# -------------------------------
# Theoretical verification plot
# -------------------------------
fig, ax = plt.subplots(figsize=(7,6))
x_theory = np.log((logData[:,3]/logData[:,1])/(logData[:,2]/logData[:,0]))
y_sim = logData[:,7]
ax.plot(x_theory,y_sim,'o')
ax.set_xlabel("ln[(W3/L3)/(W1/L1)]")
ax.set_ylabel("Vn - Vp [V]")
ax.set_title("Logarithmic dependence verification")
ax.grid(True,alpha=GRID_ALPHA)
plt.tight_layout()

# Show all figures
plt.show()
