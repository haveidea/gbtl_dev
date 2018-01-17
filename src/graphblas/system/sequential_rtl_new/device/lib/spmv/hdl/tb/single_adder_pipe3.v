
module single_adder_pipe3 ( 
input aclr ,  
input [31:0] ax ,  
input [31:0] ay ,  
input        clk ,  
input        ena ,  
output  [31:0] result
);

assign result = ax + ay;
endmodule

