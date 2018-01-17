module fifo_fwft
  #(parameter DATA_WIDTH = 0,
    parameter DEPTH_WIDTH = 0)
   (
    input                   clk,
    input                   rst,
    input [DATA_WIDTH-1:0]  din,
    input                   wr_en,
    output                  full,
    output [DATA_WIDTH-1:0] dout,
    input                   rd_en,
    output                  empty,
    output reg [DEPTH_WIDTH:0] fullness,
    output reg [DEPTH_WIDTH:0] emptyness
);

always @ (posedge clk)
if(rst) begin
  fullness <= 'h0;
end
else begin
  case ({wr_en,rd_en})
    2'b00, 2'b11: fullness<= fullness;
    2'b10:        fullness <= fullness+1;
    2'b01:        fullness <= fullness-1;
  endcase
end

always @ (posedge clk)
if(rst) begin
  emptyness<= {1'b1, {DEPTH_WIDTH{1'b0}}};
end
else begin
  case ({wr_en,rd_en})
    2'b00, 2'b11: emptyness<= emptyness;
    2'b10:        emptyness<= emptyness-1;
    2'b01:        emptyness<= emptyness+1;
  endcase
end


   wire [DATA_WIDTH-1:0]    fifo_dout;
   wire                     fifo_empty;
   wire                     fifo_rd_en;

   // orig_fifo is just a normal (non-FWFT) synchronous or asynchronous FIFO
   fifo
     #(.DEPTH_WIDTH (DEPTH_WIDTH),
       .DATA_WIDTH  (DATA_WIDTH))
   fifo0
     (
      .clk       (clk),
      .rst       (rst),
      .rd_en_i   (fifo_rd_en),
      .rd_data_o (fifo_dout),
      .empty_o   (fifo_empty),
      .wr_en_i   (wr_en),
      .wr_data_i (din),
      .full_o    (full));

   fifo_fwft_adapter
     #(.DATA_WIDTH (DATA_WIDTH))
   fwft_adapter
     (.clk          (clk),
      .rst          (rst),
      .rd_en_i      (rd_en),
      .fifo_empty_i (fifo_empty),
      .fifo_rd_en_o (fifo_rd_en),
      .fifo_dout_i  (fifo_dout),
      .dout_o       (dout),
      .empty_o      (empty));

endmodule
