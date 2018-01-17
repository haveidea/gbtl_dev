//
//---------------------------------------------------------------------------
// provides rd, wr and q empty signals - use this only when q depth > 1 
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module ptr_packed_qs_g1 #( //g1 means depth of q is greater than 1
   parameter
     BITS_ADDR_PACK = 4,	       
     NUM_OF_Q = 2**BITS_ADDR_PACK,
     BITS_ADDR_EACH_Q = 2,
     DEPTH_EACH_Q = 2**BITS_ADDR_EACH_Q,
     WORD_WIDTH_PACK = BITS_ADDR_EACH_Q + BITS_ADDR_EACH_Q + BITS_ADDR_EACH_Q + 1,
     FPGA = 0) //0 means M20K or MLAB based storage, 1 means register based storage (use for asic)
  (input rst_b, clk, rd_ptr_inc, wr_ptr_inc,
   input [BITS_ADDR_PACK - 1 : 0] rd_addr, wr_addr, 
 
   output q_empty, q_full,
   output [BITS_ADDR_EACH_Q - 1 : 0] rd_ptr_val, wr_ptr_val);

/*
logic [NUM_OF_Q - 1 : 0][WORD_WIDTH_PACK - 1 : 0] pack_storage;    
wire [WORD_WIDTH_PACK - 1 : 0] cur_word_rd = pack_storage[rd_addr];
wire [WORD_WIDTH_PACK - 1 : 0] cur_word_wr = pack_storage[wr_addr];
 
wire [BITS_ADDR_EACH_Q - 1 : 0] cur_rd_ptr = cur_word_rd[WORD_WIDTH_PACK - 1 : WORD_WIDTH_PACK - BITS_ADDR_EACH_Q];
wire [BITS_ADDR_EACH_Q - 1 : 0] cur_wr_ptr = cur_word_wr[WORD_WIDTH_PACK - 1 - BITS_ADDR_EACH_Q: WORD_WIDTH_PACK - 2*BITS_ADDR_EACH_Q];
wire [BITS_ADDR_EACH_Q : 0] cur_track_ptr_rd = cur_word_rd[BITS_ADDR_EACH_Q : 0];
wire [BITS_ADDR_EACH_Q : 0] cur_track_ptr_wr = cur_word_wr[BITS_ADDR_EACH_Q : 0];
*/

logic [NUM_OF_Q - 1 : 0][BITS_ADDR_EACH_Q - 1 : 0] rd_ptr, wr_ptr;   
logic [NUM_OF_Q - 1 : 0][BITS_ADDR_EACH_Q : 0] track_ptr;  
 
wire [BITS_ADDR_EACH_Q - 1 : 0] cur_rd_ptr = rd_ptr[rd_addr];
wire [BITS_ADDR_EACH_Q - 1 : 0] cur_wr_ptr = wr_ptr[wr_addr];
   
wire [BITS_ADDR_EACH_Q : 0] cur_track_ptr_rd = track_ptr[rd_addr];
wire [BITS_ADDR_EACH_Q : 0] cur_track_ptr_wr = track_ptr[wr_addr];
   
assign q_empty = (cur_track_ptr_rd == '0) ? 1'b1 : 1'b0;
assign q_full = (cur_track_ptr_wr[BITS_ADDR_EACH_Q] == 1'b1) ? 1'b1 : 1'b0; 

wire rd_inc_val = q_empty ? 1'b0 : 1'b1;
wire wr_inc_val = q_full ? 1'b0 : 1'b1;   
   
wire [BITS_ADDR_EACH_Q - 1 : 0] cur_rd_ptr_plus1 = cur_rd_ptr + rd_inc_val;
wire [BITS_ADDR_EACH_Q - 1 : 0] cur_wr_ptr_plus1 = cur_wr_ptr + wr_inc_val;
    
wire [BITS_ADDR_EACH_Q : 0] cur_track_ptr_rd_minus1 = cur_track_ptr_rd - rd_inc_val;
wire [BITS_ADDR_EACH_Q : 0] cur_track_ptr_wr_plus1 = cur_track_ptr_wr + wr_inc_val;

//wire rd_en = rd_ptr_inc & !q_empty;
//wire wr_en = wr_ptr_inc & !q_full;  

wire rd_en = rd_ptr_inc;
wire wr_en = wr_ptr_inc;     
 
/*  
always_ff @ (posedge clk) begin 
   if(~rst_b) begin
      for (integer i = 0; i < NUM_OF_Q; i = i + 1) begin
	 //pack_storage[i] <= {{BITS_ADDR_EACH_Q{1'b0}}, {BITS_ADDR_EACH_Q{1'b1}}, {1'b1}, {BITS_ADDR_EACH_Q{1'b0}}};//so that initially it assumes SO data is readable
	 pack_storage[i] <= {{BITS_ADDR_EACH_Q{1'b0}}, {BITS_ADDR_EACH_Q{1'b0}}, {1'b0}, {BITS_ADDR_EACH_Q{1'b0}}};//the problem with previous ctr initialization is that the data initialization only happens for the last word in q 
      end
   end
   else if(rd_en && wr_en && (rd_addr == wr_addr)) begin
//      pack_storage[rd_addr] = {cur_rd_ptr_plus1, cur_wr_ptr_plus1, cur_track_ptr_rd};
      pack_storage[rd_addr] = {cur_rd_ptr, cur_wr_ptr, cur_track_ptr_rd};
   end
   else if(rd_en && ~wr_en ) begin
      pack_storage[rd_addr] = {cur_rd_ptr_plus1, cur_wr_ptr, cur_track_ptr_rd_minus1};
   end
   else if(~rd_en && wr_en) begin
      pack_storage[wr_addr] = {cur_rd_ptr, cur_wr_ptr_plus1, cur_track_ptr_wr_plus1};
   end
   else if(rd_en && wr_en && (rd_addr != wr_addr)) begin
      pack_storage[rd_addr] = {cur_rd_ptr_plus1, cur_wr_ptr, cur_track_ptr_rd_minus1};
      pack_storage[wr_addr] = {cur_rd_ptr, cur_wr_ptr_plus1, cur_track_ptr_wr_plus1};
   end
end 
*/

always_ff @ (posedge clk) begin 
   if(~rst_b) begin
      for (integer i = 0; i < NUM_OF_Q; i = i + 1) begin
	 rd_ptr[i] <= '0;
	 wr_ptr[i] <= '0;
	 track_ptr[i] <= '0;
      end
   end
   else if(rd_en && wr_en && (rd_addr == wr_addr)) begin
      rd_ptr[rd_addr] <= cur_rd_ptr;
      wr_ptr[wr_addr] <= cur_wr_ptr;
      track_ptr[rd_addr] <= cur_track_ptr_rd;
   end
   else if(rd_en && ~wr_en ) begin
      rd_ptr[rd_addr] <= cur_rd_ptr_plus1;
      track_ptr[rd_addr] <= cur_track_ptr_rd_minus1;
   end
   else if(~rd_en && wr_en) begin
      wr_ptr[wr_addr] <= cur_wr_ptr_plus1;
      track_ptr[wr_addr] <= cur_track_ptr_wr_plus1;
   end
   else if(rd_en && wr_en && (rd_addr != wr_addr)) begin
      rd_ptr[rd_addr] <= cur_rd_ptr_plus1;
      wr_ptr[wr_addr] <= cur_wr_ptr_plus1;
      track_ptr[rd_addr] <= cur_track_ptr_rd_minus1;
      track_ptr[wr_addr] <= cur_track_ptr_wr_plus1;
   end
end 
   
assign rd_ptr_val = cur_rd_ptr;  
assign wr_ptr_val = cur_wr_ptr;
   
endmodule


module ptr_packed_qs_e1 #( //e1 means depth of q is equal to 1
   parameter
     BITS_ADDR_PACK = 4,	       
     NUM_OF_Q = 2**BITS_ADDR_PACK,
     BITS_ADDR_EACH_Q = 0,
     DEPTH_EACH_Q = 2**BITS_ADDR_EACH_Q,
     FPGA = 0) //0 means M20K or MLAB based storage, 1 means register based storage (use for asic)
  (input rst_b, clk, rd_ptr_inc, wr_ptr_inc,
   input [BITS_ADDR_PACK - 1 : 0] rd_addr, wr_addr, 
 
   output q_empty, q_full);

logic [NUM_OF_Q - 1 : 0] pack_storage;

wire cur_track_ptr_rd = pack_storage[rd_addr];
wire cur_track_ptr_wr = pack_storage[wr_addr];

assign q_empty = (cur_track_ptr_rd == '0) ? 1'b1 : 1'b0;
assign q_full = (cur_track_ptr_wr == 1'b1) ? 1'b1 : 1'b0;  

//wire rd_en = rd_ptr_inc & !q_empty;
//wire wr_en = wr_ptr_inc & !q_full;

wire rd_en = rd_ptr_inc;
wire wr_en = wr_ptr_inc;   
   
always_ff @ (posedge clk) begin 
   if(~rst_b) begin
      for (integer i = 0; i < NUM_OF_Q; i = i + 1) begin
	 //pack_storage[i] <= 1'b1;//so that initially it assumes SO data is readable
	 pack_storage[i] <= 1'b0;
      end
   end
   else if(rd_en && wr_en && (rd_addr == wr_addr)) begin
      pack_storage[rd_addr] <= cur_track_ptr_rd;
   end
   else if(rd_en && ~wr_en ) begin
      pack_storage[rd_addr] <= 1'b0;
   end
   else if(~rd_en && wr_en) begin
      pack_storage[wr_addr] <= 1'b1;
   end
   else if(rd_en && wr_en && (rd_addr != wr_addr)) begin
      pack_storage[rd_addr] <= 1'b0;
      pack_storage[wr_addr] <= 1'b1;
   end
end 
   
endmodule
