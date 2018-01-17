# Synopsys DC Script
# lim_core for SpMV
# 26 Nov, 2014
# Fazle Sadi <fsadi@andrew.cmu.edu>
#

# ================================ SETUP =================================
#Setting standard cell libraries - 28nm Samsung
set_app_var search_path "/afs/ece.cmu.edu/project/fabrics/SAMSUNG/sec_ip/ss28lpp/sc9_base_lvt/sv2p0p0/synopsys"
set ff_target_lib sc9_cmos28lpp_base_lvt_ff_nominal_min_1p210v_m40c_sadhm.db
set ss_target_lib sc9_cmos28lpp_base_lvt_ss_nominal_max_0p855v_125c_sadhm.db
set tt_target_lib sc9_cmos28lpp_base_lvt_tt_nominal_max_0p900v_25c.db

set target_lib_cmos14_usc /afs/ece/usr/fsadi/usc_libraries/cmos_14nm/cmos14nm_070.db
set target_lib_finfet7_usc /afs/ece/usr/fsadi/usc_libraries/finfet_7nm/FinFET_7nm_HVT_0450.db

set target_library $tt_target_lib

#Setting BRICK(BA+) macro libraries
lappend search_path "/afs/ece.cmu.edu/usr/fsadi/iarpa28/brick_lib_folder/sram_brick_32_8_v1"
set brick_lib_sram32x8_tt sram_brick_32_8_lib_TT.db
set brick_lib_sram32x8_ss sram_brick_32_8_lib_SS.db
set brick_lib_sram32x8_ff sram_brick_32_8_lib_FF.db

set brick_library1 $brick_lib_sram32x8_ss

############################  Library Definitions  ################################

set synth_libpath /afs/ece/support/synopsys/synopsys.release/syn-vG-2012.06-SP5-5/libraries/syn
set synth_libname dw_foundation 
set synthetic_library [format "%s/%s.sldb" $synth_libpath $synth_libname]

set_app_var link_library  [list $target_library $brick_lib_sram32x8_ss $synthetic_library "*"]
##################################################################

set_app_var search_path [concat $search_path ./src]

#./src/DW_fp_addsub.sv ./src/DW_fp_add.sv ./src/DW_fp_mult.sv

#### Add sources files here. Dependencies should be listed first
set src [list ./src/packages.vh ./src/register_definitions.sv ./src/decoder_mat_sram.sv ./src/lim_mat_storage.sv ./src/read_mat.sv ./src/decode.sv ./src/read_vec.sv ./src/multiply.sv ./src/addition_primary.sv ./src/wb_primary_result.sv ./src/pipeline1.sv ./src/min_find.sv ./src/presort.sv ./src/sort.sv ./src/read_prim_res.sv ./src/addition_intermediate_final.sv ./src/wb_inter_result.sv ./src/wb_final_result.sv ./src/pipeline2.sv ./src/lim_core.sv]

define_design_lib WORK -path "./work"

#./src/decoder_final_dram.sv ./src/decoder_inter_dram.sv ./src/decoder_mat_dram.sv ./src/decoder_mat_sram.sv ./src/decoder_primary_edram.sv ./src/decoder_vec_dram.sv ./src/decoder_vec_edram.sv


#### not sure why it cant read verilog with this command. try later
#read_verilog [list ./src/regfile.v ./src/shifter.sv ./src/check_condition.sv ./src/arm_alu.sv ./src/decode_part1.sv ./src/fetch_v1.sv ./src/decode_v1.sv ./src/execute_v1.sv ./src/memory_v1.sv ./src/arm_core.sv]

# Set top module
set TOP lim_core

analyze -format sverilog -lib WORK $src
elaborate $TOP -lib WORK -update
current_design $TOP

link
uniquify

################## Design constraints  ##############################

#Setting input/output load and driver constraints
## Wire load models are used only when Design Compiler is not operating in topographical mode.
#set auto_wire_load_selection true

# Samsung 28nm library capacitance unit is pF (not fF)
set_load 0.005 [all_outputs] 
#set_driving_cell -no_design_rule -library sc9_cmos28lpp_base_rvt_tt_nominal_max_0p900v_25c -lib_cell SEL_INV_1 [all_inputs]

# =============================== CLOCKING ===============================

#### The time unit is defined by the library. ps for 14, 7nm
## mult-factor is 1 for ns time unit and 1000 for ps time unit
set mult_factor 1

set period [expr ($mult_factor * 5) ]
set half_period [expr ($period * 0.5) ]

# Create real clock if clock port is found
if {[sizeof_collection [get_ports clk]] > 0} {
set clk_name clk
create_clock -period $period -waveform [list 0 $half_period] clk
}
# Create virtual clock if clock port is not found
if {[sizeof_collection [get_ports clk]] == 0} {
set clk_name vclk
create_clock -period $period -waveform [list 0 $half_period] -name vclk
}
# If real clock, set infinite drive strength
if {[sizeof_collection [get_ports clk]] > 0} {
set_drive 0 clk
}

# Apply default timing constraints for modules

set clk_latency [expr ($mult_factor * 0.1) ]
set clk_transition [expr ($mult_factor * 0.01) ]
set clk_setup_skew [expr ($mult_factor * 0.06) ]
set clk_hold_skew [expr ($mult_factor * 0.025) ]
set input_delay_val [expr ($mult_factor * 0.06) ]
set output_delay_val [expr ($mult_factor * 0.07) ]

set_clock_latency $clk_latency $clk_name
set_clock_transition $clk_transition $clk_name
set_clock_uncertainty -setup $clk_setup_skew $clk_name
set_clock_uncertainty -hold $clk_hold_skew $clk_name

set real_inputs [remove_from_collection [all_inputs] $clk_name]
set_input_delay $input_delay_val -clock $clk_name $real_inputs
set_output_delay $output_delay_val -clock $clk_name [all_outputs]

#** Note that since this is still a pre-layout design we also had to set the set_dont_touch_network
#** attribute on the clock network. Setting this attribute prevents Design Compiler from modifying 
#** the cells or nets in the clock network or from inserting buffers on the clock network. This is 
#** needed since usually physical layout data is required for clock tree synthesis (CTS).
set_dont_touch_network $clk_name
#set_dont_touch_network {$clk_name, rst_n}

#** Reset net is another High-Fanout Net (HFN) that should be balanced by a backend tool. Therefore, 
#** we need to tell Design Compiler that it should rather ignore than try to fix possible timing/DRC 
#** violations on the reset net.
#set_dont_touch rst_n
#set_ideal_network rst_n

#** This command is particularly useful with designs that are pipelined. The command reshuffles the 
#** logic from one pipeline stage to another. This allows extra logic to be moved away from overly 
#** constrained pipeline stages to less constrained ones with additional timing.
#balance_registers

#set_max_delay .05 [all_outputs]

## setting max area to 0 makes the area as small as possible
set_max_area 0

# Prior to compiling the datapath blocks, enable power analysis:
set synlib_enable_analyze_dw_power 1

# Use report_timing -loops to view all timing loops in your design. Use set_disable_timing to manualy break the loops.
#report_timing -loops 
# =============================== REPORTS ================================

check_design
compile_ultra;
ungroup -flatten -all

# Got from solvenet - this reportspercentage of datapath
analyze_datapath

# to check how many sequential cells are not user annotated
# report_saif -type rtl -flat -missing

## Use the report_lib command to list the library units
# report_lib USERLIB_tt_1p000v_1p000v_25c > lib_units.rpt
report_lib sc9_cmos28lpp_base_rvt_tt_nominal_max_0p900v_25c > lib_units.rpt
report_area > area.rpt
report_timing > timing.rpt
report_power > power.rpt
# for DW datapath area and blocks
report_area -designware > area_dw.rpt
report_resources -hier > resource.rpt 
# for DW minPower block's power report
analyze_dw_power -hier > power_dw.rpt

write -format verilog -output ${TOP}.mapped.v
write -format ddc -hierarchy -output ${TOP}.ddc
write_sdf ${TOP}.sdf
write_sdc -nosplit ${TOP}.sdc
#write_milkyway -overwrite -output "design_rtl_DCT"
check_design >> check_design.log

#** For design vision do 
#** design_vision-xg -64bit
#** read_ddc arm_core.mapped.ddc
#** or for GUI
#** read -> locate the .ddc

exit
