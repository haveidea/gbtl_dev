//
//---------------------------------------------------------------------------
// This module only stores the results from a single merge unit
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module unit_output_write
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_ADD_STG,
    NUM_OUTPUT_WORDS_PER_UNIT = `NUM_OUTPUT_WORDS_PER_UNIT,
    BITS_OUTPUT_ADDR_PER_UNIT = `BITS_OUTPUT_ADDR_PER_UNIT) 
   (//input
   input rst_b, clk, unit_en, mode,  
   input [BITS_OUTPUT_ADDR_PER_UNIT - 1 : 0] rd_addr,						   
   input [DATA_WIDTH - 1 : 0] data_in,
					
   output logic [BITS_OUTPUT_ADDR_PER_UNIT - 1 : 0] wr_addr,		  
   output logic [DATA_WIDTH - 1 : 0] data_out);

//wire [BITS_OUTPUT_ADDR_PER_UNIT - 1 : 0] wr_addr;
wire wr_en;

wire data_in_valid;
wire [`BITS_ROW_IDX - 1 : 0] data_in_row_idx;
wire [`DATA_PRECISION - 1 : 0] data_in_value;
      
assign data_in_valid = data_in[0];
assign data_in_row_idx = data_in[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
assign data_in_value = data_in[DATA_WIDTH - `BITS_ROW_IDX - 1 : DATA_WIDTH - `BITS_ROW_IDX - `DATA_PRECISION];   

assign wr_en = (mode == `MODE_WORK && unit_en && data_in_valid && data_in_row_idx != 0 && wr_addr != (NUM_OUTPUT_WORDS_PER_UNIT - 1)) ? 1'b1 : 1'b0;
   
//valiables with unpacked are not displayed in NCSim simulation, but works fine   
logic [NUM_OUTPUT_WORDS_PER_UNIT - 1 : 0] [DATA_WIDTH - 1 : 0] out_storage_unit;   

assign data_out = out_storage_unit[rd_addr];
   
wire [NUM_OUTPUT_WORDS_PER_UNIT - 1 : 0] wr_decode;
assign wr_decode = 1 << wr_addr;      
   
//********** INPUT FLOPS **********   
always_ff @ (posedge clk) begin
   if(~rst_b) begin
      for (integer i = 0; i < NUM_OUTPUT_WORDS_PER_UNIT; i = i + 1) begin
	 out_storage_unit[i] <= 0;
	 wr_addr <= 0;
      end
   end
   else begin
      for (integer i = 0; i < NUM_OUTPUT_WORDS_PER_UNIT; i = i + 1) begin
	 out_storage_unit[i] <= (wr_decode[i] && wr_en) ? data_in : out_storage_unit[i];
	 wr_addr <= wr_en ? wr_addr + 1 : wr_addr; 		   
      end
   end
end

endmodule

