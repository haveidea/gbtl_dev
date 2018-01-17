
//
//---------------------------------------------------------------------------
// Top module for Asynchronous FIFOs (10spmv_fpga) between slow and fast merge blocks   
// 
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module afifo_top_slow_fast 
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,
    DATA_WIDTH_ADD_STG = `DATA_WIDTH_ADD_STG,
    SLOW_BLK_BUFF_SIZE = `SLOW_BLK_BUFF_SIZE,
    BITS_SLOW_BLK_BUFF_ADDR = `BITS_SLOW_BLK_BUFF_ADDR,
    NUM_SLOW_BLK = `NUM_SEG_PER_STG,
    VI = `VALID_INDEX_DATA_BUFF_SO_SEG)
   (//input
    input clk, clk_slow, rst_b, unit_en, mode, next_stg_rd_en,
    input [NUM_SLOW_BLK - 1 : 0] blk_en_adv_slow,
    input [NUM_SLOW_BLK - 1 : 0] [DATA_WIDTH - 1 : 0] data_out_blk_slow,
    input [NUM_SLOW_BLK - 1 : 0] en_intake_fifo_slow_blk,
  
    //output
    output logic [NUM_SLOW_BLK - 1 : 0] fifo_empty,
    output logic [NUM_SLOW_BLK - 1 : 0] out_fifo_wr_ready_slow, out_fifo_wr_ready_slow_adv,
    output [NUM_SLOW_BLK - 1 : 0] [DATA_WIDTH_ADD_STG - 1 : 0] data_out_fifo);

   logic [NUM_SLOW_BLK - 1 : 0] fifo_wr_en, fifo_rd_en, fifo_full;//,fifo_empty;
   logic [NUM_SLOW_BLK - 1 : 0] [DATA_WIDTH_ADD_STG - 1 : 0] din;
      
   integer i0;
   always_comb begin
      for (i0 = 0; i0 < NUM_SLOW_BLK; i0 = i0 + 1) begin
	 din[i0] = data_out_blk_slow[i0][DATA_WIDTH - 1 : DATA_WIDTH - DATA_WIDTH_ADD_STG];
	 //fifo_wr_en[i0] = (mode == `MODE_WORK && unit_en) ? blk_en_adv_slow[i0] && data_out_blk_slow[i0][VI] : 1'b0;
	 fifo_wr_en[i0] = (mode == `MODE_WORK && unit_en) ? blk_en_adv_slow[i0] && din[i0][0] : 1'b0;
       	 fifo_rd_en[i0] = (next_stg_rd_en)? en_intake_fifo_slow_blk[i0] & ~fifo_empty[i0] : 1'b0;
	 out_fifo_wr_ready_slow_adv[i0] = (mode == `MODE_WORK) ? !fifo_full[i0] : 1'b0;  
      end   
   end
   ////assign blk_en_fast = (mode == `MODE_WORK) ? unit_en & ~(|in_fifo_rd_halt_fast) & wr_ready_blk_fast_out_q : 1'b0;// only integrate unit_en and mode with any kind of blk_en, not with fifo_ready/empty, intake_enable or rd_halt kind of signals
   register #(.WIDTH(NUM_SLOW_BLK)) reg_out_fifo(.q(out_fifo_wr_ready_slow), .d(out_fifo_wr_ready_slow_adv), .clk(clk_slow), .enable(1'b1), .rst_b(rst_b));


//-------------------------------------------------------------   
//just for plot
wire [NUM_SLOW_BLK - 1 : 0][`BITS_ROW_IDX - 1 : 0] afifo_out_row_idx;
wire [NUM_SLOW_BLK - 1 : 0][`DATA_PRECISION - 1 : 0] afifo_out_value;
wire [NUM_SLOW_BLK - 1 : 0]afifo_out_valid;   

wire [NUM_SLOW_BLK - 1 : 0][`BITS_ROW_IDX - 1 : 0] afifo_in_row_idx;
wire [NUM_SLOW_BLK - 1 : 0][`DATA_PRECISION - 1 : 0] afifo_in_value;
wire [NUM_SLOW_BLK - 1 : 0]afifo_in_valid;      
//-------------------------------------------------------------   

   
   //FIFO Asynchronous
   //=========================================================================================
   genvar j0;
   generate
      for (j0 = 0; j0 < NUM_SLOW_BLK; j0 = j0 + 1) begin : afifo
 
	 afifo #(.DSIZE(DATA_WIDTH_ADD_STG), .ASIZE(BITS_SLOW_BLK_BUFF_ADDR)) fifo_slow_fast
	  (//input
	   .wdata(din[j0]), .winc(fifo_wr_en[j0]), .wclk(clk_slow), .wrst_n(rst_b),
	   .rinc(fifo_rd_en[j0]), .rclk(clk), .rrst_n(rst_b),
	   //output
           .rdata(data_out_fifo[j0]),
           .wfull(fifo_full[j0]),
           .rempty(fifo_empty[j0]));

//--------------------------------------------------------------
//just for plot	 
assign afifo_out_row_idx[j0] = data_out_fifo[j0][DATA_WIDTH_ADD_STG - 1 : DATA_WIDTH_ADD_STG - `BITS_ROW_IDX];
assign afifo_out_value[j0] = data_out_fifo[j0][DATA_WIDTH_ADD_STG - `BITS_ROW_IDX -1 : DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - `DATA_PRECISION];
assign afifo_out_valid[j0] = data_out_fifo[j0][0];     	 
assign afifo_in_row_idx[j0] = din[j0][DATA_WIDTH_ADD_STG - 1 : DATA_WIDTH_ADD_STG - `BITS_ROW_IDX];
assign afifo_in_value[j0] = din[j0][DATA_WIDTH_ADD_STG - `BITS_ROW_IDX -1 : DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - `DATA_PRECISION];
assign afifo_in_valid[j0] = din[j0][0];  
//--------------------------------------------------------------	 
      end
   endgenerate
  //=========================================================================================


   
endmodule
