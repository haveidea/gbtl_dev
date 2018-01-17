//
//---------------------------------------------------------------------------
// register based memory block for segment for both buffer and stage output
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module reg_mem(CLK, rd_en, wr_en, rd_addr, wr_addr, WBL, ARBL);
   
   parameter 
     BL_WIDTH = `LIM_BRICK_WORD_SIZE,
     ADDR_WIDTH = `BITS_ADDR_LIM_BRICK,	
     WL_WIDTH = `LIM_BRICK_WORD_NUM;
   
   input CLK, rd_en, wr_en;
   input [ADDR_WIDTH - 1 : 0] rd_addr, wr_addr;
   input [BL_WIDTH - 1 : 0] WBL;    
   output logic [BL_WIDTH - 1 : 0] ARBL;			  
   
   logic [BL_WIDTH - 1 : 0] mem [WL_WIDTH - 1 : 0]; 

   always_ff @(posedge CLK) begin    
      /*
      if(~rst_b) begin
	 for (integer i = 0; i < WL_WIDTH; i = i + 1) begin
	    mem[i] <= '0; 
	 end
      end */ //try this without reseting
      //write
      if(wr_en) begin
	 mem[wr_addr] <= WBL;
      end
   end 

   logic [ADDR_WIDTH - 1 : 0] rd_addr_reg;
   always_ff @(posedge CLK) begin    
      //if(rd_en) begin
	 rd_addr_reg <= rd_addr;
      //end
   end 
   assign ARBL = mem[rd_addr_reg];

endmodule

