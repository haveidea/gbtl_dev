module mem_module(
clk,
addr,
data_in,
data_out,
data_op // 0: rd, 1:wr
);
  function integer clogb2 (input integer bit_depth);              
  begin                                                           
    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
      bit_depth = bit_depth >> 1;                                 
    end                                                           
  endfunction                                                     
parameter  WIDTH = 32;
parameter  SIZE  = 16;
localparam ADDR_BITS =  clogb2(SIZE -1);

input                        clk;
input       [ADDR_BITS-1:0]  addr;

input       [WIDTH -1:0]     data_in;
output reg  [WIDTH -1:0]     data_out;

input                        data_op;


reg         [WIDTH -1 :0]    mem[SIZE -1:0];

always @ (posedge clk)
    if(data_op ) // wr
        mem[addr] <= data_in;


always @ (posedge clk)
    data_out <= mem[addr];

endmodule
