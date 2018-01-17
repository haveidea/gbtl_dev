export VERDI_HOME=/afs/ece.cmu.edu/support/synopsys/synopsys.release/L-Foundation/2016.06/verdi_vL-2016.06
rm -rf lib_vhdl lib_verilog work
rm -rf simv.daidir
rm -rf csrc
mkdir -p lib_vhdl
mkdir -p lib_verilog
mkdir -p work
###vhdlan -full64  ../memory_bist_with_parity.vhd ../origin.vhd ../pkg_global.vhd ../retime.vhd ../wide_prbs_gen.vhd
##vhdlan -work LIB_VHDL -full64 -smart_order ../pkg_global.vhd ../retime.vhd ../wide_prbs_gen.vhd ../memory_bist_with_parity.vhd    ../origin.vhd -l vhdlan.log -verbose
##vlogan -full64 -work LIB_VERILOG -y ./lib_vhdl -P ${VERDI_HOME}/share/PLI/VCS/linux64/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux64/pli.a -f flist_verilog.f -sverilog 
###vhdlan -full64 -work LIB_VHDL ../memory_bist_with_parity.vhd ../origin.vhd ../pkg_global.vhd ../retime.vhd ../wide_prbs_gen.vhd
###vlogan -full64 -work LIB_VERILOG -P ${VERDI_HOME}/share/PLI/VCS/linux64/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux64/pli.a -f flist_verilog.f -sverilog
##vcs  tb -lib lib_vhdl:lib_verilog -full64 -P ${VERDI_HOME}/share/PLI/VCS/linux64/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux64/pli.a -f flist_verilog.f -sverilog



#vhdlan -work LIB_VHDL -smart_order ../pkg_global.vhd ../retime.vhd ../wide_prbs_gen.vhd ../memory_bist_with_parity.vhd    ../origin.vhd -l vhdlan.log -verbose -full64
#vlogan -f flist_verilog.f -sverilog -P ${VERDI_HOME}/share/PLI/VCS/linux64/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux64/pli.a  -full64
##vlogan -P ${VERDI_HOME}/share/PLI/VCS/linux/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux/pli.a -f flist_verilog.f -sverilog 
#vcs  -R tb -vhdllib+lib_vhdl -P ${VERDI_HOME}/share/PLI/VCS/linux64/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux64/pli.a  -full64



##vhdlan -full64 -work LIB_VHDL -smart_order ../pkg_global.vhd ../retime.vhd ../wide_prbs_gen.vhd ../memory_bist_with_parity.vhd    ../origin.vhd -l vhdlan.log -verbose 
##vlogan -full64 -f flist_verilog.f -sverilog  
###vlogan -P ${VERDI_HOME}/share/PLI/VCS/linux/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux/pli.a -f flist_verilog.f -sverilog 
##vcs  -full64 -R tb -vhdllib+lib_vhdl 



#vhdlan -full64 -work LIB_VHDL -smart_order ../pkg_global.vhd ../retime.vhd ../wide_prbs_gen.vhd ../memory_bist_with_parity.vhd    ../origin.vhd -l vhdlan.log -verbose 
#vlogan -full64 -f flist_verilog.f -sverilog  -P ${VERDI_HOME}/share/PLI/VCS/linux64/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux64/pli.a 
#vcs  -full64 tb -P ${VERDI_HOME}/share/PLI/VCS/linux64/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux64/pli.a 

#vhdlan -full64 -work LIB_VHDL -smart_order ../pkg_global.vhd ../retime.vhd ../wide_prbs_gen.vhd ../memory_bist_with_parity.vhd    ../origin.vhd -l vhdlan.log -verbose 
#vlogan -full64 -f flist_verilog.f -sverilog  -debug_pp -P ${VERDI_HOME}/share/PLI/VCS/linux64/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux64/pli.a 
#vcs  -R -full64 tb -debug_pp -P ${VERDI_HOME}/share/PLI/VCS/linux64/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux64/pli.a 


vhdlan -full64 -work LIB_VHDL -smart_order ../pkg_global.vhd ../retime.vhd ../wide_prbs_gen.vhd ../memory_bist_with_parity.vhd    ../origin.vhd -l vhdlan.log -verbose 
vlogan -full64 -f flist_verilog.f -sverilog  -debug_pp 
vcs  -R -full64 tb -debug_pp +vcs+loopreport +vcs+loopdetect -l sim.log
vpd2fsdb tb.vpd
grep "M0.*address 02" sim.log> M2.dat
grep "M0.*address 01" sim.log> M1.dat
grep "S1.*address" sim.log> S1.dat
grep "S2.*address" sim.log> S2.dat
grep "M0_s1.*read data" sim.log> M1_data.dat
grep "M0_s2.*read data" sim.log> M2_data.dat
grep "S1.*read data" sim.log> S1_data.dat
grep "S2.*read data" sim.log> S2_data.dat
