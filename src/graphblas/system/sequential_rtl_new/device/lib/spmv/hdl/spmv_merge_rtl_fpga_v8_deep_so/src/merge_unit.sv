//
//---------------------------------------------------------------------------
// Merge unit connects the fast and slow blocks (without the adders)   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module merge_unit 
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,
    TI = `TAG_INDEX_DATA_BUFF_SO_SEG,
    VI = `VALID_INDEX_DATA_BUFF_SO_SEG,
    DIV_RATIO_HALF = `DIV_RATIO_HALF,
    SLOW_BLK_BUFF_SIZE = `SLOW_BLK_BUFF_SIZE,
    BITS_SLOW_BLK_BUFF_ADDR = `BITS_SLOW_BLK_BUFF_ADDR,
    NUM_SLOW_BLK = `NUM_SEG_PER_STG) 
   (//input
    input clk, clk_slow, rst_b, unit_en, mode, buff_stq_full,
    input [NUM_SLOW_BLK - 1 : 0]  wr_en_unit_input,
    input [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] wr_addr_unit_input,
    input [NUM_SLOW_BLK - 1 : 0] [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [`DATA_WIDTH_INPUT - 1 : 0] data_in_unit, 
    input [NUM_SLOW_BLK - 1 : 0][`BITS_ROW_IDX - 1 : 0] maxidx_input, 
    input [NUM_SLOW_BLK - 1 : 0] fill_req_accepted_blk_slow,
    input [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_BIN_ADDR - 1 : 0] set_wr_ctr_input, set_rd_ctr_input, 
    input [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_input,

    //output
    output ini_unit_done,
    output [NUM_SLOW_BLK - 1 : 0] send_fill_req_blk_slow,
    output [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] bin_to_fill_addr_blk_slow,
    output [NUM_SLOW_BLK - 1 : 0] [`NUM_INPUTs_PER_SEG_ARR - 1 : 0][`NUM_UNITs - 1 : 0] bin_empty_flags,
    output unit_out_valid,
    output [`BITS_ROW_IDX - 1 : 0] unit_out_row_idx, 
    output [`DATA_PRECISION - 1 : 0] unit_out_value);

   //Slow block signals
   wire [NUM_SLOW_BLK - 1 : 0] out_fifo_wr_ready_slow_adv, out_fifo_wr_ready_slow;
   wire [NUM_SLOW_BLK - 1 : 0] [DATA_WIDTH - 1 : 0] data_out_blk_slow;
   wire [NUM_SLOW_BLK - 1 : 0] blk_en_adv;
   wire [NUM_SLOW_BLK - 1 : 0] ini_blk_slow_done;
   assign ini_unit_done = &ini_blk_slow_done;
         
   //Fast block signals
   wire blk_fast_rd_en_stg0, rd_ready_blk_fast_out_q;
   wire [NUM_SLOW_BLK - 1 : 0] en_intake_fifo_slow_blk;
   wire [`DATA_WIDTH_ADD_STG - 1 : 0] do_blk_fast_out_q;
 
   //FIFO signals
   wire [NUM_SLOW_BLK - 1 : 0] [`DATA_WIDTH_ADD_STG - 1 : 0] data_out_fifo;
   wire [NUM_SLOW_BLK - 1 : 0] fifo_empty_slow_blk_out;
   
   //Add stage signals
   wire [`DATA_WIDTH_ADD_STG - 1 : 0] data_out_merge_unit;
   wire accum_en, accum_out_q_rd_ready;
      
   //Connecting the modules   
   //=========================================================================================
   merge_blk_slow_parallel_arr blk_slow_parr //make it blk_slow_parr
     (//input
      .clk(clk_slow), .rst_b, .mode, .unit_en,
      .out_fifo_wr_ready_slow_adv,
      //.out_fifo_wr_ready_slow_adv(4'b1111), //just for test
      .wr_en_unit_input,
      .wr_addr_unit_input, .data_in_unit, .maxidx_input,
      .fill_req_accepted_blk_slow,
      .set_wr_ctr_input, .set_rd_ctr_input, .set_track_ctr_input,	
     
      //output
      .blk_en_adv,
      .ini_blk_slow_done,
      .send_fill_req_blk_slow, .bin_to_fill_addr_blk_slow, 
      .bin_empty_flags,	    
      .data_out_blk_slow);
   
   afifo_top_slow_fast blk_afifo_slow_fast  
     (//input
      .clk, .clk_slow, .rst_b, .unit_en, .mode,
      .next_stg_rd_en(blk_fast_rd_en_stg0), .blk_en_adv_slow(blk_en_adv),
      .data_out_blk_slow,  
      .en_intake_fifo_slow_blk, 
      
      //output	
      .fifo_empty(fifo_empty_slow_blk_out),
      .out_fifo_wr_ready_slow, .out_fifo_wr_ready_slow_adv,
      .data_out_fifo);
   
   merge_blk_fast_fifo_based blk_fast 
     (//input
      .clk, .rst_b, .mode, .unit_en, 
      .next_blk_rd_en(accum_en),
      //.next_blk_rd_en(rd_ready_blk_fast_out_q), //debug only
      .data_in_blk_fast(data_out_fifo),
      .prev_blk_fifo_empty(fifo_empty_slow_blk_out),
     
      //output
      .blk_fast_rd_en_stg0, .rd_ready_blk_fast_out_q,
      .en_intake_fifo_slow_blk,					  
      .do_blk_fast_out_q);

   wire rd_en_accum_blk;
   
   accum_blk accum_blk 
     (//input
      .clk, .rst_b, .unit_en, .mode, .data_ended(1'b0), 
      .prev_blk_rd_ready(rd_ready_blk_fast_out_q), 
      //.next_blk_rd_en(accum_out_q_rd_ready),//debug only
      .next_blk_rd_en(!buff_stq_full),
      .di(do_blk_fast_out_q),
      
      //output
      .en_blk(accum_en), .out_q_rd_ready(accum_out_q_rd_ready), 
      .do_accum_blk_out_q(data_out_merge_unit));   

   assign rd_en_accum_blk = accum_out_q_rd_ready && !buff_stq_full && data_out_merge_unit[0];
      
   //=========================================================================================
   
   wire blk_fast_out_valid;
   wire [`BITS_ROW_IDX - 1 : 0] blk_fast_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] blk_fast_out_value;      
   assign blk_fast_out_valid = do_blk_fast_out_q[0];
   assign blk_fast_out_row_idx = do_blk_fast_out_q[`DATA_WIDTH_ADD_STG - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX];
   assign blk_fast_out_value = do_blk_fast_out_q[`DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - `DATA_PRECISION];

    
   assign unit_out_valid = rd_en_accum_blk;//original
   //assign unit_out_valid = data_out_merge_unit[0];///temp
   assign unit_out_row_idx = data_out_merge_unit[`DATA_WIDTH_ADD_STG - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX];
   assign unit_out_value = data_out_merge_unit[`DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - `DATA_PRECISION];

endmodule // merge_unit
