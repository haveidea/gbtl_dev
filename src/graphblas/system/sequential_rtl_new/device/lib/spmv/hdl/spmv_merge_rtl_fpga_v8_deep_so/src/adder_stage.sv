//
//---------------------------------------------------------------------------
// Adder stage for mult unit. Can add up to two conflicts   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module adder_stage 
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_ADD_STG,
    BITS_ROW_IDX = `BITS_ROW_IDX) 
   (
    input clk, rst_b, add_en, data_ended,
    input [DATA_WIDTH - 1 : 0] data_in,
					  
    output [DATA_WIDTH - 1 : 0] data_out_add_stg);

   //-------------------------Adder input and activation-----------------------
   logic [DATA_WIDTH - 1 : 0] storage0, storage1, storage1_input;
   register #(.WIDTH(DATA_WIDTH)) reg_storage0(.q(storage0), .d(data_in), .clk(clk), .enable(add_en), .rst_b(rst_b));
   register #(.WIDTH(DATA_WIDTH)) reg_storage1(.q(storage1), .d(storage1_input), .clk(clk), .enable(add_en), .rst_b(rst_b));//--

   wire add_issue, bypass_issue;
   wire add_en_reg;
   register #(.WIDTH(1)) reg_add_en(.q(add_en_reg), .d(add_en), .clk(clk), .enable(1'b1), .rst_b(rst_b));
   
   wire valid_storage0, valid_storage1;   
   wire [BITS_ROW_IDX - 1 : 0] row_idx_storage0, row_idx_storage1;
   wire [`DATA_PRECISION - 1 : 0] value_storage0, value_storage1, adder_in0, adder_in1;
           
   assign valid_storage0 = storage0[0];
   assign valid_storage1 = storage1[0];
   assign row_idx_storage0 = storage0[DATA_WIDTH - 1 : DATA_WIDTH - BITS_ROW_IDX];
   assign row_idx_storage1 = storage1[DATA_WIDTH - 1 : DATA_WIDTH - BITS_ROW_IDX];
   assign value_storage0 = storage0[DATA_WIDTH - BITS_ROW_IDX - 1 : DATA_WIDTH - BITS_ROW_IDX - `DATA_PRECISION];
   assign value_storage1 = storage1[DATA_WIDTH - BITS_ROW_IDX - 1 : DATA_WIDTH - BITS_ROW_IDX - `DATA_PRECISION];
   
   assign add_issue = add_en && valid_storage0 && valid_storage1 && (row_idx_storage0 == row_idx_storage1);
  ////assign bypass_issue = add_en && valid_storage1 && ((row_idx_storage0 != row_idx_storage1) || ~valid_storage0);
   assign bypass_issue = add_en && valid_storage1 && valid_storage0 && (row_idx_storage0 != row_idx_storage1);
   
   assign adder_in0 = add_issue ? value_storage0 : '0;
   assign adder_in1 = (add_issue || bypass_issue) ? value_storage1 : '0;
   //assign storage1_input = (add_issue || bypass_issue) ? '0 : storage0;
   assign storage1_input = add_issue ? '0 : storage0;
   //Note: if invalid data comes when add_en=1, the adder will pass the data in storage1. This is probably not ideal. For only one adder stage this might not be a big problem. But for multiple adder stages, we should not pass the data in storage1 just because new invalid data came in. We can control it by putiing more logic with add_en in the upper level of hierarchy.
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
   wire data_valid;   
   wire [BITS_ROW_IDX - 1 : 0] data_row_idx;
   assign data_valid = valid_storage1;
   assign data_row_idx = row_idx_storage1;
   
   wire add_en_enhanced;
   assign add_en_enhanced = add_en && (add_issue || bypass_issue);

   wire add_out_valid;   
   wire [BITS_ROW_IDX - 1 : 0] add_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] add_out_value;
     
   adder_sing_w_ctrl add_sing
     (//input
      .clk, .rst_b, .adder_select(add_en_enhanced), 
      .data_in0(adder_in0), .data_in1(adder_in1), 
      .data_valid, .data_row_idx,
      //output
      .data_valid_reg(add_out_valid), .data_row_idx_reg(add_out_row_idx),
      .add_result(add_out_value));
   
   assign data_out_add_stg = {add_out_row_idx, add_out_value, add_out_valid};
      
endmodule // adder_stage
