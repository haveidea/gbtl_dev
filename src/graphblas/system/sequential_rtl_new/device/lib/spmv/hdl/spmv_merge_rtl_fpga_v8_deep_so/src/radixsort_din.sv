//
//---------------------------------------------------------------------------
// This modules dcontrols the data coming from DRAM and does the radix sort + calculates the proper value for the bin counters
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module radixsort_din
  #(//parameter
    NUM_UNITs = `NUM_UNITs,
    STREAM_WIDTH = `STREAM_WIDTH,
    LOG_STREAM_WIDTH = `LOG_STREAM_WIDTH,
    DATA_WIDTH = `BITS_ROW_IDX + `DATA_PRECISION,
    NUM_BIOTONIC_STGS_TOT = `NUM_BIOTONIC_STGS_TOT,
    NUM_BLOCKS = LOG_STREAM_WIDTH)
   (input clk, rst_b, unit_en, mode, ldq_data_valid,
    input [`LDQ_DATA_WIDTH - 1: 0] ldq_data,
    //input [STREAM_WIDTH - 1 : 0][DATA_WIDTH - 1 : 0] 		   din, 

    output ldq_data_valid_pb,
    output [`LDQ_DATA_WIDTH - 1: 0] ldq_data_pb,
    output [`BITS_ROW_IDX - 1 : 0] maxidx_pb,
    output [NUM_UNITs - 1 : 0][`BITS_INPUT_BIN_ADDR - 1 : 0] set_rd_ctr_pb, set_wr_ctr_pb,
    output [NUM_UNITs - 1 : 0][`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_pb);

   wire global_en;
   assign global_en = (mode == `MODE_WORK) && unit_en;
   
   wire [STREAM_WIDTH - 1 : 0][DATA_WIDTH - 1 : 0] din, dout;
   wire [`BITS_ROW_IDX - 1 : 0] maxidx;
     
   assign maxidx = din[STREAM_WIDTH - 1][DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   
   genvar j1;
   generate
      for (j1 = 0; j1 < STREAM_WIDTH; j1 = j1 + 1) begin 
	 assign din[j1] = ldq_data[`LDQ_DATA_WIDTH - DATA_WIDTH*j1 - 1 : `LDQ_DATA_WIDTH - DATA_WIDTH*(j1 + 1)]; //notice that the MSB is the data for lower address (smaller index)
	 assign ldq_data_pb[`LDQ_DATA_WIDTH - DATA_WIDTH*j1 - 1 : `LDQ_DATA_WIDTH - DATA_WIDTH*(j1 + 1)] = dout[j1];
      end
   endgenerate
   
   bitonic_sort_network bitonic_sort_network
     (//input
      .clk, .rst_b, .enable(global_en), .din, 
      //output
      .dout);
   
   input_fifo_ctr_calc input_fifo_ctr_calc
     (//input
      .clk, .rst_b, .enable(global_en), .din,
      //output
      .set_rd_ctr_pb, .set_wr_ctr_pb, .set_track_ctr_pb);

   delay #(.WIDTH(1), .DEPTH(NUM_BIOTONIC_STGS_TOT)) delay_ldq_data_valid(.q(ldq_data_valid_pb), .d(ldq_data_valid), .clk(clk), .enable(global_en), .rst_b(rst_b));
   delay #(.WIDTH(`BITS_ROW_IDX), .DEPTH(NUM_BIOTONIC_STGS_TOT)) delay_maxidx(.q(maxidx_pb), .d(maxidx), .clk(clk), .enable(global_en), .rst_b(rst_b));


//------------------------------------
   //just for debug
logic [STREAM_WIDTH - 1 : 0][`BITS_ROW_IDX - 1 : 0] din_rowidx, dout_rowidx;
   
always_comb begin
   for (integer i0 = 0; i0 < STREAM_WIDTH; i0 = i0 + 1) begin 

      din_rowidx[i0] = din[i0][DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
      dout_rowidx[i0] = dout[i0][DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
      
   end
end
//-----------------------------------  

endmodule // radixsort_din

