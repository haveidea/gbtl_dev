#Setting up general variables
set TOP "merge_blk_slow"
define_design_lib WORK -path "./work"

# ========================================== Libraries =========================================
# Setting standard cell libraries - 28nm Samsung
set_app_var search_path "/afs/ece.cmu.edu/project/fabrics/SAMSUNG/sec_ip/ss28lpp/sc9_base_lvt/sv2p0p0/synopsys"
set ff_target_lib sc9_cmos28lpp_base_lvt_ff_nominal_min_1p210v_m40c_sadhm.db
set ss_target_lib sc9_cmos28lpp_base_lvt_ss_nominal_max_0p855v_125c_sadhm.db
set tt_target_lib sc9_cmos28lpp_base_lvt_tt_nominal_max_0p900v_25c.db
set_app_var target_library $ss_target_lib
#set target_library $ss_target_lib

#set brick_library_path /afs/ece.cmu.edu/usr/kuntals/Samsung_28nm_PDK/TestChip/BA_libs
set brick_library_path /afs/ece.cmu.edu/usr/misgenc/tapeout/iarpa_TIC_28nm_Samsung/cadence/FINALIZED_LAYOUT_03_12_15/LIB_FOLDERS
set mem_lib_sram32x8_TT $brick_library_path/sram_brick_32_8_lib_TT.db
set mem_lib_sram32x8_FF $brick_library_path/sram_brick_32_8_lib_FF.db
set mem_lib_sram32x8_SS $brick_library_path/sram_brick_32_8_lib_SS.db
 
#set brick_library1 $mem_lib_sram32x8_SS

# =================================== DesignWare Library =======================================
set synth_libpath /afs/ece/support/synopsys/synopsys.release/syn-vG-2012.06-SP5-5/libraries/syn
set synth_libname dw_foundation 
set synthetic_library [format "%s/%s.sldb" $synth_libpath $synth_libname]

set_app_var link_library  [list $target_library $mem_lib_sram32x8_SS $synthetic_library "*"]

set_min_library $ss_target_lib -min_version $ff_target_lib
set_min_library $mem_lib_sram32x8_SS -min_version $mem_lib_sram32x8_FF

# ====================================== Reading RTL ===========================================
puts "- Step - Specifying constraints and settings"
set search_path [concat $search_path ./src]
set RTL_PATH ./src

# Add sources files here. Dependencies should be listed first
set src [list $RTL_PATH/register_definitions.sv $RTL_PATH/comparator_2in.sv $RTL_PATH/decoder_blk_slow_rd.sv $RTL_PATH/decoder_blk_slow_wr.sv $RTL_PATH/segment_memory_reg.sv $RTL_PATH/segment_memory_lim.sv $RTL_PATH/segment_memory_input.sv $RTL_PATH/merge_segment.sv $RTL_PATH/merge_segment_input.sv $RTL_PATH/merge_blk_slow.sv]

analyze -format sverilog -lib WORK $src
elaborate $TOP -lib WORK -update
current_design $TOP

link
uniquify

# ===================================== Constraints ===========================================
# Wire load models are used only when Design Compiler is not operating in topographical mode.
#set auto_wire_load_selection true

puts "- Step - Specifying constraints and settings"
#Setting output load and input driver constraints

# Samsung 28nm library capacitance unit is pF (not fF)

set_load -wire_load 0.03 [all_outputs]
set_driving_cell -no_design_rule -library sc9_cmos28lpp_base_lvt_ss_nominal_max_0p855v_125c_sadhm -lib_cell INV_X1B_A9TL [all_inputs]
#Default driver is inverter with unit drive strength (1), with balanced delay for the 2 edges HtoL and LtoH, 9 M2 track height and regular Vth -changed to low Vth cell 

# Operating conditions
set_operating_conditions -max ss_0p855v_125c -max_library sc9_cmos28lpp_base_lvt_ss_nominal_max_0p855v_125c_sadhm -min ff_1p210v_m40c -min_library  sc9_cmos28lpp_base_lvt_ff_nominal_min_1p210v_m40c_sadhm

# Setting max area to 0 makes the area as small as possible
set_max_area 0

# ========================================== Clock =============================================

#### The time unit is defined by the library. ps for 14, 7nm
## mult-factor is 1 for ns time unit and 1000 for ps time unit
set mult_factor 1
set period [expr ($mult_factor * 3.0) ]
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

# ===================================== Timing Constraints ====================================
#set clk_latency [expr ($mult_factor * 0.1) ]
set clk_transition [expr ($mult_factor * 0.075) ]
set clk_setup_skew [expr ($mult_factor * 0.130) ]
set clk_hold_skew [expr ($mult_factor * 0.135) ]

set max_transition [expr ($mult_factor * 0.075) ]
#set max_delay [expr ($mult_factor * $period * 1.5) ]
set max_delay [expr ($mult_factor * 1.005) ]

# Setting up signal and clock inputs' slopes and max transition
set_input_transition $max_transition [all_inputs]
set_clock_transition $clk_transition $clk_name
set_max_transition $max_transition $TOP
set_max_delay -from [all_inputs] -to [all_outputs] $max_delay 

# Setting up setup and hold clock uncertainty 
#set_clock_latency $clk_latency $clk_name
set_clock_uncertainty -setup $clk_setup_skew [all_clocks]
set_clock_uncertainty -hold $clk_hold_skew [all_clocks]

# Setting up external input and output delays
set real_inputs [remove_from_collection [all_inputs] $clk_name]
 
# The delay_value represents the amount of time that the signal is required before a clock edge. For maximum output delay, this usually represents a combinational path delay to a register plus the library setup time of that register. For minimum output delay, this value is usually the shortest path delay to a register minus the library hold time.
set_output_delay -max -clock $clk_name [expr $period/2] [all_outputs]
set_output_delay -min -clock $clk_name [expr $period * 0.025] [all_outputs]
set_input_delay -max -clock $clk_name [expr $period/2] [get_ports $real_inputs]
set_input_delay -min -clock $clk_name [expr $period * 0.025] [get_ports $real_inputs]

# Enable DC to fix hold violations on all clocks 
set_fix_hold [all_clocks]

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

# ===================================== Compilation ========================================
puts "- Step - Compiling"
set_host_options -max_cores 12
# Prior to compiling the datapath blocks, enable power analysis:
set synlib_enable_analyze_dw_power 1

check_design
compile_ultra -no_boundary_optimization
ungroup -flatten -all
change_names -rules verilog -hierarchy

# Got from solvenet - this reportspercentage of datapath
analyze_datapath

# =================================== Synthesis Outputs ====================================
puts "- Step - Writing synthesis outputs"
set_app_var verilogout_show_unconnected_pins true
file mkdir outputs

write -format verilog -hierarchy -output outputs/${TOP}.mapped.v
write -format ddc -hierarchy -output outputs/${TOP}.ddc
write_sdf outputs/${TOP}.sdf
write_sdc -nosplit outputs/${TOP}.sdc
#write_milkyway -overwrite -output "design_rtl_DCT"


# =================================== Writing Reports =====================================
puts "- Step - Writing reports"
file mkdir reports
# Use report_timing -loops to view all timing loops in your design. Use set_disable_timing to manualy break the loops.
#report_timing -loops 

# to check how many sequential cells are not user annotated
# report_saif -type rtl -flat -missing

## Use the report_lib command to list the library units
report_lib sc9_cmos28lpp_base_rvt_tt_nominal_max_0p900v_25c > reports/lib_units.rpt
report_area > reports/area.rpt
report_timing -nets -input_pins -capacitance -transition_time -delay max -nosplit > reports/max.timing
report_timing -nets -input_pins -capacitance -transition_time -delay min -nosplit > reports/min.timing
report_timing > reports/timing.rpt
report_power > reports/power.rpt
report_qor > reports/qor.rpt
# for DW datapath area and blocks
report_area -designware > reports/area_dw.rpt
report_resources -hier > reports/resource.rpt 
# for DW minPower block's power report
analyze_dw_power -hier > reports/power_dw.rpt

check_timing > reports/check_timing.rpt
report_port -verbose > reports/port.rpt
report_constraint -all_violators > reports/constraint.rpt

check_design >> check_design.log

#** For design vision do 
#** design_vision-xg -64bit
#** read_ddc arm_core.mapped.ddc
#** or for GUI
#** read -> locate the .ddc

exit