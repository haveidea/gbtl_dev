//
//---------------------------------------------------------------------------
// Clock divider
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module clk_divider 
  #(
    parameter
    DIV_RATIO_HALF = `DIV_RATIO_HALF,
    BITS_DIV_RATIO_HALF = `BITS_DIV_RATIO_HALF) 
   (
    input clk, rst_b,

    output logic [BITS_DIV_RATIO_HALF - 1 :0] clk_div_ctr,  					  
    output logic clk_divided);
 
   always_ff @ (posedge clk) begin
      if(~rst_b || clk_div_ctr == DIV_RATIO_HALF - 1)
        clk_div_ctr <= '0;
      else
        clk_div_ctr <= clk_div_ctr + 1;
   end

   always_ff @ (posedge clk) begin
    if (~rst_b)
      clk_divided <= '0;
    else if (clk_div_ctr == DIV_RATIO_HALF - 1)
      clk_divided <= ~clk_divided;
   end


endmodule // clk_divider
