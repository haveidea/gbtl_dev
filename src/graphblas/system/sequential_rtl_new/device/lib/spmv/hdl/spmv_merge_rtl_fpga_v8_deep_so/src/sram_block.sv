//
//---------------------------------------------------------------------------
// SRAM block 
//  
//  
//---------------------------------------------------------------------------
//

`include "definitions.vh"

module sram_block(CLK, BLK_RE, DRWL, DWWL, WBL, ARBL);
   
   parameter
     NUM_BRICKS = 1,
     BL_WIDTH = `LIM_BRICK_WORD_SIZE,
     WL_WIDTH = `LIM_BRICK_WORD_NUM;
   
   input CLK; 
   input [NUM_BRICKS - 1 : 0] BLK_RE;  
   input [WL_WIDTH - 1 : 0] DRWL, DWWL;
   input [BL_WIDTH - 1 : 0] WBL;
   
   output logic [BL_WIDTH - 1 : 0] ARBL;

   logic [NUM_BRICKS - 1 : 0][BL_WIDTH - 1 : 0] ARBL_single;
      
   genvar j0;
   generate 
      for (j0 = 0; j0 < NUM_BRICKS; j0 = j0 + 1) begin : bricks
	 sram_brick brick_single(.CLK, .BLK_RE(BLK_RE[j0]),
           .DRWL(DRWL[`LIM_BRICK_WORD_NUM * (j0 + 1) - 1 : `LIM_BRICK_WORD_NUM * j0]), 
           .DWWL(DWWL[`LIM_BRICK_WORD_NUM * (j0 + 1) - 1 : `LIM_BRICK_WORD_NUM * j0]),
           .WBL,
           .ARBL(ARBL_single[j0]));
      end 
   endgenerate

   /*
   genvar j1;
   generate 
      for (j1 = 0; j1 < NUM_BRICKS; j1 = j1 + 1) begin : arbls
	 assign ARBL = BLK_RE[j1] ? ARBL_single[j1] : 'z; 
      end 
   endgenerate
    */

   always_comb begin
      ARBL = 'z;
      for(integer i0 = 0; i0 < NUM_BRICKS; i0 = i0 + 1) begin
	 if(BLK_RE[i0])
	   ARBL = ARBL_single[i0];
      end
   end
   
endmodule
