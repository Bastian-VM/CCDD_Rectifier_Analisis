v {xschem version=3.4.5 file_version=1.2
}
G {}
K {}
V {}
S {}
E {}
T {Esto es tanto para lv_nmos como para lv_pmos
l_min = 0.13u
w_min = 0.15u; w_max = 10u

hvMOS
l_min_HVnmos = 0.45u; l_min_HVpmos = 0.4
w_min_HVnmos = 0.3u;w_min_HVpmos = 0.3u;w_max = 10u;
} -670 -230 0 0 0.4 0.4 {}
N 200 -350 220 -350 {lab=V1P}
N 200 -500 260 -500 {lab=V1P}
N 180 -450 220 -450 {lab=V1N}
N 200 -500 200 -350 {lab=V1P}
N 170 -350 200 -350 {lab=V1P}
N 130 -500 200 -500 {lab=V1P}
N 180 -300 260 -300 {lab=V1N}
N 180 -450 180 -300 {lab=V1N}
N 170 -450 180 -450 {lab=V1N}
N 130 -300 180 -300 {lab=V1N}
N 260 -410 490 -410 {lab=VOUT}
N 470 -350 470 -340 {lab=GND}
N 100 -160 100 -130 {
lab=VRFP}
N 100 -70 100 -40 {
lab=VRFM}
N 380 -350 380 -340 {
lab=GND}
N 260 -450 270 -450 {
lab=VOUT}
N 260 -500 260 -480 {lab=V1P}
N 130 -400 130 -380 {
lab=GND}
N 120 -350 130 -350 {
lab=GND}
N 130 -320 130 -300 {lab=V1N}
N 260 -420 260 -410 {
lab=VOUT}
N 260 -350 270 -350 {
lab=VOUT}
N 260 -410 260 -380 {
lab=VOUT}
N 130 -500 130 -480 {
lab=V1P}
N 120 -450 130 -450 {
lab=GND}
N 120 -450 120 -420 {
lab=GND}
N 120 -420 130 -420 {
lab=GND}
N 270 -450 270 -420 {
lab=VOUT}
N 260 -420 270 -420 {
lab=VOUT}
N 120 -380 120 -350 {
lab=GND}
N 120 -380 130 -380 {
lab=GND}
N 270 -380 270 -350 {
lab=VOUT}
N 260 -380 270 -380 {
lab=VOUT}
N 260 -320 260 -300 {
lab=V1N}
N 180 -240 180 -220 {
lab=VRFM}
N 200 -580 200 -560 {
lab=VRFP}
N 40 -400 130 -400 {
lab=GND}
N 130 -420 130 -400 {
lab=GND}
C {iopin.sym} 200 -580 2 0 {name=p8 lab=VRFP
}
C {iopin.sym} 180 -220 2 0 {name=p1 lab=VRFM

}
C {sg13g2_pr/sg13_lv_pmos.sym} 240 -450 2 1 {name=M3
l=\{L34\}
w=\{W34\}
ng=1
m=\{mult34\}
model=sg13_lv_pmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_nmos.sym} 150 -350 0 1 {name=M2
l=\{L12\}
w=\{W12\}
ng=1
m=\{mult12\}
model=sg13_lv_nmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_nmos.sym} 150 -450 2 0 {name=M1
l=\{L12\}
w=\{W12\}
ng=1
m=\{mult12\}
model=sg13_lv_nmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_pmos.sym} 240 -350 0 0 {name=M4
l=\{L34\}
w=\{W34\}
ng=1
m=\{mult34\}
model=sg13_lv_pmos
spiceprefix=X
}
C {gnd.sym} 40 -400 1 0 {name=l2 lab=GND}
C {devices/iopin.sym} 490 -410 0 0 {name=p5 lab=VOUT}
C {res.sym} 470 -380 0 0 {name=R1
value=\{R1v\}
footprint=1206
device=resistor
m=1}
C {gnd.sym} 470 -340 0 0 {name=l3 lab=GND
value=100p}
C {capa.sym} 380 -380 0 0 {name=C1
m=1
value=\{C1v\}
footprint=1206
device="ceramic capacitor"}
C {gnd.sym} 380 -340 0 0 {name=l4 lab=GND
value=100p}
C {vsource.sym} 100 -100 0 0 {name=VRF value="SIN(0 \{VAMPL\} \{FREQ\})" savecurrent=true}
C {iopin.sym} 100 -160 2 0 {name=p3 lab=VRFP}
C {iopin.sym} 100 -40 2 0 {name=p4 lab=VRFM}
C {devices/code_shown.sym} 10 -790 0 0 {name=MODEL1 only_toplevel=true
format="tcleval( @value )"
value="

.param corner=0

.if (corner==0)
.lib cornerMOSlv.lib mos_tt
.lib cornerRES.lib res_typ
.lib cornerCAP.lib cap_typ
.endif
"}
C {devices/code_shown.sym} 590 -730 0 0 {name=Parametros_CCDD
only_toplevel=true
spice_ignore=0
value="

.option wnflag=1
.savecurrents

* =============================
* PARAMETROS DE SIMULACION
* =============================

**** Parametros PMOS M3 y M4
.param L34 = 1u
.param W34 = 0.88u
.param mult34 = 1

**** Parametros NMOS M1 y M2
.param L12 = 1u
.param W12 = 0.2u
.param mult12 = 1

* ----------------
* Parametros PMOS M1
*.param Lval1 = 1u
*.param Wval1 = 0.15u
*.param mult1 = 1

* Parametros NMOS M2
*.param Lval2 = 1u
*.param Wval2 = 0.15u
*.param mult2 = 1

* Parametros NMOS M3
*.param Lval3 = 1u
*.param Wval3 = 0.15u
*.param mult3 = 1

* Parametros PMOS M4
*.param Lval4 = 1u
*.param Wval4 = 0.15u
*.param mult4 = 1
* --------------------

**** Parametros de Carga
.param C1v = 1p
.ic V(VOUT) = 0
.param R1v = 100k

**** Parametros de Acople
.param Csv = 1p



**** Parametros Fuente Sinusoidal
.param VAMPL = 0.1      ; Amplitud (V)
.param VOFFS = 0         ; Valor medio (V)
.param FREQ  = 900MEG        ; Frecuencia (Hz)
.param PHASE = 0         ; Fase1 (grados)



"}
C {code_shown.sym} 1070 -740 0 0 {name=Transiente_CCDD2
only_toplevel=false
spice_ignore=0

value="

.option wnflag=1
.savecurrents

* ==============================================
* BLOQUE DE CONTROL NGSPICE
* ==============================================
.control

**** Compatibilidad y Color
  set filetype = ascii
  set color0 = white

**** Inicializacion de Parametro While
  let k = 0
  let start_VRF = 0.3
  let stop_VRF = 1.2
  let delta_VRF = 0.1
  let VRF_act = start_VRF

**** Inicializacion Constantes para Calculos
  let i = 0
  let IDmax = 0
  let IGmax = 0
  let VDSmax = 0
  let VGSmax = 0

**** Variables Extriores


* ==============================================
* Inicio del While
* ==============================================
  while VRF_act le stop_VRF + 2*delta_VRF
    if k = 1
      tran 20p 500n UIC
    end
    alterparam VAMPL = $&VRF_act
    reset


* -----------------------------
* Almacenamiento de Variables
* -----------------------------
    save all

    **** M1
    save @n.xm1.nsg13_lv_nmos[ids]
    save @n.xm1.nsg13_lv_nmos[gm]
    save @n.xm1.nsg13_lv_nmos[gds]
    save @n.xm1.nsg13_lv_nmos[vth]

    **** M2
    save @n.xm2.nsg13_lv_nmos[ids]
    save @n.xm2.nsg13_lv_nmos[gm]
    save @n.xm2.nsg13_lv_nmos[gds]
    save @n.xm2.nsg13_lv_nmos[vth]

    **** M3
    save @n.xm3.nsg13_lv_pmos[ids]
    save @n.xm3.nsg13_lv_pmos[gm]
    save @n.xm3.nsg13_lv_pmos[gds]
    save @n.xm3.nsg13_lv_pmos[vth]

    **** M4
    save @n.xm4.nsg13_lv_pmos[ids]
    save @n.xm4.nsg13_lv_pmos[gm]
    save @n.xm4.nsg13_lv_pmos[gds]
    save @n.xm4.nsg13_lv_pmos[vth]
  
    **** Fuente de Voltaje
    save @VRF[i]
    save @VRF[p]

    **** Carga
    save R1[i]
    save C1[i]


* ----------------------------------------------
* Definicion de Varriables Internas
* ----------------------------------------------
    if k = 1

      **** M1
      let ids1 = @n.xm1.nsg13_lv_nmos[ids]
      let gm1 = @n.xm1.nsg13_lv_nmos[gm]
      let gds1 = @n.xm1.nsg13_lv_nmos[gds]
      let vth1 = @n.xm1.nsg13_lv_nmos[vth]
      let VDS1 = V1P - 0
      let VGS1 = V1N - 0

      **** M2
      let ids2 = @n.xm2.nsg13_lv_nmos[ids]
      let gm2 = @n.xm2.nsg13_lv_nmos[gm]
      let gds2 =  @n.xm2.nsg13_lv_nmos[gds]
      let vth2 = @n.xm2.nsg13_lv_nmos[vth]
      let VDS2 = V1N - 0
      let VGS2 = V1P - 0

      **** M3
      let ids3 = @n.xm3.nsg13_lv_pmos[ids]
      let gm3 = @n.xm3.nsg13_lv_pmos[gm]
      let gds3 = @n.xm3.nsg13_lv_pmos[gds]
      let vth3 = @n.xm3.nsg13_lv_pmos[vth]
      let VSD3 = VOUT - V1P
      let VSG3 = VOUT - V1N  

      **** M4
      let ids4 = @n.xm4.nsg13_lv_pmos[ids]
      let gm4 = @n.xm4.nsg13_lv_pmos[gm]
      let gds4 = @n.xm4.nsg13_lv_pmos[gds]
      let vth4 = @n.xm4.nsg13_lv_pmos[vth]
      let VSD4 = VOUT - V1N
      let VSG4 = VOUT - V1P

      **** Fuente de Voltaje
      let IRF = @VRF[i]
      let PRF = @VRF[p]
      let VRF = VRFP - VRFM

      **** Carga
      let IC = @C1[i]
      let IR = @R1[i]
      let IRC = IC + IR
      let PR = IR * VOUT

    end


* ==============================================
* RESULTADOS
* ==============================================

* -----------------------------
* Graficas de la Simulacion
* -----------------------------
    **** Fuente
    *plot VRF vs time
    *plot IRF vs time

    **** Carga
    plot VOUT VRF vs time
    *plot IRC vs time
    *plot avg(PR/PRF)

* -----------------------------
* Registro de Datos
* -----------------------------
    remzerovec
    write Memoria_CCDD2_TRAN_MULT1_L01-00_W00-20_R100k_M1_C01-00.csv time VRF IRF VOUT IC IR VDS1 VDS2 VSD3 VSD4 VGS1 VGS2 VSG3 VSG4 ids1 ids2 ids3 ids4 igs1 igs2 igs3 igs4 vth1 vth2 vth3 vth4


* ==============================================
* CIERRE DE WHILE
* ==============================================
    **** Definicion de proximo valor (while)
    let VRF_act = VRF_act + delta_VRF
    let k = 1
    set appendwrite

  end

.endc
"}
C {capa.sym} 200 -530 0 0 {name=C2
m=1
value=\{Csv\}
footprint=1206
device="ceramic capacitor"}
C {capa.sym} 180 -270 0 0 {name=C3
m=1
value=\{Csv\}
footprint=1206
device="ceramic capacitor"}
C {lab_pin.sym} 130 -500 1 0 {name=p2 sig_type=std_logic lab=V1P}
C {lab_pin.sym} 260 -300 3 0 {name=p6 sig_type=std_logic lab=V1N}
