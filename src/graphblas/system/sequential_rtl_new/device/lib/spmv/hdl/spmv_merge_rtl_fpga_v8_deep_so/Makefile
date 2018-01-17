
#Makefile for ncverilog simulation and synthesize

###################################################################
### Setup
###################################################################
#TIMESTAMP := outputs/$(shell date +%m%d-%H%M%S)
WORKLIB = worklib
WORKLIBLOGICAL = wlib
SOURCE = src
OUTPUT = run_dir
INPUT = input
#TB = tb_top_merge_core
TB = tb_merge_core

SYNTHDIR = dc
SYNTH = dc_script.tcl

###################################################################
### Constants
###################################################################

# text attributes: normal, bold, underline
n=\e[0m
b=\e[1m
u=\e[4m

# bold+green
g=\e[1;32m

# bold+red
r=\e[1;31m

# debug message
m=$gsimulation Makefile: $n


###################################################################
### Help Screen
###################################################################

default:
	@echo -e "$mHELP SCREEN"
	@echo -e ""
	@echo -e "$bUSAGE:$n"
	@echo -e "\tmake $uTARGET$n [$uVARIABLE$n]..."
	@echo -e ""
	@echo -e ""
	@echo -e "$bTARGET:$n"
	@echo -e "\t$bsim$n"
	@echo -e "\t    compiles Verilog found in $usrc$n directory;"
	@echo -e "\t    simulates Verilog using $bINPUT$n as input;"
	@echo -e "\t    places all outputs (logs, waveforms, regdump, etc.) in $bOUTPUT$n"
	@echo -e ""
	@echo -e "\t$bverify$n"
	@echo -e "\t    compiles Verilog found in $usrc$n directory;"
	@echo -e "\t    simulates Verilog using $bINPUT$n as input;"
	@echo -e "\t    places all outputs (logs, waveforms, regdump, etc.) in $bOUTPUT$n"
	@echo -e "\t    verifies the simulation register-dump against the reference"
	@echo -e ""
	@echo -e "\t$bbatch-verify$n"
	@echo -e "\t    similar to $bverify$n, but uses $bBATCH$n as input"
	@echo -e ""
	@echo -e "\t$bsynth$n"
	@echo -e "\t    compiles Verilog found in $usrc$n directory;"
	@echo -e "\t    synthesizes Verilog"
	@echo -e "\t    places all outputs (reports, schematics, etc.) in $bOUTPUT$n"
	@echo -e ""
	@echo -e "\t$bauto$n"
	@echo -e "\t    automatically \"wires\" up Verilog modules found in $usrc/*.v$n;"
	@echo -e "\t    (not mandatory -- merely for your convenience)"
	@echo -e ""
	@echo -e ""
	@echo -e "$bVARIABLE:$n"
	@echo -e "\t$bINPUT$n=$uASSEMBLY$n"
	@echo -e "\t    for $bsim$n and $bverify$n, specifies an input ARM assemply file;"
	@echo -e "\t    if unspecified, defaults to $u447inputs/addiu.s$n"
	@echo -e ""
	@echo -e "\t$bBATCH$n=$uASSEMBLY FILES$n"
	@echo -e "\t    for $bbatch-verify$n, specifies one or more input ARM assemply files;"
	@echo -e "\t    if unspecified, defaults to $u447inputs/addiu.s$n"
	@echo -e ""
	@echo -e "\t$bOUTPUT$n=$uDIR$n"
	@echo -e "\t    for all targets, specifies the output directory;"
	@echo -e "\t    if unspecified, defaults to $uoutputs/current-timestamp$n;"
	@echo -e ""
	@echo -e ""
	@echo -e "$bEXAMPLES:$n"
	@echo -e "\tmake sim"
	@echo -e "\tmake sim INPUT=inputs/mytest.s OUTPUT=outputs/myoutput"
	@echo -e "\tmake verify"
	@echo -e "\tmake verify INPUT=inputs/mytest.s OUTPUT=outputs/myoutput"
	@echo -e "\tmake batch-verify BATCH=447inputs/*.s"
	@echo -e "\tmake batch-verify BATCH=447inputs/*.s OUTPUT=outputs/myoutput"
	@echo -e "\tmake synth"
	@echo -e "\tmake synth OUTPUT=outputs/myoutput"
	@echo -e ""
	@echo -e "(END)"
	@exit 0

###################################################################
### Generate the encoder verilog code from defined WL width
###################################################################
verilog:
	@cd $(SOURCE)/; chmod +x ./definitions.py; ./definitions.py
	@cd $(SOURCE)/; chmod +x ./encoder_brick.py; ./encoder_brick.py
	@cd $(SOURCE)/; chmod +x ./decoder_blk_slow_rd.py; ./decoder_blk_slow_rd.py 
	@cd $(SOURCE)/; chmod +x ./decoder_blk_slow_wr.py; ./decoder_blk_slow_wr.py

###################################################################
### Compile Verilog
###################################################################

compile:
	@echo -e "$mMaking WORK directory..."
	@mkdir -p $(OUTPUT)/sim/$(WORKLIB)
	@mkdir -p $(OUTPUT)/sim/$(INPUT)
	@cp -rf $(INPUT)/* $(OUTPUT)/sim/$(INPUT)		
	@cp cds.lib $(OUTPUT)/sim
	@cp hdl.var $(OUTPUT)/sim
	@echo -e "$mCopying Verilog into $(OUTPUT)..."
	@mkdir -p $(OUTPUT)/sim/src
	@rm -rf $(OUTPUT)/sim/src/*
#	@cp `find $(SOURCE) -iname '*.sv' -o -iname '*.v' -o -iname '*.vh'` $(OUTPUT)/sim/src
	@cp `find $(SOURCE) -iname '*.sv' -o -iname '*.vh'` $(OUTPUT)/sim/src
#	@cp $(SOURCE)/definitions.vh $(SOURCE)/sram_brick_generic.sv  $(SOURCE)/wl_encoder_generic.sv $(SOURCE)/decoder_generic.sv $(SOURCE)/spmv_core.sv $(SOURCE)/tb_v1.sv $(OUTPUT)/sim/src
	@echo -e "$mCompiling Verilog..."
	cd $(OUTPUT)/sim; ncvlog -64bit -sv -linedebug -messages -incdir src src/*.sv 
	@if grep '*W' $(OUTPUT)/sim/ncvlog.log >/dev/null; \
		then echo -e '$m$rCompiler log has warnings!$n'; fi
	@echo -e "$mElaborating Verilog..."
	cd $(OUTPUT)/sim; ncelab -64bit -disable_sem2009 -timescale 100ps/10ps +access+rwc -messages $(WORKLIBLOGICAL).$(TB)
	@if grep '*W' $(OUTPUT)/sim/ncelab.log >/dev/null; \
		then echo -e '$m$rElaborator log has warnings!$n'; fi


###################################################################
### Assemble ARM Assembly Input
###################################################################

#assemble:
#	@echo -e "$mCopying $(INPUT) into $(OUTPUT)..."
#	@mkdir -p $(OUTPUT)/sim
#	@([ -f $(INPUT) ] && cp $(INPUT) $(OUTPUT)/sim) || \
#		(echo -e "$mERROR -- test input not found: $(INPUT)"; exit 1)
#	@echo -e "$mAssemblying input in $(OUTPUT)..."
#	arm2hex $(INPUT) $(OUTPUT)/sim/mem.text.dat;


###################################################################
### Simulate Verilog
###################################################################

sim: compile 
	@echo -e "$mCopying NCSim configuration into $(OUTPUT)..."
	@cp ncsim/* $(OUTPUT)/sim
	@echo -e "$mSimulating Verilog in $(OUTPUT)..."
	cd $(OUTPUT)/sim; ncsim -64bit $(WORKLIBLOGICAL).$(TB):module -input ncsim.tcl
	@if grep '*W' $(OUTPUT)/sim/ncsim.log >/dev/null; \
		then echo -e '$m$rSimulator log has warnings!$n'; fi
	@echo -e "$mSimulation of $(INPUT) has completed in $(OUTPUT)."
	@echo -e "$mTo view waveforms, execute the following command: $bsimvision $(OUTPUT)/sim/waveforms.shm$n"


###################################################################
### Synthesize Verilog
###################################################################

synth:
	@mkdir -p $(OUTPUT)/synth/src
	@rm -rf $(OUTPUT)/synth/src/*
	@cp `find src -iname '*.sv' -o -iname '*.vh'` $(OUTPUT)/synth/src
	@cp $(SYNTHDIR)/$(SYNTH) $(OUTPUT)/synth
	@cd $(OUTPUT)/synth; dc_shell-xg-t -f $(SYNTH)
	@echo -e "$mSynthesis has completed in $(OUTPUT)."
	@echo -e "Timing results can be found at $(OUTPUT)/synth/reports/timing.rpt"
