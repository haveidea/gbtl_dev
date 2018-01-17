//
//---------------------------------------------------------------------------
// Pipelined adder   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module adder_pipe_w_ctrl
  #(
    parameter
    NUM_STG_ADDER_PIPE = `NUM_STG_ADDER_PIPE)
   (
    input clk, rst_b, adder_select, ena,
    input [`DATA_PRECISION - 1 : 0] data_in0, data_in1,
    input data_valid,
    input [`BITS_ROW_IDX - 1 : 0] data_row_idx,
    
    output logic data_valid_reg,
    output logic [`BITS_ROW_IDX - 1 : 0] data_row_idx_reg,
    output [`DATA_PRECISION - 1 : 0] add_result);

   //logic [`DATA_PRECISION - 1 : 0] data_in0_reg, data_in1_reg;
   logic [1 : 0] 		   aclr;
   assign aclr = rst_b ? 2'b00 : 2'b11;
        
   single_adder_pipe3 adder_bb(
      .aclr(aclr),		 
      //.ax(data_in0_reg),
      //.ay(data_in1_reg),
      .ax(data_in0),
      .ay(data_in1),
      .clk(clk), .ena(ena),			       
      .result(add_result));
   
   logic [NUM_STG_ADDER_PIPE : 0] [`BITS_ROW_IDX - 1 : 0] row_idx_internal;
   logic [NUM_STG_ADDER_PIPE : 0] [1 : 0] valid_internal;//actually need 1 dimensional array. but single dimension creates error in simulation because of two always block assignment. 
   
   always_ff @ (posedge clk) begin
      if(!rst_b) begin
	 //ena <= 0;
	 //data_in0_reg <= '0;
	 //data_in1_reg <= '0;
	 valid_internal[0] <= '0;
	 row_idx_internal[0] <= '0;
      end
      //else if (adder_select) begin
      else if (ena) begin	 
	 //ena <= adder_select;
	 //data_in0_reg <= data_in0;
	 //data_in1_reg <= data_in1;
	 valid_internal[0] <= {1'b0, data_valid};
	 row_idx_internal[0] <= data_row_idx;
      end
   end
      
   integer i0;
   always_ff @ (posedge clk) begin
      if(~rst_b) begin
	 for (i0 = 0; i0 < NUM_STG_ADDER_PIPE; i0 = i0 + 1) begin
	    valid_internal[i0+1] <= '0;
	    row_idx_internal[i0+1] <= '0;
	 end
      end
      if (ena) begin
	 for (i0 = 0; i0 < NUM_STG_ADDER_PIPE; i0 = i0 + 1) begin
	    valid_internal[i0+1] <= valid_internal[i0];
	    row_idx_internal[i0+1] <= row_idx_internal[i0];
	 end
      end
   end
   assign data_valid_reg = valid_internal[NUM_STG_ADDER_PIPE][0];
   assign data_row_idx_reg = row_idx_internal[NUM_STG_ADDER_PIPE];
   
endmodule 
