//
//---------------------------------------------------------------------------
// Merge connects the clock divider with multiple merge units.   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module merge_core
  #(//parameter
    NUM_SLOW_BLK = `NUM_SEG_PER_STG,
    LDQ_DATA_WIDTH = `LDQ_DATA_WIDTH,
    STQ_DATA_WIDTH = `STQ_DATA_WIDTH,
    NUM_UNITs = `NUM_UNITs,
    BITS_UNIT_SELECTION = `BITS_UNIT_SELECTION,
    BITS_TOTAl_INPUTS = `BITS_TOTAl_INPUTS)
   (//input
    input clk_ldq, clk_slow, clk_fast, rst_b, enable, mode, 
    input [NUM_SLOW_BLK - 1 : 0] ldq_addr_ready, ldq_data_valid,
    input [NUM_SLOW_BLK - 1 : 0] [LDQ_DATA_WIDTH - 1 : 0] ldq_data,
    input stq_ready,
    
    //output
    output init, done,
    //output [NUM_SLOW_BLK - 1 : 0] [`DRAM_ADDR_WIDTH - 1 : 0] ldq_addr,
    output [NUM_SLOW_BLK - 1 : 0] [BITS_TOTAl_INPUTS - 1 : 0] ldq_addr,
    output [NUM_SLOW_BLK - 1 : 0] ldq_addr_valid, ldq_data_ready,
    output logic stq_valid,
    output [STQ_DATA_WIDTH - 1 : 0] stq_data);
      
//Connecting the radix-sort units
//=========================================================================================
//unit input signals
wire [NUM_UNITs - 1 : 0] stq_buff_full;   
wire [NUM_SLOW_BLK - 1 : 0] wr_en_unit_input;   
wire [NUM_SLOW_BLK - 1 : 0][`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] wr_addr_unit_input;   
wire [NUM_SLOW_BLK - 1 : 0][`BLK_SLOW_PARR_WR_NUM - 1 : 0][`DATA_WIDTH_INPUT - 1 : 0] data_in_unit;
wire [NUM_SLOW_BLK - 1 : 0][`BITS_ROW_IDX - 1 : 0] maxidx_input;   
logic [NUM_UNITs - 1 : 0][NUM_SLOW_BLK - 1 : 0] fill_req_accepted_blk_slow;
logic [NUM_UNITs - 1 : 0][NUM_SLOW_BLK - 1 : 0][`BITS_INPUT_BIN_ADDR - 1 : 0] set_wr_ctr_input, set_rd_ctr_input;
logic [NUM_UNITs - 1 : 0][NUM_SLOW_BLK - 1 : 0][`BITS_INPUT_BIN_ADDR : 0]  set_track_ctr_input;
   
//unit output signals
wire [NUM_UNITs - 1 : 0] ini_unit_done;
wire [NUM_UNITs - 1 : 0][NUM_SLOW_BLK - 1 : 0] send_fill_req_blk_slow;  
wire [NUM_UNITs - 1 : 0][NUM_SLOW_BLK - 1 : 0][`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] bin_to_fill_addr_blk_slow;  
wire [NUM_UNITs - 1 : 0][NUM_SLOW_BLK - 1 : 0][`NUM_INPUTs_PER_SEG_ARR - 1 : 0][`NUM_UNITs - 1 : 0] bin_empty_flags;
   
wire [NUM_UNITs - 1 : 0] unit_out_valid;
wire [NUM_UNITs - 1 : 0][`BITS_ROW_IDX - 1 : 0] unit_out_row_idx;
wire [NUM_UNITs - 1 : 0][`DATA_PRECISION - 1 : 0] unit_out_value;

   genvar j1;
   generate
      for (j1 = 0; j1 < NUM_UNITs; j1 = j1 + 1) begin : unit_parr
	 merge_unit unit
	   (//input
	    .clk(clk_fast), .clk_slow, .rst_b, .unit_en(enable), .mode, .buff_stq_full(stq_buff_full[j1]), 
            .wr_en_unit_input,
	    .wr_addr_unit_input, .data_in_unit,  .maxidx_input,
	    .fill_req_accepted_blk_slow(fill_req_accepted_blk_slow[j1]),
	    .set_wr_ctr_input(set_wr_ctr_input[j1]), .set_rd_ctr_input(set_rd_ctr_input[j1]),
            .set_track_ctr_input(set_track_ctr_input[j1]),
	    
	    //output
	    .ini_unit_done(ini_unit_done[j1]),
	    .send_fill_req_blk_slow(send_fill_req_blk_slow[j1]),
	    .bin_to_fill_addr_blk_slow(bin_to_fill_addr_blk_slow[j1]),
	    .bin_empty_flags(bin_empty_flags[j1]),
	    .unit_out_valid(unit_out_valid[j1]), .unit_out_row_idx(unit_out_row_idx[j1]),
            .unit_out_value(unit_out_value[j1]));
      end
   endgenerate
   
assign init = &ini_unit_done;

logic [NUM_SLOW_BLK - 1 : 0][NUM_UNITs - 1 : 0][`NUM_INPUTs_PER_SEG_ARR - 1 : 0][`NUM_UNITs - 1 : 0] bin_empty_flags_temp;
logic [NUM_SLOW_BLK - 1 : 0][NUM_UNITs - 1 : 0] send_fill_req_blk_slow_temp;  
logic [NUM_SLOW_BLK - 1 : 0][NUM_UNITs - 1 : 0][`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] bin_to_fill_addr_blk_slow_temp;  
logic [NUM_SLOW_BLK - 1 : 0][NUM_UNITs - 1 : 0] fill_req_accepted_blk_slow_temp;

logic [NUM_SLOW_BLK - 1 : 0][NUM_UNITs - 1 : 0][`BITS_INPUT_BIN_ADDR - 1 : 0] set_wr_ctr_input_temp, set_rd_ctr_input_temp;
logic [NUM_SLOW_BLK - 1 : 0][NUM_UNITs - 1 : 0][`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_input_temp;
   
   always_comb begin      
      for (integer i0 = 0; i0 < NUM_SLOW_BLK; i0 = i0 + 1) begin
	 for (integer i1 = 0; i1 < NUM_UNITs; i1 = i1 + 1) begin

	    bin_empty_flags_temp[i0][i1] = bin_empty_flags[i1][i0];
	    send_fill_req_blk_slow_temp[i0][i1] = send_fill_req_blk_slow[i1][i0];
	    bin_to_fill_addr_blk_slow_temp[i0][i1] = bin_to_fill_addr_blk_slow[i1][i0];

	    fill_req_accepted_blk_slow[i1][i0] = fill_req_accepted_blk_slow_temp[i0][i1];  
	    set_wr_ctr_input[i1][i0] = set_wr_ctr_input_temp[i0][i1];
	    set_rd_ctr_input[i1][i0] = set_rd_ctr_input_temp[i0][i1];
	    set_track_ctr_input[i1][i0] = set_track_ctr_input_temp[i0][i1];
	 end
      end
   end   
//=========================================================================================
   
//Connecting the unit level load store interface
//=========================================================================================
wire [NUM_SLOW_BLK - 1 : 0] fill_req_accept_ready;
wire [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] bin_to_fill_addr;  
wire [NUM_SLOW_BLK - 1 : 0] send_fill_req;

wire [NUM_SLOW_BLK - 1 : 0] ldq_data_valid_pb;
wire [NUM_SLOW_BLK - 1 : 0][LDQ_DATA_WIDTH - 1 : 0] ldq_data_pb;
wire [NUM_SLOW_BLK - 1 : 0][`BITS_ROW_IDX - 1 : 0] maxidx_pb;
   
wire [NUM_SLOW_BLK - 1 : 0][NUM_UNITs - 1 : 0][`BITS_INPUT_BIN_ADDR - 1 : 0] set_wr_ctr_pb, set_rd_ctr_pb;
wire [NUM_SLOW_BLK - 1 : 0][NUM_UNITs - 1 : 0][`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_pb;
     
   genvar j0;
   generate
      for (j0 = 0; j0 < NUM_SLOW_BLK; j0 = j0 + 1) begin : ld_data

	 radixsort_pb_interface pb_interface 
	   (//input
	    .clk_slow, .rst_b, .unit_en(enable), .mode, .fill_req_accept_ready(fill_req_accept_ready[j0]),
            //.bin_empty_flags(bin_empty_flags[NUM_UNITs - 1 : 0][j0]),
            .bin_empty_flags(bin_empty_flags_temp[j0]),
            //.send_fill_req_blk_slow(send_fill_req_blk_slow[NUM_UNITs - 1 : 0][j0]),
	    .send_fill_req_blk_slow(send_fill_req_blk_slow_temp[j0]),
            //.bin_to_fill_addr_blk_slow(bin_to_fill_addr_blk_slow[NUM_UNITs - 1 : 0][j0]),
	    .bin_to_fill_addr_blk_slow(bin_to_fill_addr_blk_slow_temp[j0]),
	    	    
	    //output
            //.fill_req_accepted_blk_slow(fill_req_accepted_blk_slow[NUM_UNITs - 1 : 0][j0]),
	    .fill_req_accepted_blk_slow(fill_req_accepted_blk_slow_temp[j0]), 
            .bin_to_fill_addr(bin_to_fill_addr[j0]),   
            .send_fill_req(send_fill_req[j0]));
	 
	 page_buffer #(.SERIAL_SLOW_BLK(j0)) page_buffer
	   (//input
	    .clk_ldq, .clk_slow, .rst_b, .unit_en(enable), .mode,
	    .ldq_addr_ready(ldq_addr_ready[j0]),
            ///.ldq_data_valid(ldq_data_valid[j0]),
    	    ///.ldq_data(ldq_data[j0]),
	    .ldq_data_valid(ldq_data_valid_pb[j0]),
    	    .ldq_data(ldq_data_pb[j0]),
            .rcv_fill_req(send_fill_req[j0]), 
            .bin_to_fill_addr_blk_slow(bin_to_fill_addr[j0]),
	    .maxidx_pb(maxidx_pb[j0]),
	    .set_rd_ctr_pb(set_rd_ctr_pb[j0]), .set_wr_ctr_pb(set_wr_ctr_pb[j0]),
	    .set_track_ctr_pb(set_track_ctr_pb[j0]),
	    
	    //output
            .wr_en_blk_slow_input(wr_en_unit_input[j0]),
	    .fill_req_accept_ready(fill_req_accept_ready[j0]),
            .wr_addr_blk_slow_input(wr_addr_unit_input[j0]),
	    .data_in_blk_slow(data_in_unit[j0]),
	    .maxidx_input(maxidx_input[j0]), 
	    .set_rd_ctr_input(set_rd_ctr_input_temp[j0]),
	    .set_wr_ctr_input(set_wr_ctr_input_temp[j0]),
	    .set_track_ctr_input(set_track_ctr_input_temp[j0]),
            .ldq_addr(ldq_addr[j0]),
            .ldq_addr_valid(ldq_addr_valid[j0]), .ldq_data_ready(ldq_data_ready[j0]));

	 radixsort_din radixsort_din
	   (//input
	    .clk(clk_ldq), .rst_b, .unit_en(enable), .mode, .ldq_data_valid(ldq_data_valid[j0]),
	    .ldq_data(ldq_data[j0]), 
	    //output
	    .ldq_data_valid_pb(ldq_data_valid_pb[j0]),
	    .ldq_data_pb(ldq_data_pb[j0]),
	    .maxidx_pb(maxidx_pb[j0]),
	    .set_rd_ctr_pb(set_rd_ctr_pb[j0]), .set_wr_ctr_pb(set_wr_ctr_pb[j0]),
	    .set_track_ctr_pb(set_track_ctr_pb[j0])); 
      end
   endgenerate
//=========================================================================================
	
   stq_interface stq_interface
     (//input
      .clk(clk_fast), .rst_b, .unit_en(enable), .mode, 
      .stq_ready, .unit_out_valid, .unit_out_row_idx, .unit_out_value,
      
      //output
      .stq_buff_full, .stq_valid, .done, .stq_data);
   
endmodule // merge_core


   
   
