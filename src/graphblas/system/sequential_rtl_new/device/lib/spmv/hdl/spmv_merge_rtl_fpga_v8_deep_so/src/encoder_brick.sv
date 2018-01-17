//
//---------------------------------------------------------------------------
//  LiM SRAM block encoder
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module encoder_brick #(
   parameter
     ADDR_WIDTH = `BITS_ADDR_LIM_BRICK,
     WL_WIDTH = 1 << ADDR_WIDTH) (

   input [WL_WIDTH - 1 : 0] wls,
   output reg [ADDR_WIDTH - 1 : 0] addr);

   always_comb begin
     unique case(wls)
         32'h00000001: addr = 5'd0;
         32'h00000002: addr = 5'd1;
         32'h00000004: addr = 5'd2;
         32'h00000008: addr = 5'd3;
         32'h00000010: addr = 5'd4;
         32'h00000020: addr = 5'd5;
         32'h00000040: addr = 5'd6;
         32'h00000080: addr = 5'd7;
         32'h00000100: addr = 5'd8;
         32'h00000200: addr = 5'd9;
         32'h00000400: addr = 5'd10;
         32'h00000800: addr = 5'd11;
         32'h00001000: addr = 5'd12;
         32'h00002000: addr = 5'd13;
         32'h00004000: addr = 5'd14;
         32'h00008000: addr = 5'd15;
         32'h00010000: addr = 5'd16;
         32'h00020000: addr = 5'd17;
         32'h00040000: addr = 5'd18;
         32'h00080000: addr = 5'd19;
         32'h00100000: addr = 5'd20;
         32'h00200000: addr = 5'd21;
         32'h00400000: addr = 5'd22;
         32'h00800000: addr = 5'd23;
         32'h01000000: addr = 5'd24;
         32'h02000000: addr = 5'd25;
         32'h04000000: addr = 5'd26;
         32'h08000000: addr = 5'd27;
         32'h10000000: addr = 5'd28;
         32'h20000000: addr = 5'd29;
         32'h40000000: addr = 5'd30;
         32'h80000000: addr = 5'd31;
         default: addr = 'bz;
     endcase
   end
endmodule