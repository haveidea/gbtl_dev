#DEFINE = +define+DUMMY
DEFINE += +define+SIMU
VERDI_HOME=/afs/ece.cmu.edu/support/synopsys/synopsys.release/L-Foundation/2016.06/verdi_vL-2016.06
#QUARTUS_INSTALL_DIR="/afs/ece.cmu.edu/usr/jingh1/edatools/intelFPGA_pro/quartus"


 VCS_COMPILE_OPTS += -full64 
#VCS_COMPILE_OPTS += -P ${VERDI_HOME}/share/PLI/VCS/linux64/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux64/pli.a 
#VCS_COMPILE_OPTS += -P ${VERDI_HOME}/share/PLI/VCS/linux64/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux64/pli.a 
 VCS_COMPILE_OPTS  += -debug_pp -sverilog 
# VCS_COMPILE_OPTS  += +lint=PCWM
# VCS_COMPILE_OPTS  += +lint=TFIPC-L
 VCS_COMPILE_OPTS  += -sverilog 
 #VCS_COMPILE_OPTS  += -lca -sverilog +verilog2001ext+.v -ntb_opts dtm
# VCS_COMPILE_OPTS  +=   -v ${QUARTUS_INSTALL_DIR}/eda/sim_lib/altera_primitives.v 
# VCS_COMPILE_OPTS  +=   -v ${QUARTUS_INSTALL_DIR}/eda/sim_lib/220model.v 
# VCS_COMPILE_OPTS  +=   -v ${QUARTUS_INSTALL_DIR}/eda/sim_lib/sgate.v 
# VCS_COMPILE_OPTS  +=   -v ${QUARTUS_INSTALL_DIR}/eda/sim_lib/altera_mf.v 
# VCS_COMPILE_OPTS  +=   -v ${QUARTUS_INSTALL_DIR}/eda/sim_lib/altera_lnsim.sv 
# VCS_COMPILE_OPTS  +=   -v ${QUARTUS_INSTALL_DIR}/eda/sim_lib/twentynm_atoms.v 
# VCS_COMPILE_OPTS  +=   -v ${QUARTUS_INSTALL_DIR}/eda/sim_lib/synopsys/twentynm_atoms_ncrypt.v 
# VCS_COMPILE_OPTS  +=   -v ${QUARTUS_INSTALL_DIR}/eda/sim_lib/synopsys/twentynm_hssi_atoms_ncrypt.v 
# VCS_COMPILE_OPTS  +=   -v ${QUARTUS_INSTALL_DIR}/eda/sim_lib/twentynm_hssi_atoms.v 
# VCS_COMPILE_OPTS  +=   -v ${QUARTUS_INSTALL_DIR}/eda/sim_lib/synopsys/twentynm_hip_atoms_ncrypt.v 
# VCS_COMPILE_OPTS  +=   -v ${QUARTUS_INSTALL_DIR}/eda/sim_lib/twentynm_hip_atoms.v 


 VCS_COMMON_OPTS += -ucli 
 VCS_COMMON_OPTS += +cli+2
# VCS_COMMON_OPTS += +fsdb+mda=on
 VCS_COMMON_OPTS += +vcs+loopreport
 VCS_COMMON_OPTS += +vcs+loopdetect

 VCS_RUN_OPTS = 

#VERDI_OPTS = -workMode protocolDebug
 VERDI_OPTS = -workMode hardwareDebug ${DEFINE}

vcs: 
	vcs  -f flist.f  ${VCS_COMPILE_OPTS} ${VCS_COMMON_OPTS} -l vcs.log  ${VCS_RUN_OPTS} -R

compile:
	vcs  -f flist.f  ${VCS_COMPILE_OPTS} ${VCS_COMMON_OPTS} -l sim.log 

run:
	./simv   ${VCS_COMMON_OPTS} ${VCS_RUN_OPTS} -l run.log

verdi:
	verdi -f flist.f -sv ${VERDI_OPTS}

clean:
	rm -rf csrc simv.daidir simv verdiLog vpd2fsdbLog *.log novas* ucli.key

fsdb:
	vpd2fsdb tb.vpd

