//
//---------------------------------------------------------------------------
// Accumulator block. Includes all accumulator stages.   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module accum_blk 
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_ADD_STG,
    BITS_ROW_IDX = `BITS_ROW_IDX,
    BITS_ADDER_OUT_Q = `BITS_ADDER_OUT_Q,
    NUM_ACCUM_STG = `NUM_ACCUM_STG) 
   (//input
    input clk, rst_b, unit_en, mode, data_ended,
    input [DATA_WIDTH - 1 : 0] di,
    
    //handshaking signals
    input prev_blk_rd_ready, next_blk_rd_en,
    output en_blk, out_q_rd_ready, 
    
    //output
    output [DATA_WIDTH - 1 : 0] do_accum_blk_out_q);

   ////assign en_blk = en_stg;
   wire en_global;
   assign en_global = (mode == `MODE_WORK && unit_en);

   
   //Accumulator stages including special last edge
   //=========================================================================================
   wire [NUM_ACCUM_STG : 0] [DATA_WIDTH - 1 : 0] di_stg;
   wire [NUM_ACCUM_STG : 0] prev_stg_rd_ready; 
   wire [NUM_ACCUM_STG : 0] en_stg;
   
   wire [DATA_WIDTH - 1 : 0] do_accum_stg_out_q_last;
   wire out_q_rd_ready_last; 
   wire en_stg_last;

   assign prev_stg_rd_ready[0] = prev_blk_rd_ready;
   assign en_stg[NUM_ACCUM_STG] = en_stg_last; 
   assign en_blk = en_stg[0];
   assign out_q_rd_ready = out_q_rd_ready_last;

   assign di_stg[0] = di; 
   assign do_accum_blk_out_q = do_accum_stg_out_q_last; //original
   //assign do_accum_blk_out_q = di_stg[1];///temp
   
genvar j0;
generate  
for (j0 = 0; j0 < NUM_ACCUM_STG; j0 = j0 + 1) begin    
   accum_stg #(.DATA_WIDTH(DATA_WIDTH), .BITS_ROW_IDX(BITS_ROW_IDX), .BITS_ADDER_OUT_Q(BITS_ADDER_OUT_Q)) accum_stg
     (//input
      .clk, .rst_b, .en_global, .data_ended, .di(di_stg[j0]),
      //handshaking signals
      .prev_stg_rd_ready(prev_stg_rd_ready[j0]),
      //.next_stg_rd_en(prev_stg_rd_ready[j0+1]),//for debug
      .next_stg_rd_en(en_stg[j0+1]),
      .en_stg(en_stg[j0]), .out_q_rd_ready(prev_stg_rd_ready[j0+1]),
      //output
      .do_accum_stg_out_q(di_stg[j0+1]));
end 
endgenerate

   //assign en_stg_last = prev_stg_rd_ready[NUM_ACCUM_STG];//temp. for debug

   //temp. just for debug
   integer i0;
   assign i0 = 1;
   wire    blk_fast_out_valid;
   wire [`BITS_ROW_IDX - 1 : 0] blk_fast_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] blk_fast_out_value;      
   assign blk_fast_out_valid = di_stg[1][0];
   assign blk_fast_out_row_idx = di_stg[1][`DATA_WIDTH_ADD_STG - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX];
   assign blk_fast_out_value = di_stg[1][`DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - `DATA_PRECISION];
   

   //Last Accumulator Stage
   accum_stg_last #(.DATA_WIDTH(DATA_WIDTH), .BITS_ROW_IDX(BITS_ROW_IDX), .BITS_ADDER_OUT_Q(BITS_ADDER_OUT_Q)) accum_stg_last
     (//input
      .clk, .rst_b, .en_global, .data_ended, .di(di_stg[NUM_ACCUM_STG]),
      //handshaking signals
      .prev_stg_rd_ready(prev_stg_rd_ready[NUM_ACCUM_STG]), .next_stg_rd_en(next_blk_rd_en),
      .en_stg(en_stg_last), .out_q_rd_ready(out_q_rd_ready_last),
      //output
      .do_accum_stg_out_q(do_accum_stg_out_q_last));
 
   //=========================================================================================

   /*
   //Accumulator stages without last stage
   //=========================================================================================
   wire [NUM_ACCUM_STG : 0] [DATA_WIDTH - 1 : 0] di_stg;
   wire [NUM_ACCUM_STG : 0] prev_stg_rd_ready; 
   wire [NUM_ACCUM_STG : 0] en_stg;
   
   //handshaking signals
   assign prev_stg_rd_ready[0] = prev_blk_rd_ready;
   assign en_stg[NUM_ACCUM_STG] = next_blk_rd_en;
   assign en_blk = en_stg[0];
   assign out_q_rd_ready = prev_stg_rd_ready[NUM_ACCUM_STG];

   assign di_stg[0] = di;
   assign do_accum_blk_out_q = di_stg[NUM_ACCUM_STG];
  
genvar j0;
generate  
for (j0 = 0; j0 < NUM_ACCUM_STG; j0 = j0 + 1) begin    
   accum_stg #(.DATA_WIDTH(DATA_WIDTH), .BITS_ROW_IDX(BITS_ROW_IDX), .BITS_ADDER_OUT_Q(BITS_ADDER_OUT_Q)) accum_stg
     (//input
      .clk, .rst_b, .en_global, .data_ended, .di(di_stg[j0]),
      //handshaking signals
      .prev_stg_rd_ready(prev_stg_rd_ready[j0]), .next_stg_rd_en(en_stg[j0+1]),
      .en_stg(en_stg[j0]), .out_q_rd_ready(prev_stg_rd_ready[j0+1]),
      //output
      .do_accum_stg_out_q(di_stg[j0+1]));
end 
endgenerate
   //=========================================================================================
   */
      
endmodule // accum_blk
