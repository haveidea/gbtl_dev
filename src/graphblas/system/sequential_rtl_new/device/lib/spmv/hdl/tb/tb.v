`timescale 1ns/1ns
`define CLOCK_MMAP 4
`define CLOCK_DDR  2


`define AVL_ADDR_WIDTH 32
`define SPMV_ADDR_WIDTH 32
`define DATA_WIDTH      512
module tb();
  reg  ddr_clk;
  reg  ddr_rstn;

  wire [`AVL_ADDR_WIDTH -1:0]  m0_address      ;
  wire         m0_read         ;
  reg          m0_read_d       ;
  reg          m0_read_dd      ;
  reg          m0_read_ddd     ;
  wire [`DATA_WIDTH-1:0] m0_readdata     ;
  wire         m0_write        ;
  wire [`DATA_WIDTH-1:0] m0_writedata    ;

  wire [`DATA_WIDTH/8-1:0] m0_byteenable = {`DATA_WIDTH/8{1'b1}};

  wire [`AVL_ADDR_WIDTH -1:0]  temp_address      ;
  wire                         temp_read         ;
  reg                          temp_read_d       ;
  reg                          temp_read_dd      ;
  reg                          temp_read_ddd     ;
  wire [`DATA_WIDTH-1:0]       temp_readdata     ;
  wire                         temp_write        ;
  wire [`DATA_WIDTH-1:0]       temp_writedata    ;

  wire [`DATA_WIDTH/8 - 1:0]  m0_be           ;
  wire [6:0]                  m0_burstcount   ;
  reg spmv_start;
  reg spmv_clear;




top #(.ADDRESS_SIZE(`AVL_ADDR_WIDTH))
u_top
(
  .ddr3_clk              (ddr_clk          ),
  .ddr3_reset            (~ddr_rstn        ),
  .ddr3_m0_address       (m0_address       ),
  .ddr3_m0_read          (m0_read          ),
  .ddr3_m0_waitrequest   (m0_waitrequest   ),
  .ddr3_m0_readdata      (m0_readdata      ),
  .ddr3_m0_write         (m0_write         ),
  .ddr3_m0_writedata     (m0_writedata     ),
  .ddr3_m0_readdatavalid (m0_readdatavalid ),
  .ddr3_m0_be            (m0_be            ),
  .ddr3_m0_burstcount    (m0_burstcount    ),

  .spmv_start            (spmv_start),
  .spmv_clear            (spmv_clear),
  .spmv_done             (spmv_done)
  
);

slave_template 
#(.DATA_WIDTH(512))
u_slave_template
(
        // signals to connect to an Avalon clock source interface
        .clk      (ddr_clk),
        .reset    (~ddr_rstn),
        
        // signals to connect to an Avalon-MM slave interface
        .slave_address          ({m0_address[31:6]}),
        .slave_read             (m0_read),
        .slave_write            (m0_write),
        .slave_readdata         (m0_readdata[511:0]),
        .slave_readdatavalid    (m0_readdatavalid),
        .slave_waitrequest      (m0_waitrequest),
        .slave_writedata        (m0_writedata[511:0]),
        .slave_byteenable       (m0_byteenable)

);
  always #`CLOCK_DDR  ddr_clk = ~ddr_clk;

initial begin
  spmv_start = 1'b0;
  spmv_clear = 1'b0;
  repeat (100) @ (posedge ddr_clk);
  #1;
  spmv_start = 1'b1;
end

  initial begin
    ddr_clk    = 1'b0;
    ddr_rstn   = 1'b0;
    repeat(10) @ (posedge ddr_clk);
    ddr_rstn   = 1'b1;
  end

initial begin
  $display("simu start");
  repeat(500000) @ (posedge ddr_clk);
  $display("simu end");
  $finish();
end

initial begin
  $vcdplusfile("tb.vpd");
  $vcdpluson(0,tb);
end
//initial begin
//  $fsdbDumpfile("tb.fsdb");
//  $fsdbDumpvars(0,tb);
//  $fsdbDumpon;
//end

endmodule
