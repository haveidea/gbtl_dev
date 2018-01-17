//
//---------------------------------------------------------------------------
// Fast merge stage comprising atoms   
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module merge_stage_fast_fifo_based 
  #(
    parameter
    NUM_ATOMS = 1,
    DATA_WIDTH = `DATA_WIDTH_ADD_STG)
   (//input
    input rst_b, clk, global_en, 
    input [NUM_ATOMS - 1 : 0] next_fifo_full, 
    input [(NUM_ATOMS << 1) - 1 : 0] fifo_wr_en,      
    input [(NUM_ATOMS << 1) - 1 : 0] [DATA_WIDTH - 1 : 0] data_in,
        
    //enable signals are generated inside the rd/wr cycle				      
    output [(NUM_ATOMS << 1) - 1 : 0] fifo_full,
    output [NUM_ATOMS - 1 : 0] next_fifo_wr_en,  	    
    output [NUM_ATOMS - 1 : 0] [DATA_WIDTH - 1 : 0] data_out);

   genvar i;
   generate
      for (i = 0; i < NUM_ATOMS; i = i + 1) begin 
	 merge_atom_fast_fifo_based atom
         (//input
	  .rst_b, .clk, .global_en, .next_fifo_full(next_fifo_full[i]),
          .f0_wr_en(fifo_wr_en[(i<<1)]), .f1_wr_en(fifo_wr_en[(i<<1) + 1]),
	  .din_f0(data_in[(i<<1)]), .din_f1(data_in[(i<<1) + 1]),
	  
	  //output
	  .next_fifo_wr_en(next_fifo_wr_en[i]),
	  .f0_full(fifo_full[(i<<1)]), .f1_full(fifo_full[(i<<1) + 1]),
	  .data_out(data_out[i]));
      end     
   endgenerate
   
endmodule 
   

	  
