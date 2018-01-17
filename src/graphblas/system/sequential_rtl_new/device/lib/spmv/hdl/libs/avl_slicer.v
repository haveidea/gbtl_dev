module avl_slicer
#(parameter ADDR_WIDTH = 27, DATA_WIDTH = 576)
(
  input clk,
  input reset,
  
 input      [ADDR_WIDTH-1:0]      s0_address      ,
 input                            s0_read         ,
 output                           s0_waitrequest  ,
 output reg [DATA_WIDTH-1:0]      s0_readdata     , // done
 input                            s0_write        ,
 input      [DATA_WIDTH-1:0]      s0_writedata    ,
 output reg                       s0_readdatavalid, // done
 input      [DATA_WIDTH/8 - 1:0]  s0_be           ,
 input      [6:0]                 s0_burstcount   ,

 output reg [ADDR_WIDTH-1:0]      m0_address      ,
 output reg                       m0_read         ,
 input                            m0_waitrequest  ,
 input      [DATA_WIDTH-1:0]      m0_readdata     , // done
 output reg                       m0_write        ,
 output reg [DATA_WIDTH-1:0]      m0_writedata    ,
 input                            m0_readdatavalid, // done
 output reg [DATA_WIDTH/8 - 1:0]  m0_be           ,
 output reg [6:0]                 m0_burstcount   
);

reg latch_valid;

always @ (posedge clk)
if(reset) begin
  s0_readdata <= 'h0;
  s0_readdatavalid <= 1'b0;
end
else begin
  s0_readdata      <= m0_readdata     ;
  s0_readdatavalid <= m0_readdatavalid;
end


always @ (posedge clk)
if(reset) 
  latch_valid <= 1'b0;
else if(!latch_valid & (s0_read | s0_write))
  latch_valid <= 1'b1;
else if(latch_valid & ~(s0_read| s0_write) & ~m0_waitrequest)
  latch_valid <= 1'b0;
else if(latch_valid & ~m0_waitrequest & (s0_read | s0_write))
  latch_valid <= 1'b1;

always @ (posedge clk)
if(reset) begin
  m0_address<= 'h0;
  m0_read<= 1'b0;
  m0_write<= 1'b0;
  m0_writedata<= 'h0;
  m0_be<= 'h0;
  m0_burstcount<= 'h0;
end
else if((~latch_valid) | (latch_valid & ~m0_waitrequest)) begin
  m0_address<= s0_address;
  m0_read<= s0_read;
  m0_write<= s0_write;
  m0_writedata<= s0_writedata;
  m0_be<= s0_be;
  m0_burstcount<= s0_burstcount;
end

assign s0_waitrequest = latch_valid & m0_waitrequest;
  
endmodule
