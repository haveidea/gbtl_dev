//
//---------------------------------------------------------------------------
// SRAM brick 
//  
//  
//---------------------------------------------------------------------------
//

`include "definitions.vh"

module sram_brick(CLK, BLK_RE, DRWL, DWWL, WBL, ARBL);
   
   parameter 
     BL_WIDTH = `LIM_BRICK_WORD_SIZE,
     ADDR_WIDTH = `BITS_ADDR_LIM_BRICK,	
     WL_WIDTH = `LIM_BRICK_WORD_NUM;
   
   input CLK, BLK_RE;//BLK_RE enables the reading from that block.useful when you stack multiple bricks on global BL
   input [WL_WIDTH - 1 : 0] DRWL, DWWL;  
   input [BL_WIDTH - 1 : 0] WBL;
   
   output reg [BL_WIDTH - 1 : 0] ARBL;			  
   
   reg [BL_WIDTH - 1 : 0] mem_brick [WL_WIDTH - 1 : 0]; 
   wire [ADDR_WIDTH - 1 : 0] rd_memaddr, wr_memaddr;
     
   encoder_brick #(.WL_WIDTH(WL_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) enco_brk_rd (.wls(DRWL), .addr(rd_memaddr));
   encoder_brick #(.WL_WIDTH(WL_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) enco_brk_wr (.wls(DWWL), .addr(wr_memaddr));
   
   always @(posedge CLK) begin
      
      //read
      if(BLK_RE)
	ARBL <= mem_brick[rd_memaddr];
      else
	ARBL <= 'bz;
      //write
      if(|DWWL)
	mem_brick[wr_memaddr] <= WBL;
   end
   
   always @(negedge CLK) begin
      
      ARBL <= 'bz;
   end
   

   /*
   // This is the true verilog behaviour. However, for post-layout simulation, this will create problem as there is no gate delays counted here.  
   always_comb begin
      
      //read
      if(BLK_RE && CLK == 1)
	ARBL = mem_brick[rd_memaddr];
      else
	ARBL = 'bz;
   end
   
   always_latch begin
      //write
      if(|DWWL && CLK == 1)
	mem_brick[wr_memaddr] = WBL&(~WBL_B);
   end
   */
   
endmodule
