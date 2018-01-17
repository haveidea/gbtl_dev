//
//---------------------------------------------------------------------------
// store queue connection for single unit   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module stq_buff_unit
  #(//parameter
    NUM_UNITs = `NUM_UNITs, 
    STQ_BUFF_DEPTH = `STQ_BUFF_RATIO_2DATA,
    BITS_STQ_BUFF_PER_UNIT = `BITS_STQ_BUFF_PER_UNIT,
    UNIT_INIT_BIT = `UNIT_INIT_BIT,
    DATA_WIDTH = UNIT_INIT_BIT + `DATA_PRECISION)
   (input clk, rst_b, global_en, rd_en, 
    input [UNIT_INIT_BIT - 1 : 0] svc_threshold_idx, svc_idx,
    input unit_out_valid,
    input [`BITS_ROW_IDX - 1 : 0] unit_out_row_idx,
    input [`DATA_PRECISION - 1 : 0] unit_out_value,
    
    output svc_ready, stq_buff_full,
    output [`DATA_PRECISION - 1 : 0] do_stq_buff);

   // Storage
   //==============================================================================
   wire rd_en_stq_buff, wr_en_stq_buff, stq_buff_empty, deliver;
   wire [DATA_WIDTH  - 1 : 0] di_stq_buff, do_stq_buff_ori;
   wire [UNIT_INIT_BIT - 1 : 0] di_idx, last_stored_idx;

   assign di_idx = unit_out_row_idx[`BITS_ROW_IDX - 1 : `BITS_ROW_IDX - UNIT_INIT_BIT];
   assign di_stq_buff = {di_idx, unit_out_value};
   assign wr_en_stq_buff = global_en && unit_out_valid && !stq_buff_full;
   assign rd_en_stq_buff = svc_ready && deliver ? rd_en : 1'b0;
   			
   sfifo #(.DSIZE(DATA_WIDTH), .ASIZE(BITS_STQ_BUFF_PER_UNIT)) stq_buff
     (//input
      .clk, .rst_b, .rd_en(rd_en_stq_buff), .wr_en(wr_en_stq_buff),
      .data_in(di_stq_buff),
      //output
      .data_out(do_stq_buff_ori),
      .full(stq_buff_full), .empty(stq_buff_empty)); 
   //==============================================================================

   wire [UNIT_INIT_BIT - 1 : 0] do_idx;
   wire [`DATA_PRECISION - 1 : 0] do_value;

   assign deliver = (do_idx == svc_idx);
   assign do_idx = do_stq_buff_ori[DATA_WIDTH - 1 : DATA_WIDTH - UNIT_INIT_BIT];
   assign do_stq_buff = deliver ? do_stq_buff_ori[`DATA_PRECISION - 1 : 0] : '0;

   register #(.WIDTH(UNIT_INIT_BIT)) reg_last_stored_idx(.q(last_stored_idx), .d(di_idx), .clk(clk), .enable(wr_en_stq_buff), .rst_b(rst_b));
   assign svc_ready = (last_stored_idx >= svc_threshold_idx) ? 1'b1 : 1'b0;
      
endmodule // stq_buff_unit
