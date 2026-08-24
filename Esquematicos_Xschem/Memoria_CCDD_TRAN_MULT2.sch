v {xschem version=3.4.5 file_version=1.2
}
G {}
K {}
V {}
S {}
E {}
N 630 -170 650 -170 {lab=V1P}
N 630 -320 690 -320 {lab=V1P}
N 610 -270 650 -270 {lab=V1N}
N 630 -320 630 -170 {lab=V1P}
N 600 -170 630 -170 {lab=V1P}
N 560 -320 630 -320 {lab=V1P}
N 610 -120 690 -120 {lab=V1N}
N 610 -270 610 -120 {lab=V1N}
N 600 -270 610 -270 {lab=V1N}
N 560 -120 610 -120 {lab=V1N}
N 690 -230 920 -230 {lab=VOUT}
N 900 -170 900 -160 {lab=GND}
N -190 -140 -190 -110 {
lab=VRFP}
N -190 -50 -190 -20 {
lab=VRFM}
N 810 -170 810 -160 {
lab=GND}
N 690 -270 700 -270 {
lab=VOUT}
N 690 -320 690 -300 {lab=V1P}
N 550 -170 560 -170 {
lab=VO2}
N 560 -140 560 -120 {lab=V1N}
N 690 -240 690 -230 {
lab=VOUT}
N 690 -170 700 -170 {
lab=VOUT}
N 690 -230 690 -200 {
lab=VOUT}
N 560 -320 560 -300 {
lab=V1P}
N 550 -270 560 -270 {
lab=VO2}
N 550 -270 550 -240 {
lab=VO2}
N 550 -240 560 -240 {
lab=VO2}
N 700 -270 700 -240 {
lab=VOUT}
N 690 -240 700 -240 {
lab=VOUT}
N 550 -200 550 -170 {
lab=VO2}
N 550 -200 560 -200 {
lab=VO2}
N 700 -200 700 -170 {
lab=VOUT}
N 690 -200 700 -200 {
lab=VOUT}
N 690 -140 690 -120 {
lab=V1N}
N 610 -60 610 -40 {
lab=VRFM}
N 630 -400 630 -380 {
lab=VRFP}
N 560 -220 560 -200 {
lab=VO2}
N 190 -170 210 -170 {lab=V2P}
N 190 -320 250 -320 {lab=V2P}
N 170 -270 210 -270 {lab=V2N}
N 190 -320 190 -170 {lab=V2P}
N 160 -170 190 -170 {lab=V2P}
N 120 -320 190 -320 {lab=V2P}
N 170 -120 250 -120 {lab=V2N}
N 170 -270 170 -120 {lab=V2N}
N 160 -270 170 -270 {lab=V2N}
N 120 -120 170 -120 {lab=V2N}
N 390 -160 390 -150 {
lab=GND}
N 250 -270 260 -270 {
lab=VO2}
N 250 -320 250 -300 {lab=V2P}
N 120 -220 120 -200 {
lab=GND}
N 110 -170 120 -170 {
lab=GND}
N 120 -140 120 -120 {lab=V2N}
N 250 -220 250 -200 {
lab=VO2}
N 250 -170 260 -170 {
lab=VO2}
N 120 -320 120 -300 {
lab=V2P}
N 110 -270 120 -270 {
lab=GND}
N 110 -270 110 -240 {
lab=GND}
N 110 -240 120 -240 {
lab=GND}
N 260 -270 260 -240 {
lab=VO2}
N 250 -240 260 -240 {
lab=VO2}
N 110 -200 110 -170 {
lab=GND}
N 110 -200 120 -200 {
lab=GND}
N 260 -200 260 -170 {
lab=VO2}
N 250 -200 260 -200 {
lab=VO2}
N 250 -140 250 -120 {
lab=V2N}
N 170 -60 170 -40 {
lab=VRFM}
N 190 -400 190 -380 {
lab=VRFP}
N 30 -220 120 -220 {
lab=GND}
N 120 -240 120 -220 {
lab=GND}
N 250 -220 560 -220 {
lab=VO2}
N 250 -240 250 -220 {
lab=VO2}
N 560 -240 560 -220 {
lab=VO2}
C {devices/code_shown.sym} 30 70 0 0 {name=Parametros_CCDD
only_toplevel=true
spice_ignore=0
value="

.option wnflag=1
.savecurrents

* =============================
* PARAMETROS DE SIMULACION
* =============================

**** Parametros PMOS M3 y M4
.param L34 = 0.2u
.param W34 = 1.78u
.param mult34 = 20

**** Parametros NMOS M1 y M2
.param L12 = 0.2u
.param W12 = 0.6u
.param mult12 = 20

* Parametros PMOS M1
*.param Lval1 = 0.13u
*.param Wval1 = 0.15u
*.param mult1 = 5

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

**** Parametros de Carga
.param C1v = 1p
.ic V(VOUT) = 0
.param R1v = 100k

**** Parametros de Acople
.param Csv = 1p
.param Cav2 = 2*1p
*.param Cav3 = 3*1p
*.param Cav4 = 4*1p
*.param Cav5 = 5*1p

**** Parametros Fuente Sinusoidal
.param VAMPL = 0.1      ; Amplitud (V)
.param VOFFS = 0         ; Valor medio (V)
.param FREQ  = 900MEG        ; Frecuencia (Hz)
.param PHASE = 0         ; Fase1 (grados)



"}
C {code_shown.sym} 470 60 0 0 {name=Transiente_CCDD2
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

    **** M2
    save @n.xm2.nsg13_lv_nmos[ids]
    save @n.xm2.nsg13_lv_nmos[igs]
    save @n.xm2.nsg13_lv_nmos[gm]
    save @n.xm2.nsg13_lv_nmos[gds]
    save @n.xm2.nsg13_lv_nmos[vth]

    **** M6
    save @n.xm6.nsg13_lv_nmos[ids]
    save @n.xm6.nsg13_lv_nmos[igs]
    save @n.xm6.nsg13_lv_nmos[gm]
    save @n.xm6.nsg13_lv_nmos[gds]
    save @n.xm6.nsg13_lv_nmos[vth]

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

      **** M2
      let ids2 = @n.xm2.nsg13_lv_nmos[ids]
      let igs2 = @n.xm2.nsg13_lv_nmos[igs]
      let gm2 = @n.xm2.nsg13_lv_nmos[gm]
      let gds2 =  @n.xm2.nsg13_lv_nmos[gds]
      let vth2 = @n.xm2.nsg13_lv_nmos[vth]
      let VDS2 = V1N - VO2
      let VGS2 = V1P - VO2

      **** M6
      let ids6 = @n.xm6.nsg13_lv_nmos[ids]
      let igs6 = @n.xm6.nsg13_lv_nmos[igs]
      let gm6 = @n.xm6.nsg13_lv_nmos[gm]
      let gds6 =  @n.xm6.nsg13_lv_nmos[gds]
      let vth6 = @n.xm6.nsg13_lv_nmos[vth]
      let VDS6 = V2N - 0
      let VGS6 = V2P - 0

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
    if k = 1
    **** Fuente
    *plot VRF vs time
    *plot IRF vs time

    **** Carga
    plot VOUT VRF vs time
    *plot IRC vs time
    *plot avg(PR/PRF)
    end
* -----------------------------
* Registro de Datos
* -----------------------------
    remzerovec
    write Memoria_CCDD2_TRAN_MULT2_L00-20_W00-60_R100k_M20_C01-00.csv time VRF IRF VOUT VO2 IC IR VDS2 VDS6 VGS2 VGS6 ids2 ids6 igs2 igs6


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
C {iopin.sym} 630 -400 2 0 {name=p8 lab=VRFP
}
C {iopin.sym} 610 -40 2 0 {name=p1 lab=VRFM

}
C {sg13g2_pr/sg13_lv_pmos.sym} 670 -270 2 1 {name=M3
l=\{L34\}
w=\{W34\}
ng=1
m=\{mult34\}
model=sg13_lv_pmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_nmos.sym} 580 -170 0 1 {name=M2
l=\{L12\}
w=\{W12\}
ng=1
m=\{mult12\}
model=sg13_lv_nmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_nmos.sym} 580 -270 2 0 {name=M1
l=\{L12\}
w=\{W12\}
ng=1
m=\{mult12\}
model=sg13_lv_nmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_pmos.sym} 670 -170 0 0 {name=M4
l=\{L34\}
w=\{W34\}
ng=1
m=\{mult34\}
model=sg13_lv_pmos
spiceprefix=X
}
C {devices/iopin.sym} 920 -230 0 0 {name=p5 lab=VOUT}
C {res.sym} 900 -200 0 0 {name=R1
value=\{R1v\}
footprint=1206
device=resistor
m=1}
C {gnd.sym} 900 -160 0 0 {name=l3 lab=GND
value=100p}
C {capa.sym} 810 -200 0 0 {name=C1
m=1
value=\{C1v\}
footprint=1206
device="ceramic capacitor"}
C {gnd.sym} 810 -160 0 0 {name=l4 lab=GND
value=100p}
C {vsource.sym} -190 -80 0 0 {name=VRF value="SIN(0 \{VAMPL\} \{FREQ\})" savecurrent=true}
C {iopin.sym} -190 -140 2 0 {name=p3 lab=VRFP}
C {iopin.sym} -190 -20 2 0 {name=p4 lab=VRFM}
C {capa.sym} 630 -350 0 0 {name=C2
m=1
value=\{Csv\}
footprint=1206
device="ceramic capacitor"}
C {capa.sym} 610 -90 0 0 {name=C3
m=1
value=\{Csv\}
footprint=1206
device="ceramic capacitor"}
C {devices/code_shown.sym} -310 -430 0 0 {name=MODEL1 only_toplevel=true
format="tcleval( @value )"
value="

.param corner=0

.if (corner==0)
.lib cornerMOSlv.lib mos_tt
.lib cornerRES.lib res_typ
.lib cornerCAP.lib cap_typ
.endif
"}
C {iopin.sym} 190 -400 2 0 {name=p2 lab=VRFP
}
C {iopin.sym} 170 -40 2 0 {name=p6 lab=VRFM

}
C {sg13g2_pr/sg13_lv_pmos.sym} 230 -270 2 1 {name=M5
l=\{L34\}
w=\{W34\}
ng=1
m=\{mult34\}
model=sg13_lv_pmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_nmos.sym} 140 -170 0 1 {name=M6
l=\{L12\}
w=\{W12\}
ng=1
m=\{mult12\}
model=sg13_lv_nmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_nmos.sym} 140 -270 2 0 {name=M7
l=\{L12\}
w=\{W12\}
ng=1
m=\{mult12\}
model=sg13_lv_nmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_pmos.sym} 230 -170 0 0 {name=M8
l=\{L34\}
w=\{W34\}
ng=1
m=\{mult34\}
model=sg13_lv_pmos
spiceprefix=X
}
C {gnd.sym} 30 -220 1 0 {name=l1 lab=GND}
C {capa.sym} 390 -190 0 0 {name=C4
m=1
value=\{Cav2\}
footprint=1206
device="ceramic capacitor"}
C {gnd.sym} 390 -150 0 0 {name=l6 lab=GND
value=100p}
C {capa.sym} 190 -350 0 0 {name=C5
m=1
value=\{Csv\}
footprint=1206
device="ceramic capacitor"}
C {capa.sym} 170 -90 0 0 {name=C6
m=1
value=\{Csv\}
footprint=1206
device="ceramic capacitor"}
C {lab_pin.sym} 560 -320 1 0 {name=p7 sig_type=std_logic lab=V1P}
C {lab_pin.sym} 690 -120 3 0 {name=p9 sig_type=std_logic lab=V1N}
C {lab_pin.sym} 410 -220 1 0 {name=p10 sig_type=std_logic lab=VO2}
C {lab_pin.sym} 120 -320 1 0 {name=p11 sig_type=std_logic lab=V2P}
C {lab_pin.sym} 250 -120 3 0 {name=p12 sig_type=std_logic lab=V2N}
