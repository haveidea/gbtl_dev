module load_queue
#(parameter DDR_DATA_WIDTH = 512, 
            LDQ_DATA_WIDTH = 512, 
            ADDR_WIDTH = 32,
            QPTR_WIDTH = 4,
            IDS_NUM    = 128,
            BASE_ADDR_WIDTH = 20)
(
// spmv interface
input                               sys_clk,
input                               sys_rstn,

input                               req_valid,
input [$clog2(IDS_NUM)-1+2:0]       req_id,
output                              req_ready,
input [BASE_ADDR_WIDTH*IDS_NUM-1:0] addr_base,

output reg                          data_valid,
input                               data_ready,
output [LDQ_DATA_WIDTH-1:0]         data,

//ddr interface
input                               ddr_clk,
input                               ddr_rstn,

output reg                          ddr_addr_valid,
input                               ddr_addr_ready,
output [ADDR_WIDTH-1:0]             ddr_addr,
input                               ddr_data_valid,
input [DDR_DATA_WIDTH-1:0]          ddr_data
);

localparam ID_WIDTH =$clog2(IDS_NUM);
localparam Q_DEPTH  =(1<<QPTR_WIDTH);

reg                     req_channel_empty;
wire                    req_channel_rd;
wire                    req_channel_wr;

wire                    data_channel_empty;
wire                    data_channel_rd;
wire                    data_channel_full;
wire                    data_channel_wr;
reg  [27*IDS_NUM-1:0]  ddr_trans_cnt; 
reg  [ID_WIDTH-1:0]     cur_id;
wire [BASE_ADDR_WIDTH-1:0] cur_addr_base;
wire                       req_channel_full;
wire [8:0]                 sync_fifo_emptyness;
reg  [31:0]                pre_occupy;
wire req_channel_rd_tmp;
wire [6:0]  cur_id_tmp;
wire        req_channel_empty_tmp;
assign cur_addr_base =  addr_base[cur_id * BASE_ADDR_WIDTH  +: BASE_ADDR_WIDTH];

always @ (posedge ddr_clk)
if(!ddr_rstn)
  ddr_trans_cnt <= 'h0;
else if(ddr_addr_valid & ddr_addr_ready)
  ddr_trans_cnt[cur_id*27 +:27] <= ddr_trans_cnt[cur_id*27 +:27]+1;

// count to 0x1f, which is 32 transactions -> 32 * 64B = 2KB
assign req_channel_rd = ~req_channel_empty & 
                        (((ddr_trans_cnt[cur_id * 27 +:5]== 5'h0) & ~ddr_addr_valid) | ((ddr_trans_cnt[cur_id*27+:5] == 5'h1f) & (ddr_addr_valid & ddr_addr_ready)))
                        & (sync_fifo_emptyness > (pre_occupy+32));

assign req_ready      = ~req_channel_full;
assign req_channel_wr =  req_valid & req_ready;

always @ (posedge ddr_clk)
if(~ddr_rstn) begin
  pre_occupy <= 'h0;
end
else begin
  case ({req_channel_rd, ddr_data_valid})
    2'b00: pre_occupy <= pre_occupy;
    2'b01: pre_occupy <= pre_occupy -1;
    2'b10: pre_occupy <= pre_occupy+32;
    2'b11: pre_occupy <= pre_occupy+31;
  endcase
end

always @ (posedge ddr_clk)
if(!ddr_rstn)
  ddr_addr_valid <= 1'b0;
//else if(~req_channel_empty )
else if(req_channel_rd_tmp)
  ddr_addr_valid <= 1'b1;
else if (ddr_addr_valid & ddr_addr_ready & (ddr_trans_cnt[cur_id*27+:5] == 5'h1f))
  ddr_addr_valid <= 1'b0;


dual_clock_fifo #(.DATA_WIDTH(ID_WIDTH),.ADDR_WIDTH(4)) load_req_channel
(
  .wr_rst_i     (~sys_rstn),
  .wr_clk_i     (sys_clk),
  .wr_en_i      (req_channel_wr),
  .wr_data_i    (req_id),            // data is not important here. only internal counters in the fifo matters.

  .rd_rst_i     (~ddr_rstn),
  .rd_clk_i     (ddr_clk),
  .rd_en_i      (req_channel_rd_tmp),
  .rd_data_o    (cur_id_tmp),

  .empty_o      (req_channel_empty_tmp),

  .full_o       (req_channel_full)
);

// fifo fast forward logic
reg req_channel_rd_tmp_d;
always @ (posedge ddr_clk)
if(!ddr_rstn)
  req_channel_rd_tmp_d <= 1'b0;
else
  req_channel_rd_tmp_d <= req_channel_rd_tmp;

assign req_channel_rd_tmp =  req_channel_rd;
//assign req_channel_rd_tmp = (req_channel_empty & ~req_channel_empty_tmp) | req_channel_rd;

//always @ (posedge ddr_clk)
//if(!ddr_rstn)
//  cur_id<= 'h0;
//else if(req_channel_rd_tmp_d)
//  cur_id<= cur_id_tmp;

always@ (posedge ddr_clk)
if(!ddr_rstn)
  cur_id <= 'h0;
else if(req_channel_rd_tmp)
  cur_id <= cur_id_tmp;

always  @(*)
  req_channel_empty = req_channel_empty_tmp;

assign  ddr_addr  = {cur_addr_base, 12'h0} + (ddr_trans_cnt[cur_id*27 +:27] << 6);

// data channel
reg data_valid_tmp;
assign data_channel_rd = ~data_channel_empty & data_ready;

always @ (*)
    data_valid <= data_channel_rd;

assign data_channel_wr = ddr_data_valid;
wire data_sync_fifo_empty;
wire [DDR_DATA_WIDTH-1:0]      ddr_data_fifo;

dual_clock_fifo #(.DATA_WIDTH(DDR_DATA_WIDTH),.ADDR_WIDTH(4)) load_data_channel_async // just for clock synchronize spmv always ready
(
  .wr_rst_i     (~ddr_rstn          ),
  .wr_clk_i     (ddr_clk            ),
  .wr_en_i      (~data_sync_fifo_empty & ~data_channel_full),
  .wr_data_i    (ddr_data_fifo      ),

  .rd_rst_i     (~sys_rstn          ),
  .rd_clk_i     (sys_clk            ),
  .rd_en_i      (data_channel_rd    ),
  .rd_data_o    (data               ),

  .empty_o      (data_channel_empty ),
  .full_o       (data_channel_full  )
);


fifo_fwft #(.DATA_WIDTH(DDR_DATA_WIDTH), .DEPTH_WIDTH(8))
load_data_channel_sync
(
    .clk  (ddr_clk),
    .rst  (~ddr_rstn),
    .din  (ddr_data),
    .wr_en(data_channel_wr),
    .full (),
    .dout (ddr_data_fifo),
    .rd_en(~data_sync_fifo_empty & ~data_channel_full),
    .empty(data_sync_fifo_empty),
    .fullness(),
    .emptyness(sync_fifo_emptyness)
);

endmodule
