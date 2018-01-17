//
//---------------------------------------------------------------------------
// FIFOs with control signals   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module fifo_slow_blk_w_ctrl_signals 
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,
    DIV_RATIO_HALF = `DIV_RATIO_HALF,
    SLOW_BLK_BUFF_SIZE = `SLOW_BLK_BUFF_SIZE,
    BITS_SLOW_BLK_BUFF_ADDR = `BITS_SLOW_BLK_BUFF_ADDR,
    NUM_SLOW_BLK = `NUM_SEG_PER_STG)
   (//input
    input clk, clk_slow, rst_b, unit_en, mode, out_q_wr_ready_fast,
    input [NUM_SLOW_BLK - 1 : 0] blk_en_slow, 
    input [NUM_SLOW_BLK - 1 : 0] [DATA_WIDTH - 1 : 0]  data_out_blk_slow,
    input [NUM_SLOW_BLK - 1 : 0] 		       en_intake_fifo_slow_blk,
    //output
    output logic blk_en_fast,
    output logic [NUM_SLOW_BLK - 1 : 0] out_fifo_wr_ready_slow, out_fifo_wr_ready_slow_adv,
    output [NUM_SLOW_BLK - 1 : 0] [DATA_WIDTH - 1 : 0] data_out_fifo);

   //FIFO signals
   logic [NUM_SLOW_BLK - 1 : 0] fifo_wr_en, fifo_rd_en, in_fifo_rd_halt_fast, fifo_not_full, fifo_empty;
   
   //FIFO counters
   logic [NUM_SLOW_BLK - 1 : 0] [BITS_SLOW_BLK_BUFF_ADDR - 1 : 0] rd_addr_ctr;
   logic [NUM_SLOW_BLK - 1 : 0] [BITS_SLOW_BLK_BUFF_ADDR - 1 : 0] wr_addr_ctr;   
   logic [NUM_SLOW_BLK - 1 : 0] [BITS_SLOW_BLK_BUFF_ADDR : 0] fifo_track_ctr;
   
   logic clk_slow_posedge_coming;
   ////assign clk_slow_posedge_coming = ((clk_div_ctr == DIV_RATIO_HALF - 1) & ~clk_slow);  
   //------------------------------------------------------------------
   logic [`BITS_DIV_RATIO_HALF : 0] posedge_coming_ctr; //the counter has to reach exactly to `BITS_DIV_RATIO_HALF. So one bit more
   always_ff @ (negedge clk) begin
      if(~rst_b) begin
	 posedge_coming_ctr <= '0;
      end
      else if(clk_slow == 0) begin
	 posedge_coming_ctr <= posedge_coming_ctr + 1;	 
      end
      else begin
	 posedge_coming_ctr <= '0;
      end
   end
   assign clk_slow_posedge_coming = posedge_coming_ctr == DIV_RATIO_HALF ? 1'b1 : 1'b0;
   //------------------------------------------------------------------
       
   logic mode_reg;
   register #(.WIDTH(1)) reg_mode(.q(mode_reg), .d(mode), .clk(clk), .enable(1'b1), .rst_b(rst_b));
   
   //Control signals for the modules and the counters
   //=========================================================================================
   integer i1;
   always_comb begin
      for (i1 = 0; i1 < NUM_SLOW_BLK; i1 = i1 + 1) begin
	 
	 fifo_empty[i1] = fifo_track_ctr[i1] == 0 ? 1'b1 : 1'b0;	 
	 fifo_wr_en[i1] = (mode_reg == `MODE_WORK) ? blk_en_slow[i1] : 1'b0;
	 in_fifo_rd_halt_fast[i1] = (mode_reg == `MODE_WORK) ? en_intake_fifo_slow_blk[i1] & fifo_empty[i1] : 1'b0;
	 fifo_rd_en[i1] = (blk_en_fast)? en_intake_fifo_slow_blk[i1] & ~fifo_empty[i1] : 1'b0;
      end   
   end
   assign blk_en_fast = (mode == `MODE_WORK) ? unit_en & ~(|in_fifo_rd_halt_fast) & out_q_wr_ready_fast : 1'b0;// only integrate unit_en and mode with any kind of blk_en, not with fifo_ready/empty, intake_enable or rd_halt kind of signals
   //=========================================================================================

   //FIFO not full signal - works at negedge of the fast clock
   //=========================================================================================
   integer i4;   
   always_ff @ (negedge clk) begin
      if(~rst_b) begin
	 for (i4 = 0; i4 < NUM_SLOW_BLK; i4 = i4 + 1) begin
	    fifo_not_full[i4] <= 1;
	 end
      end
      else if (clk_slow_posedge_coming) begin
	 for (i4 = 0; i4 < NUM_SLOW_BLK; i4 = i4 + 1) begin
	    fifo_not_full[i4] <= (fifo_track_ctr[i4] == (SLOW_BLK_BUFF_SIZE - 1) && fifo_wr_en[i4]) || (fifo_track_ctr[i4] == (SLOW_BLK_BUFF_SIZE))? 1'b0 : 1'b1;
	 end
      end
   end
   //=========================================================================================

   //Incrementing and decrementing the fifo counters
   //=========================================================================================
   integer i2;   
   always_ff @ (posedge clk) begin
      if(~rst_b) begin
	 for (i2 = 0; i2 < NUM_SLOW_BLK; i2 = i2 + 1) begin
	    fifo_track_ctr[i2] <= '0;
	    rd_addr_ctr[i2] <= '0;
	 end
      end
      else begin
	 for (i2 = 0; i2 < NUM_SLOW_BLK; i2 = i2 + 1) begin
	    fifo_track_ctr[i2] <= (fifo_rd_en[i2] && fifo_wr_en[i2] && clk_slow_posedge_coming) ? 
		   fifo_track_ctr[i2] : (fifo_wr_en[i2] && clk_slow_posedge_coming ? 
	           fifo_track_ctr[i2] + 1 : (fifo_rd_en[i2] ? fifo_track_ctr[i2] - 1 : fifo_track_ctr[i2]));
	    rd_addr_ctr[i2] <= fifo_rd_en[i2] ? rd_addr_ctr[i2] + 1 : rd_addr_ctr[i2];
	 end
      end   
   end 

   integer i3;   
   always_ff @ (posedge clk_slow) begin
      if(~rst_b) begin
	 for (i3 = 0; i3 < NUM_SLOW_BLK; i3 = i3 + 1) begin
	    wr_addr_ctr[i3] <= '0;
	    ////blk_en_slow[i3] <= '0;
	    out_fifo_wr_ready_slow[i3] <= '0;
	 end
      end
      else begin
	 for (i3 = 0; i3 < NUM_SLOW_BLK; i3 = i3 + 1) begin
	    wr_addr_ctr[i3] <= fifo_wr_en[i3] ? wr_addr_ctr[i3] + 1 : wr_addr_ctr[i3];
	    ////blk_en_slow[i3] <= (mode == `MODE_WORK) ? unit_en & fifo_not_full[i3] : unit_en;
	    out_fifo_wr_ready_slow[i3] <= fifo_not_full[i3];
	 end
      end   
   end // always_ff @

   integer i5;   
   always_comb begin
      for (i5 = 0; i5 < NUM_SLOW_BLK; i5 = i5 + 1) begin
	 ////blk_en_slow_adv[i5] = (mode == `MODE_WORK) ? unit_en & fifo_not_full[i5] : unit_en;
	 out_fifo_wr_ready_slow_adv[i5] = fifo_not_full[i5];
      end
   end 
   //=========================================================================================

   
   //FIFO storage
   //=========================================================================================
   genvar j1;
   generate
      for (j1 = 0; j1 < NUM_SLOW_BLK; j1 = j1 + 1) begin : fifo_parallel_storage

	 fifo_slow_blk fifo_parr 
	   (//input
	    .rst_b, .clk_slow, .wr_en(fifo_wr_en[j1]),  
	    .rd_addr(rd_addr_ctr[j1]), .wr_addr(wr_addr_ctr[j1]),						   
	    .data_in(data_out_blk_slow[j1]),
	    //output					  
	    .data_out(data_out_fifo[j1]));
      end
   endgenerate
  //=========================================================================================
   
   endmodule
   
