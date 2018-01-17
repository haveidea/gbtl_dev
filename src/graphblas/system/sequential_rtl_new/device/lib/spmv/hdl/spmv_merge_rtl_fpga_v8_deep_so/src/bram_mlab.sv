//
//---------------------------------------------------------------------------
// FPGA block memory for MLAB 
//  
//  
//---------------------------------------------------------------------------
//

`include "definitions.vh"

//`timescale `TIME_SCALE

module bram_mlab(CLK, rd_en, wr_en, rd_addr, wr_addr, WBL, ARBL);
   
   parameter 
     BL_WIDTH = `LIM_BRICK_WORD_SIZE,
     ADDR_WIDTH = `BITS_ADDR_LIM_BRICK,	
     WL_WIDTH = `LIM_BRICK_WORD_NUM;
   
   input CLK, rd_en, wr_en;
   input [ADDR_WIDTH - 1 : 0] rd_addr, wr_addr;
   input [BL_WIDTH - 1 : 0] WBL;    
   output logic [BL_WIDTH - 1 : 0] ARBL;			  
   
   (* ramstyle="MLAB,no_rw_check" *) logic [BL_WIDTH - 1 : 0] mem_brick [(2**ADDR_WIDTH) - 1 : 0]; 
  
   always @(posedge CLK) begin    
      //read
      if(rd_en)
	ARBL <= mem_brick[rd_addr];
      //else
	//ARBL <= 'bz;
      //else
	//ARBL <= '0;
      //write
      if(wr_en)
	mem_brick[wr_addr] <= WBL;
   end
     
endmodule
