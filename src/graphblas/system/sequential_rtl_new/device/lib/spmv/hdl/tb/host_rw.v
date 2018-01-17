module host_rw #(parameter ADDRESS_SIZE = 27 ) (
  input ddr3_clk,
  input ddr3_reset,
  output [ADDRESS_SIZE-1:0]   host_m0_address      ,
  output                      host_m0_read         ,
  input                       host_m0_waitrequest  ,
  input [575:0]               host_m0_readdata     ,
  output                      host_m0_write        ,
  output [575:0]              host_m0_writedata    ,
  input                       host_m0_readdatavalid,
  output [71:0]               host_m0_be           ,
  output [6:0]                host_m0_burstcount   ,
  
  input [ADDRESS_SIZE-1:0]  test_addr,
  input [575:0]             test_wdata,
  output reg  [3:0]             host_status,
  input                     reg_host_load,
  input                     host_mode_start,
  
  output    reg [575:0]                host_rdata
); 
reg                     host_m0_read_reg;
reg                     host_m0_write_reg;
assign  host_m0_address     = test_addr[26:0]; // generated in mmp clock, used in ddr clock,don't need clock domain issue
assign  host_m0_writedata   = test_wdata;      // generated in mmp clock, used in ddr clock,don't need clock domain issue
assign  host_m0_be          ={72{1'b1}};
assign  host_m0_burstcount  = 7'h1;
assign host_m0_read  = host_m0_read_reg;
assign host_m0_write = host_m0_write_reg;

wire  host_mode_start_p;
reg   host_mode_start_d;
reg   host_is_stopped;
assign host_mode_start_p = host_mode_start& ~host_mode_start_d;

always @ (posedge ddr3_clk)
if(ddr3_reset)
  host_m0_read_reg <= 1'b0;
else if(reg_host_load & host_mode_start_p)
  host_m0_read_reg <= 1'b1;
else if(~host_m0_waitrequest)
  host_m0_read_reg <= 1'b0;

always @ (posedge ddr3_clk)
if(ddr3_reset)
  host_mode_start_d <= 1'b0;
else
  host_mode_start_d <= host_mode_start;


always @ (posedge ddr3_clk)
if(ddr3_reset) 
  host_is_stopped  <= 1'b1;
else if(host_mode_start_p)
    host_is_stopped <= 1'b0;
else if(~host_is_stopped && ((host_m0_read && host_m0_readdatavalid) | (host_m0_write & ~host_m0_waitrequest)))
    host_is_stopped <= 1'b1;

always @ (posedge ddr3_clk)
if(host_m0_readdatavalid)
  host_rdata<= host_m0_readdata;

always @ (posedge ddr3_clk)
if(ddr3_reset)
  host_m0_write_reg <= 1'b0;
else if(~reg_host_load& host_mode_start_p)
  host_m0_write_reg <= 1'b1;
else if(~host_m0_waitrequest)
  host_m0_write_reg <= 1'b0;

always @ (posedge ddr3_clk)
if(ddr3_reset)
    host_status <= 4'b0;
else if(host_mode_start_p)
    host_status <= 4'b1;
else if(host_is_stopped)
    host_status<= 4'b0;
endmodule
