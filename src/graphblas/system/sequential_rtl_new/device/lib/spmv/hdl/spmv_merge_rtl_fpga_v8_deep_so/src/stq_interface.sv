//
//---------------------------------------------------------------------------
// store queue connection for single unit   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module stq_interface
  #(//parameter
    DONE_IDX = 512,
    NUM_UNITs = `NUM_UNITs,
    UNIT_INIT_BIT = `UNIT_INIT_BIT,
    STQ_DATA_WIDTH = `STQ_DATA_WIDTH,
    SVC_TH_FIRST = `STQ_BUFF_MIN_RATIO_2DATA - 1)
   (//LDQ signals
    input clk, rst_b, unit_en, mode, stq_ready, 
    input [NUM_UNITs - 1 : 0] unit_out_valid,
    input [NUM_UNITs - 1 : 0] [`BITS_ROW_IDX - 1 : 0] unit_out_row_idx,
    input [NUM_UNITs - 1 : 0] [`DATA_PRECISION - 1 : 0] unit_out_value,
    
    output [NUM_UNITs - 1 : 0] stq_buff_full,
    output stq_valid, done,
    output [STQ_DATA_WIDTH - 1 : 0] stq_data);

   wire global_en;
   assign global_en = (mode == `MODE_WORK) && unit_en;
   
   //Connecting stq buffs
   //==============================================================================
   wire [NUM_UNITs - 1 : 0][`DATA_PRECISION - 1 : 0] do_stq_buff;
   wire [NUM_UNITs - 1 : 0] svc_ready;
   wire rd_en;
   wire [UNIT_INIT_BIT - 1 : 0] svc_threshold_idx, svc_idx, svc_threshold_idx_adv, svc_idx_adv;
   
   assign rd_en = stq_valid && stq_ready;
   assign stq_valid = global_en && (&svc_ready);
   
   genvar j0;
   generate
      for (j0 = 0; j0 < NUM_UNITs; j0 = j0 + 1) begin : stq_unit
	 
	 stq_buff_unit stq_buff_unit
	   (//input 
	    .clk, .rst_b, .global_en, .rd_en, 
	    .svc_threshold_idx, .svc_idx,
	    .unit_out_valid(unit_out_valid[j0]),
            .unit_out_row_idx(unit_out_row_idx[j0]),
	    .unit_out_value(unit_out_value[j0]),
	    //output
	    .svc_ready(svc_ready[j0]), .stq_buff_full(stq_buff_full[j0]),
	    .do_stq_buff(do_stq_buff[j0]));

	 assign stq_data[STQ_DATA_WIDTH - 1 - `DATA_PRECISION*j0 : STQ_DATA_WIDTH - `DATA_PRECISION*(j0+1)] = do_stq_buff[j0];
      end
   endgenerate
   //==============================================================================

   //Store queue data deliver controls 
   //==============================================================================
   wire inc_svc_th, inc_svc_idx;
   assign svc_threshold_idx_adv = svc_threshold_idx + `STQ_BUFF_MIN_RATIO_2DATA;
   assign svc_idx_adv = svc_idx + 1'b1;

   assign inc_svc_idx = rd_en;
   assign inc_svc_th = inc_svc_idx && (svc_idx == svc_threshold_idx);
   
   register #(.WIDTH(UNIT_INIT_BIT), .RESET_VALUE(SVC_TH_FIRST)) reg_svc_threshold_idx(.q(svc_threshold_idx), .d(svc_threshold_idx_adv), .clk(clk), .enable(inc_svc_th), .rst_b(rst_b));
   register #(.WIDTH(UNIT_INIT_BIT)) reg_svc_idx(.q(svc_idx), .d(svc_idx_adv), .clk(clk), .enable(inc_svc_idx), .rst_b(rst_b));
   //==============================================================================

   wire en_done;
   assign en_done = inc_svc_idx && (svc_idx == DONE_IDX);
   register #(.WIDTH(1)) reg_done(.q(done), .d(1'b1), .clk(clk), .enable(en_done), .rst_b(rst_b));
   
endmodule // stq_interface

