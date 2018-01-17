# SimVision Command Script (Fri Jul 21 01:33:08 AM EDT 2017)
#
# Version 15.20.s006
#
# You can restore this configuration with:
#
#     simvision -input crashrecovery.tcl
#  or simvision -input crashrecovery.tcl database1 database2 ...
#


#
# Preferences
#
preferences set plugin-enable-svdatabrowser-new 1
preferences set toolbar-TimeSearch-WaveWindow {
  usual
  position -anchor e
}
preferences set toolbar-txe_waveform_toggle-WaveWindow {
  usual
  position -pos 1
}
preferences set toolbar-Standard-WaveWindow {
  usual
  position -pos 2
}
preferences set plugin-enable-groupscope 0
preferences set plugin-enable-interleaveandcompare 0
preferences set plugin-enable-waveformfrequencyplot 0
preferences set toolbar-WaveZoom-WaveWindow {
  usual
  position -pos 1
}
preferences set whats-new-dont-show-at-startup 1

#
# PPE data
#
array set dbNames ""
set dbNames(realName1) [database require waveforms -search {
}]

#
# Databases
#
database require waveforms -search {
	./run_dir/sim/waveforms.shm/waveforms.trn
	/afs/ece.cmu.edu/usr/fsadi/spmv_merge_rtl_fpga_v4/run_dir/sim/waveforms.shm/waveforms.trn
}

#
# Mnemonic Maps
#
mmap new -reuse -name {Boolean as Logic} -radix %b -contents {{%c=FALSE -edgepriority 1 -shape low}
{%c=TRUE -edgepriority 1 -shape high}}
mmap new -reuse -name {Example Map} -radix %x -contents {{%b=11???? -bgcolor orange -label REG:%x -linecolor yellow -shape bus}
{%x=1F -bgcolor red -label ERROR -linecolor white -shape EVENT}
{%x=2C -bgcolor red -label ERROR -linecolor white -shape EVENT}
{%x=* -label %x -linecolor gray -shape bus}}

#
# Waveform windows
#
if {[catch {window new WaveWindow -name "Waveform 1" -geometry 1920x1018+1680+22}] != ""} {
    window geometry "Waveform 1" 1920x1018+1680+22
}
window target "Waveform 1" on
waveform using {Waveform 1}
waveform sidebar select designbrowser
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 175 \
    -units ns \
    -valuewidth 75
waveform baseline set -time 0


waveform xview limits 0 2000ns

if {[catch {window new WaveWindow -name "accum_stg0_add_pipe" -geometry 1920x1018+1680+22}] != ""} {
    window geometry "accum_stg0_add_pipe" 1920x1018+1680+22
}
waveform using accum_stg0_add_pipe
waveform sidebar visibility partial
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 175 \
    -units ns \
    -valuewidth 75
waveform baseline set -time 0


waveform xview limits 0 2000ns

if {[catch {window new WaveWindow -name "accum_stg0" -geometry 1920x1018+1680+22}] != ""} {
    window geometry "accum_stg0" 1920x1018+1680+22
}
waveform using accum_stg0
waveform sidebar visibility partial
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 246 \
    -units ns \
    -valuewidth 102
waveform baseline set -time 0

set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.add_en_enhanced}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.add_issue}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.add_out_row_idx[31:0]}
	} ]
waveform format $id -radix %d
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.add_out_valid}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.wr_en_q}
	} ]
waveform format $id -color #0099ff -namecolor #0099ff
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.add_out_value[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.adder_in0[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.adder_in1[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.bypass_issue}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.clk}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.data_ended}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.data_row_idx[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.data_valid}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.di[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.do_accum_stg[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.do_accum_stg_out_q[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.en_global}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.en_stg}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.fifo_empty}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.fifo_full}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.next_stg_rd_en}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.out_q_rd_ready}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.out_q_wr_ready}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.prev_stg_rd_ready}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.q_out_row_idx[31:0]}
	} ]
waveform format $id -radix %d
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.q_out_valid}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.rd_en_q}
	} ]
waveform format $id -color #0099ff
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.q_out_value[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.row_idx_storage0[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.row_idx_storage1[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.rst_b}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.storage0[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.storage0_input[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.storage1[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.storage1_input[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.str0_issue}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.str1_issue}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.valid_di}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.valid_storage0}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.valid_storage1}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.value_storage0[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.genblk1[0].accum_stg.value_storage1[31:0]}
	} ]

waveform xview limits 3523.29ns 3554.57ns

if {[catch {window new WaveWindow -name "accum_stg1" -geometry 1920x1018+1680+22}] != ""} {
    window geometry "accum_stg1" 1920x1018+1680+22
}
waveform using accum_stg1
waveform sidebar visibility partial
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 199 \
    -units ns \
    -valuewidth 134
waveform baseline set -time 0


waveform xview limits 0 2000ns

if {[catch {window new WaveWindow -name "accum_stg2" -geometry 1680x1028+0+52}] != ""} {
    window geometry "accum_stg2" 1680x1028+0+52
}
waveform using accum_stg2
waveform sidebar visibility partial
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 175 \
    -units ns \
    -valuewidth 75
waveform baseline set -time 0


waveform xview limits 0 2000ns

if {[catch {window new WaveWindow -name "accum_stg_last" -geometry 1920x1018+1680+22}] != ""} {
    window geometry "accum_stg_last" 1920x1018+1680+22
}
waveform using accum_stg_last
waveform sidebar select tracesignals
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 248 \
    -units ns \
    -valuewidth 75
waveform baseline set -time 0

set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.add_out_row_idx[31:0]}
	} ]
waveform format $id -radix %d
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.add_out_valid
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.input_add_out_row_idx_last[31:0]}
	} ]
waveform format $id -radix %d
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.input_add_out_valid_last
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.add_issue
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.add_out_row_idx_last[31:0]}
	} ]
waveform format $id -radix %d
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.add_out_valid_last
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.wr_en_q
	} ]
waveform format $id -color #0099ff
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.add_out_value_last[31:0]}
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.release_last
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.add_out_value[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.adder_in0_value[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.adder_in1_value[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.adder_in_row_idx[31:0]}
	} ]
waveform format $id -radix %d
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.adder_in_valid
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.bypass_issue
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.clk
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.conflict_add_issue
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.data_ended
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.data_row_idx[31:0]}
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.data_valid
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.di[64:0]}
	} ]
waveform hierarchy collapse $id
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.do_accum_stg[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.do_accum_stg_last[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.do_accum_stg_out_q[64:0]}
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.en_global
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.en_stg
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.en_adder
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.fifo_empty
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.fifo_full
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.halt_conflict
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.input_add_out_value_last[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.issued_row_idx_last[31:0]}
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.issued_valid_last
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.next_stg_rd_en
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.out_q_rd_ready
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.out_q_wr_ready
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.prev_stg_rd_ready
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.rd_en_q
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.release_last
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.rst_b
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.sth_issued
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.storage0[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.storage0_input[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.storage1[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.storage1_input[64:0]}
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.str0_issue
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.str1_issue
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.str_add_out
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.valid_di
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.row_idx_storage1[31:0]}
	} ]
waveform format $id -radix %d
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.row_idx_storage0[31:0]}
	} ]
waveform format $id -radix %d
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.valid_storage0
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.valid_storage1
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.value_storage0[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.accum_blk.accum_stg_last.value_storage1[31:0]}
	} ]

waveform xview limits 3506.44ns 3569ns

if {[catch {window new WaveWindow -name "blk_fast" -geometry 1920x1018+1680+22}] != ""} {
    window geometry "blk_fast" 1920x1018+1680+22
}
waveform using blk_fast
waveform sidebar visibility partial
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 228 \
    -units ns \
    -valuewidth 100
waveform baseline set -time 0

set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_fast.atom_data_out[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_fast.atom_en[2:0]}
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.blk_fast.blk_en
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.blk_fast.blk_en_reg
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_fast.blk_fast_out_row_idx[31:0]}
	} ]
waveform format $id -radix %d
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.blk_fast.blk_fast_out_valid
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_fast.blk_fast_out_value[31:0]}
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.blk_fast.clk
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_fast.data_in_blk_fast[3:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_fast.data_out_blk_fast[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_fast.do_blk_fast_out_q[64:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_fast.en_intake[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_fast.en_intake_fifo_slow_blk[3:0]}
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.blk_fast.fifo_empty
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.blk_fast.fifo_full
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.blk_fast.mode
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.blk_fast.next_blk_rd_en
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.blk_fast.rd_ready_blk_fast_out_q
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.blk_fast.rst_b
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.blk_fast.unit_en
	} ]
set id [waveform add -signals  {
	waveforms::tb_merge_core.core.unit.blk_fast.wr_ready_blk_fast_out_q
	} ]

waveform xview limits 3522.09ns 3553.35ns

if {[catch {window new WaveWindow -name "blk_slow2" -geometry 1920x1018+0+0}] != ""} {
    window geometry "blk_slow2" 1920x1018+0+0
}
waveform using blk_slow2
waveform sidebar visibility partial
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 252 \
    -units ns \
    -valuewidth 75
waveform baseline set -time 0

set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.addr_seg_initialize_wr[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.addr_seg_rd[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.addr_seg_wr[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.addr_seg_wr_temp[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.adv_addr_seg_rd[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.bin_to_fill_addr_blk_slow[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.blk_en}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.blk_en_adv}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.blk_en_next}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.blk_out_data_tot[65:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.blk_out_row_idx[31:0]}
	} ]
waveform format $id -radix %d
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.blk_out_valid}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.blk_out_value[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.clk}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.data_in_blk_slow[7:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.data_in_row_idx[7:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.data_in_value[7:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.data_out_seg[7:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.fill_req_accepted}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.i0}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.inc_val_wr_ctr_input[2:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.ini_blk_slow_done}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.mode}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.mode_reg}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.out_fifo_wr_ready_slow_adv}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.rd_en_buff_so}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.rd_en_buff_so_adv}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.rst_b}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.send_fill_req}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.unit_en}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.wl_seg_rd[254:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.wl_seg_wr[254:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.wr_addr_input[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.wr_decode_en}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.wr_en_buff_so}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.wr_en_buff_so_adv}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.wr_en_input}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.wr_pause}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[2].blk_slow.wr_pending}
	} ]

waveform xview limits 10860.5ns 10985.5ns

if {[catch {window new WaveWindow -name "blk_slow1" -geometry 1920x1018+1680+22}] != ""} {
    window geometry "blk_slow1" 1920x1018+1680+22
}
waveform using blk_slow1
waveform sidebar visibility partial
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 216 \
    -units ns \
    -valuewidth 75
waveform baseline set -time 0

set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.addr_seg_initialize_wr[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.addr_seg_rd[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.addr_seg_wr[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.addr_seg_wr_temp[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.adv_addr_seg_rd[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.bin_to_fill_addr_blk_slow[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.blk_en}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.blk_en_adv}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.blk_en_next}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.blk_out_data_tot[65:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.blk_out_row_idx[31:0]}
	} ]
waveform format $id -radix %d
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.blk_out_valid}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.blk_out_value[31:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.clk}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.data_in_blk_slow[7:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.data_in_row_idx[7:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.data_in_value[7:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.data_out_seg[7:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.fill_req_accepted}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.i0}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.inc_val_wr_ctr_input[2:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.ini_blk_slow_done}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.mode}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.mode_reg}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.out_fifo_wr_ready_slow_adv}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.rd_en_buff_so}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.rd_en_buff_so_adv}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.rst_b}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.send_fill_req}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.unit_en}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.wl_seg_rd[254:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.wl_seg_wr[254:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.wr_addr_input[6:0]}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.wr_decode_en}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.wr_en_buff_so}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.wr_en_buff_so_adv}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.wr_en_input}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.wr_pause}
	} ]
set id [waveform add -signals  {
	{waveforms::tb_merge_core.core.unit.blk_slow_parr.slow_blocks_parr[1].blk_slow.wr_pending}
	} ]

waveform xview limits 10860.5ns 10985.5ns

#
# Waveform Window Links
#

#
# Console windows
#
console set -windowname Console
window geometry Console 600x250+0+0

#
# Layout selection
#

