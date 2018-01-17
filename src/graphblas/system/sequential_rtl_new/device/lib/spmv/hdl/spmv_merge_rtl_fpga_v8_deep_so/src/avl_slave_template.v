/*
  Legal Notice: (C)2008 Altera Corporation. All rights reserved.  Your
  use of Altera Corporation's design tools, logic functions and other
  software and tools, and its AMPP partner logic functions, and any
  output files any of the foregoing (including device programming or
  simulation files), and any associated documentation or information are
  expressly subject to the terms and conditions of the Altera Program
  License Subscription Agreement or other applicable license agreement,
  including, without limitation, that your use is for the sole purpose
  of programming logic devices manufactured by Altera and sold by Altera
  or its authorized distributors.  Please refer to the applicable
  agreement for further details.
*/

/*

  Author:  JCJB
  Date:  09/03/2008
  
  This slave component has a parameterizable data width and 16 input/output
  words.  There are five modes for each addressable word in this component
  as follows:
  
  Mode = 0  --> Output only
  Mode = 1  --> Input only
  Mode = 2  --> Output and input (independent I/O, default)
  Mode = 3  --> Output with loopback (software readable output registers)
  Mode = 4	--> Disabled

  This component is always available so the waitrequest signal is not used
  and it has fixed read and write latencies.  The write latency is 0 and the
  read latency is 3 cycles.  If you attempt to access a location that doesn't
  support the necessary functionality then you will either write to a
  non-existent register (write to space) or will readback 0 as the inputs
  will be grounded if they are disabled.  Inputs or outputs that are removed
  will be due to the component tcl file stubbing the signals.  Disabled outputs
  will not be exposed at the top of the system and the Quartus II software
  will optimize the register away.  Disabled inputs (except in the loopback
  mode) will not be exposed at the top and internally be wired to ground.
  The Quartus II software as a result will optimize the input registers to
  be hardcoded wires set to ground automatically.
  
  In order for your external logic to know which register is being accessed
  you will need to enable 'ENABLE_SYNC_SIGNALS' by setting it to 1.  When
  enabled, the user_chipselect/byteenable/read/write signals will be exposed to your
  external logic which you can use to determine which register is being accessed
  and whether it's a read or write access.
  
  If you use the syncronization signals use the following to qualify them:
  
  Read:  user_chipselect[x] AND user_read
  Write:  user_chipselect[x] AND user_write AND user_byteenable
  
  Note: Reads return the full word regardless of the byteenables presented.
*/




module slave_template (
	// signals to connect to an Avalon clock source interface
	clk,
	reset,
	
	// signals to connect to an Avalon-MM slave interface
	slave_address,
	slave_read,
	slave_write,
	slave_readdata,
	slave_readdatavalid,
  slave_waitrequest,
	slave_writedata,
	slave_byteenable

);

	// most of the set values will only be used by the component .tcl file.  The DATA_WIDTH and MODE_X = 3 influence the hardware created.
	// ENABLE_SYNC_SIGNALS isn't used by this hardware at all but it provided anyway so that it can be exposed in the component .tcl file
	// to control the stubbing of certain signals.
	parameter DATA_WIDTH = 512;          // word size of each input and output register
	parameter ENABLE_SYNC_SIGNALS = 0;  // only used by the component .tcl file, 1 to expose user_chipselect/write/read, 0 to stub them
	parameter CAPACITY    = 1024* 1024;  // only used by the component .tcl file, 1 to expose user_chipselect/write/read, 0 to stub them
	// clock interface
	input clk;
	input reset;
	
	
	// slave interface
	input [26:0] slave_address;
	input slave_read;
	input slave_write;
	output [DATA_WIDTH-1:0] slave_readdata;
	output                  slave_readdatavalid;
  output                  slave_waitrequest;
	reg [DATA_WIDTH-1:0] slave_readdata_temp;
	input [DATA_WIDTH-1:0] slave_writedata;
	input [(DATA_WIDTH/8)-1:0] slave_byteenable;

  reg [DATA_WIDTH-1: 0] mem[CAPACITY-1:0];
  integer i;

wire slave_read_active = slave_read & ~slave_waitrequest;
initial begin
  for (i = 0; i < CAPACITY; i = i +1)
      mem[i] = i;
end

  always @ (posedge clk)
  if(slave_write) begin
      mem[slave_address % CAPACITY]<= slave_writedata;
  end

  always @ (posedge clk)
  if(slave_read_active) begin
       slave_readdata_temp <= mem[slave_address % CAPACITY ];
  end

reg slave_read_d;

always @ (posedge clk)
if(reset)
  slave_read_d <= 1'b0;
else
  slave_read_d <= slave_read_active;
	
wire empty;
reg  rd_en;

wire  slave_waitrequest_temp;

  fifo_fwft #(.DATA_WIDTH(512), .DEPTH_WIDTH(8))
  u_fifo
  (
    .clk(clk),
    .rst(reset),
    .din(slave_readdata_temp),
    .wr_en(slave_read_d),
    .full(slave_waitrequest_temp),
    .dout(slave_readdata),
    .rd_en(rd_en),
    .empty(empty)
  );

reg my_rand;

always @(posedge clk)
    my_rand = $random%2 ;

assign slave_waitrequest = slave_waitrequest_temp | my_rand;


always @(posedge clk)begin
    rd_en = ($random%2) & ~empty ;
end

assign slave_readdatavalid = rd_en;

initial begin
  $readmemh("fpga_input_lists_512_2blk.txt",mem);
end

endmodule


