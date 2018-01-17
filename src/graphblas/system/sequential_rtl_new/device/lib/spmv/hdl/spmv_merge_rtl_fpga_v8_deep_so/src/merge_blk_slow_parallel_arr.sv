//
//---------------------------------------------------------------------------
// All the parallel slow merge blocks   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module merge_blk_slow_parallel_arr
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,
    NUM_SLOW_BLK = `NUM_SEG_PER_STG) 
   (//input
    input clk, rst_b, mode, unit_en,
    input [NUM_SLOW_BLK - 1 : 0] out_fifo_wr_ready_slow_adv,
    ////input [`NUM_STGs - 1 : 0] wr_addr_unit_input,
    input [NUM_SLOW_BLK - 1 : 0]  wr_en_unit_input,
    input [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] wr_addr_unit_input,
    input [NUM_SLOW_BLK - 1 : 0] [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [`DATA_WIDTH_INPUT - 1 : 0] data_in_unit, 
    input [NUM_SLOW_BLK - 1 : 0][`BITS_ROW_IDX - 1 : 0] maxidx_input, 
    input [NUM_SLOW_BLK - 1 : 0] fill_req_accepted_blk_slow,
    input [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_BIN_ADDR - 1 : 0] set_wr_ctr_input, set_rd_ctr_input,
    input [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_input,

    //output
    output [NUM_SLOW_BLK - 1 : 0] blk_en_adv,    
    output [NUM_SLOW_BLK - 1 : 0] ini_blk_slow_done,
    output [NUM_SLOW_BLK - 1 : 0] send_fill_req_blk_slow,
    output [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] bin_to_fill_addr_blk_slow,
    output [NUM_SLOW_BLK - 1 : 0] [`NUM_INPUTs_PER_SEG_ARR - 1 : 0][`NUM_UNITs - 1 : 0] bin_empty_flags,
    output [NUM_SLOW_BLK - 1 : 0] [DATA_WIDTH - 1 : 0] data_out_blk_slow);

   genvar j1;
   generate
      for (j1 = 0; j1 < NUM_SLOW_BLK; j1 = j1 + 1) begin : slow_blocks_parr
	 merge_blk_slow blk_slow
	   (//input
	    .clk, .rst_b, .unit_en, .mode, .wr_en_input(wr_en_unit_input[j1]), 
	    .out_fifo_wr_ready_slow_adv(out_fifo_wr_ready_slow_adv[j1]),
	    .wr_addr_input(wr_addr_unit_input[j1]),
            .data_in_blk_slow(data_in_unit[j1]), .maxidx_input(maxidx_input[j1]), 
	    .fill_req_accepted(fill_req_accepted_blk_slow[j1]),
	    .set_wr_ctr_input(set_wr_ctr_input[j1]), .set_rd_ctr_input(set_rd_ctr_input[j1]), .set_track_ctr_input(set_track_ctr_input[j1]),
	    //output
	    .blk_en_adv(blk_en_adv[j1]), 
	    .ini_blk_slow_done(ini_blk_slow_done[j1]),
            .send_fill_req(send_fill_req_blk_slow[j1]),
            .bin_to_fill_addr_blk_slow(bin_to_fill_addr_blk_slow[j1]),
            .bin_empty_flags(bin_empty_flags[j1]),	    
	    .blk_out_data_tot(data_out_blk_slow[j1]));
      end
   endgenerate

endmodule // merge_blk_slow_parallel
