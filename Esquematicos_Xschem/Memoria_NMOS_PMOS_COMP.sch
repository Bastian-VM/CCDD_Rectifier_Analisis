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
} -730 -680 0 0 0.4 0.4 {}
N 140 -230 140 -190 {
lab=VDn}
N 140 -300 140 -290 {
lab=VSn}
N 60 -260 100 -260 {
lab=VGn}
N 140 -260 150 -260 {
lab=VSn}
N 370 -220 370 -190 {
lab=VSn}
N 370 -330 370 -290 {
lab=VDn}
N 370 -260 380 -260 {
lab=VSn}
N 170 -130 170 -110 {
lab=VGn}
N 170 -50 170 -40 {
lab=GND}
N 60 -50 60 -40 {
lab=GND}
N 60 -130 60 -110 {
lab=VDn}
N 280 -50 280 -40 {
lab=GND}
N 280 -130 280 -110 {
lab=VSn}
N 380 -260 380 -220 {
lab=VSn}
N 370 -220 380 -220 {
lab=VSn}
N 370 -230 370 -220 {
lab=VSn}
N 290 -260 330 -260 {
lab=VGn}
N 150 -300 150 -260 {
lab=VSn}
N 140 -300 150 -300 {
lab=VSn}
N 140 -330 140 -300 {
lab=VSn}
C {lab_pin.sym} 60 -260 0 0 {name=p1 sig_type=std_logic lab=VGn
}
C {lab_pin.sym} 140 -190 0 0 {name=p2 sig_type=std_logic lab=VDn

}
C {lab_pin.sym} 140 -330 0 0 {name=p6 sig_type=std_logic lab=VSn
}
C {devices/code_shown.sym} 540 -690 0 0 {name=NMOS_Recorrido_VGS_y_VDS
only_toplevel=false
spice_ignore=0
value="


.option wnflag=1              ; Activa opción de simulación (warnings/flags específicos)
.savecurrents                 ; Guarda corrientes de nodos en la simulación

* ============================================================
* PARÁMETROS DE DISPOSITIVOS
* ============================================================
.param Lvaln = 0.2u           ; Longitud canal NMOS
.param Lvalp = 0.2u           ; Longitud canal PMOS
.param Wvaln = 0.6u            ; Ancho canal NMOS
.param Wvalp = 1.78u           ; Ancho canal PMOS
.param mvaln = 1              ; Multiplicidad NMOS
.param mvalp = 1              ; Multiplicidad PMOS


* ============================================================
* BLOQUE DE CONTROL DE SIMULACIÓN
* ============================================================
.control
  
  * Configuración general
  set filetype = ascii          ; Archivos de salida en formato ASCII
  set color0 = white            ; Fondo blanco en gráficas
  save all                      ; Guarda todas las variables de la simulación

  * Variables guardadas de NMOS y PMOS
  save @n.xm1.nsg13_lv_nmos[ids]    ; Corriente drenador NMOS
  *save @n.xm1.nsg13_lv_nmos[lp_cox]
  *save @n.xm1.nsg13_lv_nmos[cdg]
  *save @n.xm1.nsg13_lv_nmos[csg]
  *save @n.xm1.nsg13_lv_nmos[cgs]
  *save @n.xm1.nsg13_lv_nmos[lp_cgovd]
  save @n.xm2.nsg13_lv_pmos[ids]    ; Corriente drenador PMOS
  save @n.xm1.nsg13_lv_nmos[gm]     ; Transconductancia NMOS
  save @n.xm2.nsg13_lv_pmos[gm]     ; Transconductancia PMOS
  save @n.xm1.nsg13_lv_nmos[gds]    ; Conductancia salida NMOS
  save @n.xm2.nsg13_lv_pmos[gds]    ; Conductancia salida PMOS
  save @n.xm1.nsg13_lv_nmos[vth]    ; Voltaje umbral NMOS
  save @n.xm2.nsg13_lv_pmos[vth]    ; Voltaje umbral PMOS

* ============================================================
* BARRIDO DC
* ============================================================
  dc vd -0.9 0.9 0.1 vg -0.9 0.9 0.1

    * Definición de variables internas
    let IDSn  = @n.xm1.nsg13_lv_nmos[ids]
    let IDSp  = @n.xm2.nsg13_lv_pmos[ids]
    let gmn   = @n.xm1.nsg13_lv_nmos[gm]
    let gmp   = @n.xm2.nsg13_lv_pmos[gm]
    let gdsn  = @n.xm1.nsg13_lv_nmos[gds]
    let gdsp  = @n.xm2.nsg13_lv_pmos[gds]
    let VTHn  = @n.xm1.nsg13_lv_nmos[vth]
    let VTHp  = @n.xm2.nsg13_lv_pmos[vth]
    *let Coxn  = @n.xm1.nsg13_lv_nmos[lp_cox]
    *let Cdgn  = @n.xm1.nsg13_lv_nmos[cdg]
    *let Covdn = @n.xm1.nsg13_lv_nmos[lp_cgovd]
    *let Cgsn  = @n.xm1.nsg13_lv_nmos[csg]
    *let Csgn =  @n.xm1.nsg13_lv_nmos[cgs]
    let VDSn  = VDn - VSn
    let VGSn  = VGn - VSn

    * Inicialización de vectores parametros
    let n     = length(IDSn)
    let tol_i = 1e-10
    let IDSna = 0*v(VDSn)/v(VDSn)
    let IDSpa = 0*v(VDSn)/v(VDSn)
    let IDSpa2= 0*v(VDSn)/v(VDSn)

    * Acondicionamiento de corrientes NMOS
    let i = 0
    while i < n
      if IDSn[i] < tol_i
        let IDSna[i] = tol_i
      else
        let IDSna[i] = IDSn[i]
      end
      let i = i + 1
    end

    * Acondicionamiento de corrientes PMOS
    let i = 0
    while i < n
      if IDSp[i] < 1e-10
        let IDSpa2[i] = 1e-10
      else
        let IDSpa2[i] = IDSp[i]
      end
      let IDSpa[n-1-i] = IDSpa2[i]
      let i = i + 1
    end

* ============================================================
* GRÁFICAS
* ============================================================
  plot IDSn IDSp vs v(VDSn)                                         ; Corrientes absolutas vs VDS
  plot IDSna IDSpa vs v(VDSn)                                       ; Corrientes acondicionadas
  plot abs(IDSna-IDSpa)/abs(IDSna) vs v(VDSn) ylimit 0 1                    ; Error relativo
  plot deriv(IDSna)/deriv(VDSn) deriv(IDSpa)/deriv(VDSn) vs v(VDSn) ; Resistencia instantanea de canal
  

* ============================================================
* EXPORTACIÓN DE RESULTADOS
* ============================================================
  *write Memoria_NMOS_DC_L0-5uW0-15u.csv VDSn VGSn IDSn IDSp VTHn VTHp IDSna IDSpa

* ============================================================
* GRÁFICAS ADICIONALES (comentadas)
* ============================================================
  *plot gmn deriv(idsn) deriv(gmn) vs vds
  *plot gdsn vs vgs
  *plot 1/gdsn vs vgs ylimit 0 1G xlimit 0 0.5
  *plot log(idsn) vs vgs ylimit -20 -4
  *plot Coxn Cdgn Covdn Cgsn Csgn vs v(VGSn)

.endc
"}
C {lab_pin.sym} 290 -260 0 0 {name=p9 sig_type=std_logic lab=VGn
}
C {lab_pin.sym} 370 -330 0 0 {name=p10 sig_type=std_logic lab=VDn

}
C {lab_pin.sym} 370 -190 0 0 {name=p11 sig_type=std_logic lab=VSn

}
C {vsource.sym} 170 -80 0 0 {name=VG value="dc 0" savecurrent=true}
C {vsource.sym} 60 -80 0 0 {name=VD value="dc 2" savecurrent=true}
C {devices/gnd.sym} 170 -40 0 0 {name=l3 lab=GND}
C {devices/gnd.sym} 60 -40 0 0 {name=l5 lab=GND}
C {lab_pin.sym} 170 -130 0 0 {name=p13 sig_type=std_logic lab=VGn

}
C {lab_pin.sym} 60 -130 0 0 {name=p14 sig_type=std_logic lab=VDn

}
C {vsource.sym} 280 -80 0 0 {name=VSn value="dc 0" savecurrent=true
}
C {devices/gnd.sym} 280 -40 0 0 {name=l6 lab=GND}
C {lab_pin.sym} 280 -130 0 0 {name=p15 sig_type=std_logic lab=VSn
}
C {sg13g2_pr/sg13_lv_nmos.sym} 120 -260 0 0 {name=M1
l=\{Lvaln\}
w=\{Wvaln\}
ng=1
m=\{mvaln\}
model=sg13_lv_nmos
spiceprefix=X
}
C {sg13g2_pr/sg13_lv_pmos.sym} 350 -260 2 1 {name=M2
l=\{Lvalp\}
w=\{Wvalp\}
ng=1
m=\{mvalp\}
model=sg13_lv_pmos
spiceprefix=X
}
C {devices/code_shown.sym} 40 -670 0 0 {name=MODEL1 only_toplevel=true
format="tcleval( @value )"
value="

.param corner=0

.if (corner==0)
.lib cornerMOSlv.lib mos_tt
.lib cornerRES.lib res_typ
.lib cornerCAP.lib cap_typ
.endif
"}
