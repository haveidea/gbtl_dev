//
//---------------------------------------------------------------------------
// Combinational adder   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module adder_comb_w_ctrl 
   (
    input clk, rst_b, adder_select, ena,
    input [`DATA_PRECISION - 1 : 0] data_in0, data_in1,
    input data_valid,
    input [`BITS_ROW_IDX - 1 : 0] data_row_idx,
    
    output logic data_valid_reg,
    output logic [`BITS_ROW_IDX - 1 : 0] data_row_idx_reg,
    output [`DATA_PRECISION - 1 : 0] add_result);

   logic [`DATA_PRECISION - 1 : 0] data_in0_reg, data_in1_reg;
       
   single_adder_comb adder_bb(
      .aclr(2'b0),		 
      .ax(data_in0_reg),
      .ay(data_in1_reg),
      .result(add_result)); 

   always_ff @ (posedge clk) begin
      if(~rst_b) begin
	 data_in0_reg <= 0;
	 data_in1_reg <= 0;
	 data_valid_reg <= 0;
	 data_row_idx_reg <= 0;
      end
      else if (ena) begin
	 data_in0_reg <= data_in0;
	 data_in1_reg <= data_in1;
	 data_valid_reg <= data_valid;
	 data_row_idx_reg <= data_row_idx;
      end
   end

endmodule 
