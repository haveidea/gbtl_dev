//// register: A register which may be reset to an arbirary value
////
//// q      (output) - Current value of register
//// d      (input)  - Next value of register
//// clk    (input)  - Clock (positive edge-sensitive)
//// enable (input)  - Load new value?
//// reset  (input)  - System reset
////
module register(q, d, clk, enable, rst_b);
   parameter
     WIDTH = 1,
     RESET_VALUE = 0;
   
   output reg [WIDTH - 1 : 0] q;
   input [WIDTH - 1 : 0]  d;
   input clk, enable, rst_b;

   always_ff @(posedge clk) begin
     if (~rst_b)
       q <= RESET_VALUE;
     else if (enable)
       q <= d;
   end
endmodule // register

module register2D(q, d, clk, enable, rst_b);
   parameter
     WIDTH1 = 1,
     WIDTH2 = 1,
     RESET_VALUE = 0;
   
   output reg [WIDTH1 - 1 : 0] [WIDTH2 - 1 : 0] q;
   input [WIDTH1 - 1 : 0] [WIDTH2 - 1 : 0] d;
   input clk, enable, rst_b;

   always_ff @(posedge clk) begin
     if (~rst_b)
       for (integer i=0; i < WIDTH1; i = i+1) begin
	  q[i] <= RESET_VALUE;
       end
     else if (enable)
       q <= d;
   end
endmodule // register


module delay(q, d, clk, enable, rst_b);
   parameter
     WIDTH = 1,
     RESET_VALUE = 0,
     DEPTH = 1;
     
   output reg [WIDTH - 1 : 0] q; 
   input [WIDTH - 1 : 0]  d;
   input clk, enable, rst_b;

   wire [WIDTH - 1 : 0] connect_wire[DEPTH : 0] ;
   assign connect_wire[0] = d;
   assign q = connect_wire[DEPTH];
 
   genvar i;
   generate
      for (i = 1; i <= DEPTH; i = i + 1) begin : delay_reg_arr
	 register #(.WIDTH(WIDTH), .RESET_VALUE(RESET_VALUE)) DFF(.q(connect_wire[i]), .d(connect_wire[i-1]), .clk(clk), .enable(enable), .rst_b(rst_b));
      end   
   endgenerate 
endmodule // delay


