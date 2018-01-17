module lsq2avl_mm
#(parameter NUM_LDQ=4, NUM_STQ=1, DDR_DATA_WIDTH=512, ADDR_WIDTH=32 ) //Memory Address Size (Avalon) 
(
  input clk,
  input rstn,
  // load queue
  input  [NUM_LDQ-1:0]                  ldq_ddr_addr_valid ,
  output [NUM_LDQ-1:0]                  ldq_ddr_addr_ready ,
  input  [NUM_LDQ*ADDR_WIDTH-1:0]       ldq_ddr_addr       ,
  output [NUM_LDQ-1:0]                  ldq_ddr_data_valid ,
  output [NUM_LDQ*DDR_DATA_WIDTH-1:0]  ldq_ddr_data       ,
  input  [NUM_STQ-1:0]                  stq_ddr_valid      ,
  output [NUM_STQ-1:0]                  stq_ddr_ready      ,
  input  [NUM_STQ*ADDR_WIDTH-1:0]       stq_ddr_addr       ,
  input  [NUM_STQ*DDR_DATA_WIDTH-1:0]  stq_ddr_data       ,

  input  [2:0]                          trans_size         , // 0: 64   byte
                                                             // 1: 128  byte
                                                             // 2: 256  byte
                                                             // 3: 512  byte
                                                             // 4: 1024 byte
                                                             // 5: 2048 byte
                                                             // 6: 4096 byte
                                                             // 7: 8192 byte
  // avl
  output reg [ADDR_WIDTH-1:0]           m0_address         ,
  output reg                            m0_read            ,
  input                                 m0_waitrequest     ,
  input  [DDR_DATA_WIDTH-1:0]          m0_readdata        ,
  output reg                            m0_write           ,
  output [DDR_DATA_WIDTH-1:0]          m0_writedata       ,
  input                                 m0_readdatavalid   ,
  output [DDR_DATA_WIDTH/8 -1:0]       m0_be              ,
  output [6:0]                          m0_burstcount      ,


  input                                 enable             ,
  output reg                            disabled

);

`ifdef DEBUG
  assign ldq_ddr_addr_valid ='h0;
  assign ldq_ddr_addr       ='h0;
  assign m0_be              ='h0;
  assign m0_burstcount      ='h1;
  assign stq_ddr_valid      ='h0;
  assign stq_ddr_addr       ='h0;
  assign stq_ddr_data       ='h0;

  always @ (*) begin
     m0_write           ='h0;
     m0_writedata       ='h0;
     m0_address         ='h0;
     m0_read            ='h0;
  end
`else
localparam LD_STATE = 1'b1;
localparam ST_STATE = 1'b0;
    function [$clog2(NUM_LDQ)-1:0] ff1;
        input [NUM_LDQ-1:0] in;
        integer i;
        begin
            ff1 = 0;
            for (i = NUM_LDQ-1; i >= 0; i=i-1) begin
                if (in[i])
                    ff1 = i;
            end
        end
    endfunction

    function [$clog2(NUM_STQ)-1:0] ff2;
        input [NUM_STQ-1:0] in;
        integer i;
        begin
            ff2 = 0;
            for (i = NUM_STQ-1; i >= 0; i=i-1) begin
                if (in[i])
                    ff2 = i;
            end
        end
    endfunction
reg                   ld_st_rr; // ld/st round robin

reg    [NUM_LDQ-1:0]  cur_ld_sel_mask;
reg    [NUM_STQ-1:0]  cur_st_sel_mask;
wire                  ld_trans_pending ;
wire                  st_trans_pending;
wire                  ld_trans_permitted;
wire                  st_trans_permitted;

reg [7:0] trans_cnt;
wire ld2st_transit;
wire st2ld_transit;

assign m0_burstcount = 7'h1;
assign m0_be         = {DDR_DATA_WIDTH/8{1'b1}};

wire [7:0] CNT_MAX;

assign CNT_MAX = (trans_size == 3'h0) ? 8'd0:
                 (trans_size == 3'h1) ? 8'd1:
                 (trans_size == 3'h2) ? 8'd3:
                 (trans_size == 3'h3) ? 8'd7:
                 (trans_size == 3'h4) ? 8'd15:
                 (trans_size == 3'h5) ? 8'd31:
                 (trans_size == 3'h6) ? 8'd63: 8'd127;

assign ld2st_transit = ((m0_read  & (~m0_waitrequest) & (trans_cnt == CNT_MAX))|(~m0_read  & (trans_cnt == 0))) & st_trans_pending;
assign st2ld_transit = ((m0_write & (~m0_waitrequest) & (trans_cnt == CNT_MAX))|(~m0_write & (trans_cnt == 0)))& ld_trans_pending;

wire [NUM_LDQ-1:0] ldq_grant;
wire [NUM_STQ-1:0] stq_grant;

arbitor 
#(.ARB_WIDTH(NUM_LDQ))
ld_arb (
  .clk   (clk),
  .rstn  (rstn),

  .next  (m0_read & ~m0_waitrequest & (trans_cnt == CNT_MAX)),
  .valid (ldq_ddr_addr_valid),
  .grant (ldq_grant)
);

arbitor 
#(.ARB_WIDTH(NUM_STQ))
st_arb (
  .clk   (clk),
  .rstn  (rstn),

  .next  (m0_write & ~m0_waitrequest & (trans_cnt == CNT_MAX)),
  .valid (stq_ddr_valid),
  .grant (stq_grant)
);

always @ (posedge clk)
if(!rstn)
  ld_st_rr<= LD_STATE;
else if(disabled       ) ld_st_rr<= LD_STATE;
else if(ld2st_transit && (ld_st_rr == LD_STATE)) ld_st_rr <= ST_STATE; // round_robin =1, write has higher priority.
else if(st2ld_transit && (ld_st_rr == ST_STATE)) ld_st_rr <= LD_STATE; // round_robin = 0, read has higher priority.

assign ld_trans_pending =  ~disabled & (|ldq_ddr_addr_valid);
assign st_trans_pending =  ~disabled & (|stq_ddr_valid);

assign ld_trans_permitted = (enable|~m0_waitrequest) & ld_trans_pending & (ld_st_rr == LD_STATE);
assign st_trans_permitted = (enable|~m0_waitrequest) & st_trans_pending & (ld_st_rr == ST_STATE);

wire [NUM_LDQ-1:0] rdata_mux;
wire       empty;
fifo_fwft #(.DATA_WIDTH(NUM_LDQ), .DEPTH_WIDTH(8))
u_fifo(
  .clk (clk),
  .rst (~rstn),
  
  .din        (ldq_grant),
  .wr_en      (m0_read & ~m0_waitrequest),
  .full       (),

  .dout       (rdata_mux),
  .rd_en      (m0_readdatavalid),
  .empty      (empty)
);

// read address channel
always @ (ld_trans_permitted) begin
  m0_read = ld_trans_permitted;
end
//always@(posedge clk)
//if(!rstn)
//  m0_read <= 1'b0;
//else if ( enable & ld_trans_permitted)
//  m0_read <= 1'b1;
//else if(~m0_waitrequest)
//  m0_read <= 1'b0;


always @ (st_trans_permitted) begin
  m0_write = st_trans_permitted;
end
//always@(posedge clk)
//if(!rstn)
//  m0_write<= 1'b0;
//else if (enable & st_trans_permitted)
//  m0_write<= 1'b1;
//else if(~m0_waitrequest)
//  m0_write<= 1'b0;

wire [ADDR_WIDTH-1:0] cur_stq_ddr_addr = stq_ddr_addr[ff2(stq_grant) * ADDR_WIDTH +:ADDR_WIDTH];
assign m0_writedata     = stq_ddr_data[ff2(stq_grant) * DDR_DATA_WIDTH +:DDR_DATA_WIDTH];

wire [ADDR_WIDTH-1:0] cur_ldq_ddr_addr = ldq_ddr_addr[ff1(ldq_grant) * ADDR_WIDTH +:ADDR_WIDTH];

always @ (*)
begin
  m0_address = 0;
  //if(st_trans_permitted) m0_address = cur_stq_ddr_addr + trans_cnt * 64;
  //else                   m0_address = cur_ldq_ddr_addr + trans_cnt * 64;
  if(st_trans_permitted) m0_address = cur_stq_ddr_addr;
  else                   m0_address = cur_ldq_ddr_addr;

end
//always @ (posedge clk)
//if(disabled)
//  m0_address <= 'h0;
//else if(st_trans_permitted)
//  m0_address <= cur_stq_ddr_addr;
//else
//  m0_address <= cur_ldq_ddr_addr;

//always @ (posedge clk)
//if(disabled)
//  m0_writedata <= 'h0;
//else
//  m0_writedata <= stq_ddr_data;

// read data
assign ldq_ddr_data_valid = {NUM_LDQ{~disabled & m0_readdatavalid}} & rdata_mux;
assign ldq_ddr_data       = {NUM_LDQ{m0_readdata}};
//assign ldq_ddr_addr_ready = {NUM_LDQ{~disabled & m0_read & ~m0_waitrequest & (trans_cnt == CNT_MAX)} } & ldq_grant;
//assign stq_ddr_ready      = {NUM_STQ{~disabled & m0_write& ~m0_waitrequest & (trans_cnt == CNT_MAX)}} & stq_grant;
assign ldq_ddr_addr_ready = {NUM_LDQ{~disabled & m0_read & ~m0_waitrequest}} & ldq_grant;
assign stq_ddr_ready      = {NUM_STQ{~disabled & m0_write& ~m0_waitrequest}} & stq_grant;

always @ (posedge clk)
if(!rstn)
  trans_cnt <= 'h0;
else if((m0_read | m0_write) & ~m0_waitrequest) begin
  if(trans_cnt == CNT_MAX) trans_cnt <= 'h0;
  else trans_cnt <= trans_cnt + 1;
end

always @ (posedge clk)     // should no transction on the same cycle oon disabled signal
 if(!rstn)
    disabled <= 1'b1;
 else if(disabled & enable) // should make sure bus is idle,and then enable
  disabled <= 1'b0;
 else if(~disabled & ~enable & (empty & ~m0_read & ~m0_write))
  disabled <= 1'b1;        
`endif

endmodule
