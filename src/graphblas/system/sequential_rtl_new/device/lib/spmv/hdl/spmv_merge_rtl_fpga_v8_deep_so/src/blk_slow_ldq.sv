//
//---------------------------------------------------------------------------
// load queue connection for single slow block   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module blk_slow_ldq
  #(//parameter
    DRAM_OFFSET = 0,
    LOAD_ADDR_WIDTH = `LOAD_ADDR_WIDTH,
    //LOAD_ADDR_ALIGNMENT_WIDTH = `LOAD_ADDR_ALIGNMENT_WIDTH,
    STORE_ADDR_WIDTH = `STORE_ADDR_WIDTH,
    //STORE_ADDR_ALIGNMENT_WIDTH = `STORE_ADDR_ALIGNMENT_WIDTH,
    LDQ_DATA_WIDTH = `LDQ_DATA_WIDTH,
    STQ_DATA_WIDTH = `STQ_DATA_WIDTH,
    NUM_INPUTs_PER_SEG_ARR = `NUM_INPUTs_PER_SEG_ARR,
    BITS_INPUT_ADDR_SLOW_BLK = `BITS_INPUT_ADDR_SLOW_BLK,
    DATA_WIDTH_INPUT = `DATA_WIDTH_INPUT)
   (//LDQ signals
    input clk, rst_b, unit_en, mode, ldq_addr_ready, ldq_data_valid,
    input [LDQ_DATA_WIDTH - 1: 0] ldq_data,
    input rcv_ld_req,
    input [BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] bin_to_fill_addr_blk_slow,
    output wr_en_blk_slow_input,
    output [BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] wr_addr_blk_slow_input,
    output logic [`BLK_SLOW_PARR_WR_NUM - 1 : 0][DATA_WIDTH_INPUT - 1 : 0] data_in_blk_slow, 
    output [`DRAM_ADDR_WIDTH - 1 : 0] ldq_addr,
    output ldq_addr_valid, ldq_data_ready,
    output cur_req_list_ended);
   
   //DRAM load request address map info and history tracing
   logic [`LDQ_DEPTH - 1 : 0] [BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] ldq_req_history;
   logic [NUM_INPUTs_PER_SEG_ARR - 1 : 0] [LOAD_ADDR_WIDTH - 1 : 0] list_latest_addr_dram, list_end_addr_dram;//end addr is the last element address
   logic [NUM_INPUTs_PER_SEG_ARR - 1 : 0] list_ld_req_pending, list_ended;
   logic cur_req_list_ld_req_pending;
   logic [LOAD_ADDR_WIDTH - 1 : 0] cur_req_latest_addr_dram, cur_req_end_addr_dram;
   assign cur_req_latest_addr_dram = list_latest_addr_dram[bin_to_fill_addr_blk_slow];
   assign cur_req_end_addr_dram = list_end_addr_dram[bin_to_fill_addr_blk_slow];
   assign cur_req_list_ld_req_pending = list_ld_req_pending[bin_to_fill_addr_blk_slow];  
   assign cur_req_list_ended = list_ended[bin_to_fill_addr_blk_slow];


   logic [`BITS_LDQ_DEPTH - 1 : 0] ldq_ctr_rd, ldq_ctr_wr;
   logic [`BITS_LDQ_DEPTH : 0] ldq_track_ctr;
   //this is kind of a wr signal for the counters
   assign ldq_addr_valid = (mode == `MODE_WORK && unit_en) && ldq_addr_ready && ~cur_req_list_ld_req_pending && rcv_ld_req && ~cur_req_list_ended && (ldq_track_ctr < `LDQ_DEPTH); //this means we are going to issue this ld request
   assign ldq_addr = {cur_req_latest_addr_dram, `LOAD_ADDR_ALIGNMENT_WIDTH'b0};

   //this is kind of a rd signal for the counters
   assign ldq_data_ready = (mode == `MODE_WORK && unit_en) && ldq_data_valid && (ldq_track_ctr > 0);
   assign wr_en_blk_slow_input = ldq_data_ready;
   assign wr_addr_blk_slow_input = ldq_req_history[ldq_ctr_rd];

   //Bookkeeping the DRAM address for input lists
   //---------------------------------------------------------------------
   integer i0;
   always_ff @ (posedge clk) begin
      if(~rst_b) begin
	 for (i0 = 0; i0 < `NUM_INPUTs_PER_SEG_ARR; i0 = i0 + 1) begin
	    list_latest_addr_dram[i0] <= i0 * 2 + DRAM_OFFSET;// 2 64B DRAM data blocks per list
	    list_end_addr_dram[i0] <= (i0+1) * 2 + DRAM_OFFSET - 1;
	    //list_ld_req_pending[i0] <= '0;
	    list_ended[i0] <= '0;
	 end
      end
      else if (unit_en & mode == `MODE_WORK && ldq_addr_valid) begin
	 list_latest_addr_dram[bin_to_fill_addr_blk_slow] <= cur_req_latest_addr_dram + 1;
	 //list_ld_req_pending[bin_to_fill_addr_blk_slow] <= 1'b1;
	 list_ended[bin_to_fill_addr_blk_slow] <= cur_req_latest_addr_dram == cur_req_end_addr_dram ? 1'b1 : 1'b0;
      end
   end // always_ff @ (posedge clk)
   
   integer i3;
   always_ff @ (posedge clk) begin
      if(~rst_b) begin
	 for (i3 = 0; i3 < `NUM_INPUTs_PER_SEG_ARR; i3 = i3 + 1) begin
	    list_ld_req_pending[i3] <= '0;
	 end
      end
      else if (unit_en & mode == `MODE_WORK && ldq_addr_valid && !ldq_data_ready) begin
	 list_ld_req_pending[bin_to_fill_addr_blk_slow] <= 1'b1;
      end
      else if (unit_en & mode == `MODE_WORK && !ldq_addr_valid && ldq_data_ready) begin
	 list_ld_req_pending[wr_addr_blk_slow_input] <= 1'b0;
      end
      else if (unit_en & mode == `MODE_WORK && ldq_addr_valid && ldq_data_ready) begin
	 list_ld_req_pending[bin_to_fill_addr_blk_slow] <= 1'b1;
	 list_ld_req_pending[wr_addr_blk_slow_input] <= 1'b0;
      end
   end // always_ff @ (posedge clk)
   
   //---------------------------------------------------------------------

   //Bookkeeping the load request history for input lists
   //---------------------------------------------------------------------   
   integer i1;   
   always_ff @ (posedge clk) begin
      if(~rst_b) begin
	 for (i1 = 0; i1 < `NUM_INPUTs_PER_SEG_ARR; i1 = i1 + 1) begin
	    ldq_req_history[i1] <= '0;
	 end
	 ldq_ctr_rd <= '0;
	 ldq_ctr_wr <= '0;
	 ldq_track_ctr <= '0;
      end
      else begin
	 ldq_ctr_rd <= ldq_data_ready ? ldq_ctr_rd + 1 : ldq_ctr_rd;
	 ldq_ctr_wr <= ldq_addr_valid ? ldq_ctr_wr + 1 : ldq_ctr_wr;
	 ldq_track_ctr <= (ldq_data_ready && ~ldq_addr_valid) ? ldq_track_ctr - 1 : (~ldq_data_ready && ldq_addr_valid) ? ldq_track_ctr + 1 : ldq_track_ctr;
	 ldq_req_history[ldq_ctr_wr] <= ldq_addr_valid ? bin_to_fill_addr_blk_slow : ldq_req_history[ldq_ctr_wr];
      end
   end
   //---------------------------------------------------------------------

   //---------------------------------------------------------------------
   /*
   integer i2;
   always_comb begin
      for (i2 = 0; i2 < `BLK_SLOW_PARR_WR_NUM; i2 = i2 + 1) begin
	 //data_in_blk_slow[i2] = ldq_data[LDQ_DATA_WIDTH - DATA_WIDTH_INPUT*i2 - 1 : LDQ_DATA_WIDTH - DATA_WIDTH_INPUT*(i2 + 1)]; //notice that the MSB is the data for lower address (smaller index)
	 data_in_blk_slow[i2] = ldq_data[LDQ_DATA_WIDTH - DATA_WIDTH_INPUT - 1 : LDQ_DATA_WIDTH - DATA_WIDTH_INPUT*(2)]; //notice that the MSB is the data for lower address (smaller index)
      end     
   end
    */
   genvar j0;
   generate
      for (j0 = 0; j0 < `BLK_SLOW_PARR_WR_NUM; j0 = j0 + 1) begin 
	 assign data_in_blk_slow[j0] = ldq_data[LDQ_DATA_WIDTH - DATA_WIDTH_INPUT*j0 - 1 : LDQ_DATA_WIDTH - DATA_WIDTH_INPUT*(j0 + 1)]; //notice that the MSB is the data for lower address (smaller index)
      end
   endgenerate
   //---------------------------------------------------------------------

   


endmodule   
