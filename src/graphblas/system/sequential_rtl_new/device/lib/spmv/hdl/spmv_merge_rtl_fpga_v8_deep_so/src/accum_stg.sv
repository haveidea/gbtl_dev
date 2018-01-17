//
//---------------------------------------------------------------------------
// Accumulator stage   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module accum_stg 
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_ADD_STG,
    BITS_ROW_IDX = `BITS_ROW_IDX,
    BITS_ADDER_OUT_Q = `BITS_ADDER_OUT_Q) 
   (//input
    input clk, rst_b, en_global, data_ended, 
    input [DATA_WIDTH - 1 : 0] di,
			
    //handshaking signals
    input prev_stg_rd_ready, next_stg_rd_en,
    output en_stg, out_q_rd_ready,
  
    //output 
    output [DATA_WIDTH - 1 : 0] do_accum_stg_out_q);

   wire out_q_wr_ready;
   assign en_stg = en_global && prev_stg_rd_ready && out_q_wr_ready;
   
   //-------------------------Adder input and activation-----------------------
   wire str0_issue, str1_issue, add_issue, bypass_issue;
   wire valid_di, valid_storage0, valid_storage1;   
   wire [BITS_ROW_IDX - 1 : 0] row_idx_storage0, row_idx_storage1;
   wire [`DATA_PRECISION - 1 : 0] value_storage0, value_storage1, adder_in0, adder_in1;
   logic [DATA_WIDTH - 1 : 0] 	  storage0, storage1, storage0_input, storage1_input;
   
   assign valid_di = di[0];          
   assign valid_storage0 = storage0[0];
   assign valid_storage1 = storage1[0];
   assign row_idx_storage0 = storage0[DATA_WIDTH - 1 : DATA_WIDTH - BITS_ROW_IDX];
   assign row_idx_storage1 = storage1[DATA_WIDTH - 1 : DATA_WIDTH - BITS_ROW_IDX];
   assign value_storage0 = storage0[DATA_WIDTH - BITS_ROW_IDX - 1 : DATA_WIDTH - BITS_ROW_IDX - `DATA_PRECISION];
   assign value_storage1 = storage1[DATA_WIDTH - BITS_ROW_IDX - 1 : DATA_WIDTH - BITS_ROW_IDX - `DATA_PRECISION];
   
   assign add_issue = en_stg && valid_storage0 && valid_storage1 && (row_idx_storage0 == row_idx_storage1);
   assign bypass_issue = en_stg && valid_storage1 && valid_storage0 && (row_idx_storage0 != row_idx_storage1);

   assign str0_issue = (en_stg && valid_di) || add_issue;
   assign storage0_input = (en_stg && valid_di) ? di : (add_issue ? '0 : storage0);

   assign str1_issue = add_issue || (str0_issue && valid_storage0) || bypass_issue;
   assign storage1_input = add_issue? '0 : (str0_issue && valid_storage0)? storage0 : bypass_issue? '0 : storage1;
   
   register #(.WIDTH(DATA_WIDTH)) reg_storage0(.q(storage0), .d(storage0_input), .clk(clk), .enable(str0_issue), .rst_b(rst_b));
   register #(.WIDTH(DATA_WIDTH)) reg_storage1(.q(storage1), .d(storage1_input), .clk(clk), .enable(str1_issue), .rst_b(rst_b));
      
   assign adder_in0 = add_issue ? value_storage0 : '0;
   assign adder_in1 = (add_issue || bypass_issue) ? value_storage1 : '0;
      
   //Note: if invalid data comes when en_stg=1, the adder will pass the data in storage1. This is probably not ideal. For only one adder stage this might not be a big problem. But for multiple adder stages, we should not pass the data in storage1 just because new invalid data came in. We can control it by putiing more logic with add_en in the upper level of hierarchy.
   //----------------------------------------------------------------------------

/*   
   //Round Robin adder signals
   //---------------------------------------------------------------------------- 
   wire data_valid;   
   wire [BITS_ROW_IDX - 1 : 0] data_row_idx;
   wire [`DATA_PRECISION - 1 : 0] data_value;
   
   assign data_valid = valid_storage1;
   assign data_row_idx = row_idx_storage1;
   //assign data_value = value_storage1;

   wire add_out_valid;   
   wire [BITS_ROW_IDX - 1 : 0] add_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] add_out_value;
   wire [`STATUS_WIDTH - 1 : 0] add_status;

   assign data_out_add_stg = {add_out_row_idx, add_out_value, add_out_valid};

   wire [`NUM_RR_ADDER - 1 :0] add_out_valid_arr;   
   wire [`NUM_RR_ADDER - 1 :0] [BITS_ROW_IDX - 1 : 0] add_out_row_idx_arr;
   wire [`NUM_RR_ADDER - 1 :0] [`DATA_PRECISION - 1 : 0] add_out_value_arr;
   wire [`NUM_RR_ADDER - 1 :0] [`STATUS_WIDTH - 1 : 0] add_status_arr;

   logic [`BITS_RR_ADD_SELECT_CTR - 1 :0] adder_select_ctr;
   logic [`NUM_RR_ADDER - 1 : 0] adder_select;

   wire	add_en_enhanced;
   assign add_en_enhanced = add_en && (add_issue || bypass_issue);
     
   assign adder_select = add_en_enhanced ? 1 << adder_select_ctr : 0;  
   
   integer i0;
   always_ff @ (posedge clk) begin
      if(~rst_b || (adder_select_ctr == `NUM_RR_ADDER - 1 && add_en_enhanced)) begin
	 adder_select_ctr <= '0;
      end
      else if (add_en_enhanced && adder_select_ctr < `NUM_RR_ADDER - 1) begin
         adder_select_ctr <= adder_select_ctr + 1;
      end
   end 

   assign add_out_valid = add_out_valid_arr[adder_select_ctr] & add_en_enhanced;
   assign add_out_row_idx = add_out_row_idx_arr[adder_select_ctr];
   assign add_out_value = add_out_value_arr[adder_select_ctr];
   assign add_status = add_status_arr[adder_select_ctr];

   genvar j0;
   generate
      for (j0 = 0; j0 < `NUM_RR_ADDER; j0 = j0 + 1) begin : add_rr
					    
	 adder_single adder
	   (//input
	    .clk, .rst_b, .adder_select(adder_select[j0]), 
	    .data_in0(adder_in0), .data_in1(adder_in1), 
	    .data_valid, .data_row_idx,
	    //output
	    .data_valid_reg(add_out_valid_arr[j0]), .data_row_idx_reg(add_out_row_idx_arr[j0]),
	    .z_inst(add_out_value_arr[j0]), .status(add_status_arr[j0]));
      end
   endgenerate
   //----------------------------------------------------------------------------  
*/
   // Adder stage
   //================================================================================   
   wire data_valid;   
   wire [BITS_ROW_IDX - 1 : 0] data_row_idx;
   assign data_valid = (add_issue || bypass_issue) ? valid_storage1 : 0;
   assign data_row_idx = (add_issue || bypass_issue) ? row_idx_storage1 : '0;
   
   wire add_en_enhanced;
   assign add_en_enhanced = add_issue || bypass_issue;

   wire add_out_valid;   
   wire [BITS_ROW_IDX - 1 : 0] add_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] add_out_value;
   wire [DATA_WIDTH - 1 : 0] do_accum_stg;
       
   //adder_comb_w_ctrl add_comb
   adder_pipe_w_ctrl add_pipe  
     (//input
      .clk, .rst_b,
      .adder_select(1'b1), .ena(en_stg), //we want to activate addition at every cycle output is sampled 
      .data_in0(adder_in0), .data_in1(adder_in1), 
      .data_valid, .data_row_idx,
      //output
      .data_valid_reg(add_out_valid), .data_row_idx_reg(add_out_row_idx),
      .add_result(add_out_value));
   
   assign do_accum_stg = {add_out_row_idx, add_out_value, add_out_valid};
   //================================================================================

   // Output Fifo for Adder Stage
   //=========================================================================================
   wire fifo_full, fifo_empty, rd_en_q, wr_en_q;
   //wire [DATA_WIDTH - 1 : 0] do_accum_stg_out_q_temp;
   assign out_q_wr_ready = !fifo_full;
   assign out_q_rd_ready = !fifo_empty;
   assign rd_en_q = next_stg_rd_en; //original
   //assign rd_en_q = !fifo_empty; //temp
   assign wr_en_q = add_out_valid && en_stg;
      
   sfifo #(.DSIZE(DATA_WIDTH), .ASIZE(BITS_ADDER_OUT_Q)) fifo_fast_out
     (//input
      .clk, .rst_b, .rd_en(rd_en_q), .wr_en(wr_en_q),
      .data_in(do_accum_stg),
      //output
      .data_out(do_accum_stg_out_q),
      .full(fifo_full), .empty(fifo_empty));      
   //=========================================================================================

   //debug only
   wire q_out_valid;   
   wire [BITS_ROW_IDX - 1 : 0] q_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] q_out_value;
   assign q_out_valid = do_accum_stg_out_q[0] && !fifo_empty;
   assign q_out_row_idx = do_accum_stg_out_q[`DATA_WIDTH_ADD_STG - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX];
   assign q_out_value = do_accum_stg_out_q[`DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - `DATA_PRECISION];

   
   
endmodule // accum_stg
