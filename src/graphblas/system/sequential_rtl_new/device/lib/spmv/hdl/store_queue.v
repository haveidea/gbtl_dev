module store_queue
#(parameter STQ_DATA_WIDTH   = 256,
            DDR_DATA_WIDTH      = 512,
            ADDR_WIDTH      = 32,
            QPTR_WIDTH      = 5,
            IDS_NUM         = 1,
            BASE_ADDR_WIDTH = 20) // default to store 2KB data(512b*2^5)
(
// spmv interface
input                                 sys_clk,
input                                 sys_rstn,
input                                 req_valid,
output                                req_ready,
input [7:0]                           req_id,
input [STQ_DATA_WIDTH-1:0]            data,
input [BASE_ADDR_WIDTH*IDS_NUM -1:0]  addr_base,
input                                 spmv_done,

// ddr interface
input                                 ddr_clk,
input                                 ddr_rstn,
output reg                            ddr_valid,
input                                 ddr_ready,
output reg [ADDR_WIDTH-1:0]           ddr_addr,
output     [DDR_DATA_WIDTH-1:0]       ddr_data
);

localparam Q_DEPTH=(1<<QPTR_WIDTH);
wire                  sync_buf_e;
wire                  sync_buf_f;
wire [DDR_DATA_WIDTH-1:0] sync_buf_dout;
wire                  sync_buf_rd;
wire                  sync_buf_wr;

reg [STQ_DATA_WIDTH-1:0] data_lo;
reg [STQ_DATA_WIDTH-1:0] data_hi;
reg                       odd_even;

wire [DDR_DATA_WIDTH-1:0]     data_all;

always @ (posedge sys_clk)
if(!sys_rstn)
  odd_even<= 'h0;
else if(req_valid &req_ready)
  odd_even<= ~odd_even;


always @ (posedge sys_clk)
if(!sys_rstn)
  data_lo <= 'h0;
else if(req_valid &req_ready& ~odd_even)
  data_lo <= data;

always @ (posedge sys_clk)
if(!sys_rstn)
  data_hi <= 'h0;
else if(req_valid &req_ready& odd_even)
  data_hi <= data;

assign data_all = {data, data_lo};
//assign data_all = {data_hi, data_lo};


wire async_buf_e;
wire async_buf_f;

reg [QPTR_WIDTH:0] sync_buf_fullness;
reg [QPTR_WIDTH-1:0] sync_buf_rd_cnt_lsb;

wire req_channel_rd;
wire req_channel_full;

reg  [26:0]              ddr_trans_cnt; 
// sync fifo logic
reg sync_buf_rd_en;
assign sync_buf_wr = req_valid & req_ready & odd_even;
fifo_fwft #(.DATA_WIDTH(DDR_DATA_WIDTH), .DEPTH_WIDTH(8))
u_sync_fastforward_fifo(
  .clk      (sys_clk),
  .rst      (~sys_rstn),
  .din      (data_all),
  .wr_en    (sync_buf_wr),
  .full     (sync_buf_f),
  .dout     (sync_buf_dout),
  .rd_en    (sync_buf_rd),
  .empty    (sync_buf_e)
);

always @ (posedge sys_clk)
if(~sys_rstn)
  sync_buf_fullness <= 'h0;
else begin
  casez({sync_buf_wr, sync_buf_rd})
  2'b01:   sync_buf_fullness <= sync_buf_fullness - 1;
  2'b10:   sync_buf_fullness <= sync_buf_fullness + 1;
  default: sync_buf_fullness <= sync_buf_fullness;
  endcase
end

always @ (posedge sys_clk)
if(~sys_rstn)
  sync_buf_rd_cnt_lsb<= 'h0;
else if (sync_buf_rd)
  sync_buf_rd_cnt_lsb<= sync_buf_rd_cnt_lsb + 1;

assign sync_buf_rd =  ~sync_buf_e;
assign req_ready   = ~sync_buf_f;


// async buf logic
dual_clock_fifo #(.DATA_WIDTH(DDR_DATA_WIDTH),.ADDR_WIDTH(2)) u_async_fifo  // just for clock convertion
(
  .wr_rst_i     (~sys_rstn),
  .wr_clk_i     (sys_clk),
  .wr_en_i      (sync_buf_rd),
  .wr_data_i    (sync_buf_dout),

  .rd_rst_i     (~ddr_rstn),
  .rd_clk_i     (ddr_clk),
  .rd_en_i      (req_channel_rd),
  .rd_data_o    (ddr_data),

  .empty_o      (req_channel_empty),
  .full_o       (req_channel_full)
);

always @ (posedge ddr_clk)
if(!ddr_rstn)
  ddr_trans_cnt <= 'h0;
else if(ddr_valid & ddr_ready)
  ddr_trans_cnt <= ddr_trans_cnt + 1;

always @ (posedge ddr_clk)
if(~ddr_rstn)
  ddr_valid <= 1'b0;
else if(~req_channel_empty)
  ddr_valid <= 1'b1;
else if(ddr_valid & ddr_ready & req_channel_empty)
  ddr_valid <= 1'b0;

//always @ (posedge ddr_clk)
//if(!ddr_rstn)
//  ddr_addr <= 'h0;
//else 
//  ddr_addr <= {addr_base, 12'h0} + (ddr_trans_cnt << 5);
  
always @ (*)
  ddr_addr = {addr_base, 12'h0} + (ddr_trans_cnt << 5);


//assign req_channel_rd = ~req_channel_empty & ~(ddr_valid & ~ddr_ready);
assign req_channel_rd = ~req_channel_empty & (ddr_valid & ddr_ready);


endmodule
