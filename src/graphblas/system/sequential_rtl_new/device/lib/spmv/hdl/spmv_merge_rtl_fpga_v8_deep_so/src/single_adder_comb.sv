//
//---------------------------------------------------------------------------
// Non-pipelined adder. This module should be replaced by FPGA FP adder   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module single_adder_comb 
   (
    input [1 : 0] aclr,
    input [`DATA_PRECISION - 1 : 0] ax, ay,

    output [`DATA_PRECISION - 1 : 0] result);
      
   logic [`RND_WIDTH - 1 : 0] rnd_nearest; 
   assign rnd_nearest = `RND_NEAREST;
   logic [`STATUS_WIDTH - 1 : 0] status;
      
   DW_fp_add #(.sig_width(`SIG_WIDTH), .exp_width(`EXP_WIDTH), .ieee_compliance(`IEEE_COMPLIANCE))
   adder(
      .a(ax),
      .b(ay),
      .rnd(rnd_nearest),
      .z(result),
      .status(status));

endmodule 
