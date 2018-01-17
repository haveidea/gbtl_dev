module spmv_func
#(parameter DDR_DATA_WIDTH = 512, LDQ_DATA_WIDTH=512, STQ_DATA_WIDTH=256, ADDR_WIDTH=32, NUM_LDQ =4, NUM_STQ =1, TOTAL_LDQ_IDS=512, TOTAL_STQ_IDS=1, BASE_ADDR_WIDTH=20)
(
  input                                           clock,
  input                                           resetn,
  input                                           spmv_start,
  input                                           spmv_clear,
  output                                          spmv_done,

  input [BASE_ADDR_WIDTH * TOTAL_LDQ_IDS -1 :0]   rchannel_addr_base,
  input [BASE_ADDR_WIDTH * TOTAL_STQ_IDS -1 :0]   wchannel_addr_base,

  output [ADDR_WIDTH-1:0]                         m_rchannel0_address      ,
  output                                          m_rchannel0_read         ,
  input                                           m_rchannel0_waitrequest  ,
  input  [DDR_DATA_WIDTH-1:0]                     m_rchannel0_readdata     ,
  output                                          m_rchannel0_write        ,
  output [DDR_DATA_WIDTH-1:0]                     m_rchannel0_writedata    ,
  input                                           m_rchannel0_readdatavalid,
  output [DDR_DATA_WIDTH/8 -1:0]                  m_rchannel0_be           ,
  output [6:0]                                    m_rchannel0_burstcount   ,

  output [ADDR_WIDTH-1:0]                         m_rchannel1_address      ,
  output                                          m_rchannel1_read         ,
  input                                           m_rchannel1_waitrequest  ,
  input  [DDR_DATA_WIDTH-1:0]                     m_rchannel1_readdata     ,
  output                                          m_rchannel1_write        ,
  output [DDR_DATA_WIDTH-1:0]                     m_rchannel1_writedata    ,
  input                                           m_rchannel1_readdatavalid,
  output [DDR_DATA_WIDTH/8 -1:0]                  m_rchannel1_be           ,
  output [6:0]                                    m_rchannel1_burstcount   ,

  output [ADDR_WIDTH-1:0]                         m_rchannel2_address      ,
  output                                          m_rchannel2_read         ,
  input                                           m_rchannel2_waitrequest  ,
  input  [DDR_DATA_WIDTH-1:0]                     m_rchannel2_readdata     ,
  output                                          m_rchannel2_write        ,
  output [DDR_DATA_WIDTH-1:0]                     m_rchannel2_writedata    ,
  input                                           m_rchannel2_readdatavalid,
  output [DDR_DATA_WIDTH/8 -1:0]                  m_rchannel2_be           ,
  output [6:0]                                    m_rchannel2_burstcount   ,

  output [ADDR_WIDTH-1:0]                         m_rchannel3_address      ,
  output                                          m_rchannel3_read         ,
  input                                           m_rchannel3_waitrequest  ,
  input  [DDR_DATA_WIDTH-1:0]                     m_rchannel3_readdata     ,
  output                                          m_rchannel3_write        ,
  output [DDR_DATA_WIDTH-1:0]                     m_rchannel3_writedata    ,
  input                                           m_rchannel3_readdatavalid,
  output [DDR_DATA_WIDTH/8 -1:0]                  m_rchannel3_be           ,
  output [6:0]                                    m_rchannel3_burstcount   ,

  output [ADDR_WIDTH-1:0]                         m_wchannel0_address      ,
  output                                          m_wchannel0_read         ,
  input                                           m_wchannel0_waitrequest  ,
  input  [DDR_DATA_WIDTH-1:0]                     m_wchannel0_readdata     ,
  output                                          m_wchannel0_write        ,
  output [DDR_DATA_WIDTH-1:0]                     m_wchannel0_writedata    ,
  input                                           m_wchannel0_readdatavalid,
  output [DDR_DATA_WIDTH/8 -1:0]                  m_wchannel0_be           ,
  output [6:0]                                    m_wchannel0_burstcount   
);
localparam LDQ_ID_WIDTH=$clog2(TOTAL_LDQ_IDS);
wire [NUM_LDQ-1:0]                  ldq_valid;
wire [NUM_LDQ*LDQ_ID_WIDTH-1+8:0]   ldq_id;

wire [NUM_LDQ-1:0]                  ldq_data_valid;
wire [NUM_LDQ*LDQ_DATA_WIDTH-1:0]   ldq_data;
wire [NUM_LDQ-1:0]                  ldq_data_ready;

wire [NUM_STQ-1:0]                  stq_valid;
wire [NUM_STQ*STQ_DATA_WIDTH-1:0]   stq_data;
wire [NUM_STQ-1:0]                  stq_ready;

wire [NUM_LDQ-1:0]                  ldq_ddr_addr_valid;
wire [NUM_LDQ-1:0]                  ldq_ddr_addr_ready;
wire [NUM_LDQ-1:0]                  ldq_ready;
wire [NUM_LDQ*ADDR_WIDTH-1:0]       ldq_ddr_addr;
wire [NUM_LDQ-1:0]                  ldq_ddr_data_valid;
wire [NUM_LDQ*DDR_DATA_WIDTH-1:0]   ldq_ddr_data;

wire [NUM_STQ-1:0]                  stq_ddr_valid;
wire [NUM_STQ-1:0]                  stq_ddr_ready;
wire [NUM_STQ*ADDR_WIDTH-1:0]       stq_ddr_addr;
wire [NUM_STQ*DDR_DATA_WIDTH-1:0]   stq_ddr_data;
reg [1:0] cnt;

always @ (posedge clock)
if(!resetn)
  cnt <= 'h0;
else 
  cnt <= cnt + 1;
wire clk_slow;

assign clk_slow = cnt[0]; // 1/2 clock frequency

assign m_rchannel0_address = ldq_ddr_addr[ADDR_WIDTH  -1:0];
assign m_rchannel1_address = ldq_ddr_addr[ADDR_WIDTH*2-1:ADDR_WIDTH];
assign m_rchannel2_address = ldq_ddr_addr[ADDR_WIDTH*3-1:ADDR_WIDTH*2];
assign m_rchannel3_address = ldq_ddr_addr[ADDR_WIDTH*4-1:ADDR_WIDTH*3];

assign m_rchannel0_read    = ldq_ddr_addr_valid[0];
assign m_rchannel1_read    = ldq_ddr_addr_valid[1];
assign m_rchannel2_read    = ldq_ddr_addr_valid[2];
assign m_rchannel3_read    = ldq_ddr_addr_valid[3];

assign ldq_ddr_addr_ready[0] = m_rchannel0_waitrequest ;
assign ldq_ddr_addr_ready[1] = m_rchannel1_waitrequest ;
assign ldq_ddr_addr_ready[2] = m_rchannel2_waitrequest ;
assign ldq_ddr_addr_ready[3] = m_rchannel3_waitrequest ;

assign ldq_ddr_data[DDR_DATA_WIDTH  -1: 0             ]   = m_rchannel0_readdata;
assign ldq_ddr_data[DDR_DATA_WIDTH*2-1: DDR_DATA_WIDTH]   = m_rchannel1_readdata;
assign ldq_ddr_data[DDR_DATA_WIDTH*3-1: DDR_DATA_WIDTH*2] = m_rchannel2_readdata;
assign ldq_ddr_data[DDR_DATA_WIDTH*4-1: DDR_DATA_WIDTH*3] = m_rchannel3_readdata;

assign ldq_ddr_data_valid[0] = m_rchannel0_readdatavalid;
assign ldq_ddr_data_valid[1] = m_rchannel1_readdatavalid;
assign ldq_ddr_data_valid[2] = m_rchannel2_readdatavalid;
assign ldq_ddr_data_valid[3] = m_rchannel3_readdatavalid;

assign m_rchannel0_read      = ldq_ddr_addr_valid[0];
assign m_rchannel1_read      = ldq_ddr_addr_valid[1];
assign m_rchannel2_read      = ldq_ddr_addr_valid[2];
assign m_rchannel3_read      = ldq_ddr_addr_valid[3];

assign m_rchannel0_write    = 1'b0;
assign m_rchannel1_write    = 1'b0;
assign m_rchannel2_write    = 1'b0;
assign m_rchannel3_write    = 1'b0;

assign m_rchannel0_writedata = 'h0;
assign m_rchannel1_writedata = 'h0;
assign m_rchannel2_writedata = 'h0;
assign m_rchannel3_writedata = 'h0;

assign m_rchannel0_burstcount = 'h1;
assign m_rchannel1_burstcount = 'h1;
assign m_rchannel2_burstcount = 'h1;
assign m_rchannel3_burstcount = 'h1;

assign m_rchannel0_be = {(DDR_DATA_WIDTH/8){1'b1}};
assign m_rchannel1_be = {(DDR_DATA_WIDTH/8){1'b1}};
assign m_rchannel2_be = {(DDR_DATA_WIDTH/8){1'b1}};
assign m_rchannel3_be = {(DDR_DATA_WIDTH/8){1'b1}};

assign m_wchannel0_address    = stq_ddr_addr[ADDR_WIDTH  -1:0];
assign m_wchannel0_read       = 1'b0;
assign stq_ddr_ready          = m_wchannel0_waitrequest ;
assign m_wchannel0_write      = stq_ddr_valid;
assign m_wchannel0_writedata  = stq_ddr_data;
assign m_wchannel0_burstcount = 'h1;
assign m_wchannel0_be         = {(DDR_DATA_WIDTH/8){1'b1}};

reg spmv_enable;
wire spmv_init;

reg spmv_start_d;

always  @ (posedge clock) 
if(!resetn)
  spmv_start_d <= 1'b0;
else
  spmv_start_d <= spmv_start;

wire spmv_start_p = spmv_start & ~spmv_start_d;
reg [7:0] ctrl_cnt;
reg [2:0] cur_state, nxt_state;

always @ (posedge clock)
if(!resetn)
  cur_state <= 'h0;
else
  cur_state <= nxt_state;


parameter SPMV_IDLE         = 3'b000;
parameter SPMV_MODE0_ENABLE = 3'b001;
parameter SPMV_MODE0_DISABLE= 3'b010;
parameter SPMV_MODE1_SET    = 3'b011;
parameter SPMV_MODE1_ENABLE = 3'b100;
parameter SPMV_DONE   = 3'b101;

always @ (posedge clock)
if(!resetn)
  ctrl_cnt <= 'h0;
else if(cur_state != nxt_state)
  ctrl_cnt <= 'h0;
else if(ctrl_cnt != 'd127)
  ctrl_cnt <= ctrl_cnt + 1'b1;

always @ (*)begin
  nxt_state = cur_state;
  case(cur_state) 
    SPMV_IDLE          : if(spmv_start_p)       nxt_state = SPMV_MODE0_ENABLE;
    SPMV_MODE0_ENABLE  : if(spmv_init)          nxt_state = SPMV_MODE0_DISABLE;
    SPMV_MODE0_DISABLE : if(ctrl_cnt == 'd127)  nxt_state = SPMV_MODE1_SET;
    SPMV_MODE1_SET     : if(ctrl_cnt == 'd127)  nxt_state = SPMV_MODE1_ENABLE;
    SPMV_MODE1_ENABLE  : if(spmv_done)          nxt_state = SPMV_DONE;
    SPMV_DONE          : if(spmv_clear)         nxt_state = SPMV_IDLE;
  endcase
end

reg spmv_mode;

always @ (posedge clock)
if(!resetn)
  spmv_mode <= 1'b0;
else if(spmv_clear )
  spmv_mode <= 1'b0;
else if((cur_state == SPMV_MODE1_SET) && ctrl_cnt == 'd127)
  spmv_mode <= 1'b1;
  

always @ (posedge clock)
if(!resetn)
  spmv_enable<= 1'b0;
else if(((cur_state == SPMV_MODE0_ENABLE) && (ctrl_cnt == 'd127)) || ((cur_state == SPMV_MODE1_ENABLE) && (ctrl_cnt == 'd127)))
  spmv_enable<= 1'b1;
else if(spmv_clear || ((cur_state == SPMV_MODE0_DISABLE) && (ctrl_cnt == 'd127)))
  spmv_enable<= 1'b0;

/////////////////
merge_core dut_spmv
(
  .rst_b          (resetn  | ~spmv_clear),
  .clk_slow       (clk_slow             ),
  .clk_fast       (clock                ),
  .clk_ldq        (clock                ),

  .mode           (spmv_mode          ),
  .enable         (spmv_enable        ),
  .init           (spmv_init          ),
  .done           (spmv_done          ),
  .ldq_addr_valid (ldq_valid          ),
  .ldq_addr_ready (ldq_ready          ),
  .ldq_addr       (ldq_id             ),

  .ldq_data       (ldq_data           ),
  .ldq_data_valid (ldq_data_valid     ),
  .ldq_data_ready (ldq_data_ready     ),

  .stq_valid      (stq_valid          ),
  .stq_ready      (stq_ready          ),
  .stq_data       (stq_data           )
);

async_lsq #(.DDR_DATA_WIDTH(DDR_DATA_WIDTH), .STQ_DATA_WIDTH(STQ_DATA_WIDTH), .LDQ_DATA_WIDTH(LDQ_DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),.QPTR_WIDTH(10), .NUM_LDQ(NUM_LDQ), .NUM_STQ(NUM_STQ))
spmv_async_lsq (
  .ldq_clk            (clock),
  .stq_clk            (clock),
  .rstn               (resetn | ~spmv_clear),
  .ddr_clk            (clock),
  .ddr_rstn           (resetn | ~spmv_clear),

  .ldq_valid          (ldq_valid),
  .ldq_ready          (ldq_ready),
  .ldq_id             (ldq_id),
  .stq_id             ('h0),
  .ldq_data_valid     (ldq_data_valid),
  .ldq_data_ready     (ldq_data_ready),
  .ldq_data           (ldq_data      ),
  
  .stq_valid          (stq_valid     ),
  .stq_ready          (stq_ready     ),
  .stq_data           (stq_data      ),

  .rchannel_addr_base (rchannel_addr_base),
  .wchannel_addr_base (wchannel_addr_base),

  //ddr part
  .ldq_ddr_addr_valid (ldq_ddr_addr_valid),
  .ldq_ddr_addr_ready (ldq_ddr_addr_ready),
  .ldq_ddr_addr       (ldq_ddr_addr      ),
  .ldq_ddr_data_valid (ldq_ddr_data_valid),
  .ldq_ddr_data       (ldq_ddr_data      ),

  .stq_ddr_valid      (stq_ddr_valid     ),
  .stq_ddr_ready      (stq_ddr_ready     ),
  .stq_ddr_addr       (stq_ddr_addr      ),
  .stq_ddr_data       (stq_ddr_data      )
);


endmodule
