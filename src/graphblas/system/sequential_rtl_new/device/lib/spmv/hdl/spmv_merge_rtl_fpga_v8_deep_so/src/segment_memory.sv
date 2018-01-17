//
//---------------------------------------------------------------------------
// SRAM memory block for segment for both buffer and stage output
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module segment_memory #(
   parameter
     NUM_BUFF_SO_WORDS_SEG = `NUM_BUFF_SO_WORDS_SEG,
     NUM_BRICK_SEG_VER = `NUM_BRICK_SEG_VER,
     BITS_ADDR_SEG = `BITS_ADDR_SEG,
     DEPTH_SO_Q = 1,
     BITS_SO_Q = 0,			     
     BITS_ADDR_SEG_SO = BITS_ADDR_SEG + BITS_SO_Q,	
     BITS_ADDR_LIM_BRICK = `BITS_ADDR_LIM_BRICK,		    
     NUM_BRICK_SEG_HOR = `NUM_BRICK_SEG_HOR,		   
     DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,
     NUM_DUMMY_BITS = `NUM_DUMMY_BITS_SEG_MEM)
  (//input
   input rst_b, clk, mandatory_bubble_so, mandatory_bubble_buff,
   input rd_en_so_adv, rd_en_buff_adv, wr_en_adv,
   input adv_rd_wr_addr_match_flag_so, rd_wr_addr_match_flag_so,
   input adv_rd_wr_addr_match_flag_buff, rd_wr_addr_match_flag_buff,
   input [BITS_ADDR_SEG - 1 : 0] adv_rd_addr_buff, adv_wr_addr_buff, 
   input [BITS_ADDR_SEG_SO - 1 : 0] adv_rd_addr_so, adv_wr_addr_so, 
   input [DATA_WIDTH - 1 : 0] data_in_buff, data_in_so,
   //output		 
   output [DATA_WIDTH - 1 : 0] dout_so_early,  
   output [DATA_WIDTH - 1 : 0] dout_buff, dout_so);          

genvar j0;   

/*   
//This part is only needed for ASIC. Comment out for FPGA    
//=======================================================================
//Wordlines + rd/wr enables 
wire [BITS_ADDR_LIM_BRICK - 1 : 0] adv_rd_addr_BRAM, adv_wr_addr_BRAM;
assign adv_rd_addr_BRAM = adv_rd_addr_seg[BITS_ADDR_LIM_BRICK - 1 : 0];
assign adv_wr_addr_BRAM = adv_wr_addr_seg[BITS_ADDR_LIM_BRICK - 1 : 0];
   
wire [NUM_BRICK_SEG_VER - 1 : 0] BRAM_RE_adv, BRAM_WE_adv;
wire [NUM_BRICK_SEG_VER * `LIM_BRICK_WORD_NUM - 1 : 0] rd_wl_adv, wr_wl_adv;  
wire [`LIM_BRICK_WORD_NUM - 1 : 0] single_brick_rd_wl_adv, single_brick_wr_wl_adv;
assign single_brick_rd_wl_adv = rd_en_adv && !adv_rd_wr_addr_match_flag ? 1 << adv_rd_addr_BRAM : '0;
assign single_brick_wr_wl_adv = wr_en_adv ? 1 << adv_wr_addr_BRAM : '0;
   
generate
   for (j0 = 0; j0 < NUM_BRICK_SEG_VER; j0 = j0 + 1) begin  
      assign rd_wl_adv[`LIM_BRICK_WORD_NUM * (j0 + 1) - 1 : `LIM_BRICK_WORD_NUM * j0] = BRAM_RE_adv[j0] ? single_brick_rd_wl_adv : '0;
      assign wr_wl_adv[`LIM_BRICK_WORD_NUM * (j0 + 1) - 1 : `LIM_BRICK_WORD_NUM * j0] = BRAM_WE_adv[j0] ? single_brick_wr_wl_adv : '0;      
   end
endgenerate

wire [NUM_BRICK_SEG_VER - 1 : 0] BRAM_RE;
wire [NUM_BRICK_SEG_VER * `LIM_BRICK_WORD_NUM - 1 : 0] rd_wl, wr_wl;  
     
register #(.WIDTH(NUM_BRICK_SEG_VER * `LIM_BRICK_WORD_NUM)) reg_rd_wl(.q(rd_wl), .d(rd_wl_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));
register #(.WIDTH(NUM_BRICK_SEG_VER * `LIM_BRICK_WORD_NUM)) reg_wr_wl(.q(wr_wl), .d(wr_wl_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));
register #(.WIDTH(NUM_BRICK_SEG_VER)) reg_BRAM_RE(.q(BRAM_RE), .d(BRAM_RE_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));
   
//------------------------------------------------------
generate 
   if (BITS_ADDR_SEG - BITS_ADDR_LIM_BRICK > 0) begin  
      wire [BITS_ADDR_SEG - BITS_ADDR_LIM_BRICK - 1 : 0] adv_BRAM_RE_addr, adv_BRAM_WE_addr;
      assign adv_BRAM_RE_addr = adv_rd_addr_seg[BITS_ADDR_SEG - 1 : BITS_ADDR_LIM_BRICK]; 
      assign adv_BRAM_WE_addr = adv_wr_addr_seg[BITS_ADDR_SEG - 1 : BITS_ADDR_LIM_BRICK]; 
      assign BRAM_RE_adv = rd_en_adv && !adv_rd_wr_addr_match_flag ? 1 << adv_BRAM_RE_addr : '0;
      assign BRAM_WE_adv = wr_en_adv ? 1 << adv_BRAM_WE_addr : '0;
   end
   else begin
      wire adv_BRAM_RE_addr, adv_BRAM_WE_addr;
      assign adv_BRAM_RE_addr = '0; 
      assign adv_BRAM_WE_addr = '0;
      assign BRAM_RE_adv = rd_en_adv && !adv_rd_wr_addr_match_flag ? 1 << adv_BRAM_RE_addr : '0;   
      assign BRAM_WE_adv = wr_en_adv ? 1 << adv_BRAM_WE_addr : '0;
   end
endgenerate
//------------------------------------------------------
//=======================================================================
*/   
 
//=======================================================================
//Input/output data : bitlines   
logic [DATA_WIDTH + NUM_DUMMY_BITS - 1 : 0] data_in_buff_reg, data_in_so_reg;
logic [DATA_WIDTH + NUM_DUMMY_BITS - 1 : 0] data_in_buff_w_dummy, data_in_so_w_dummy;
generate 
   if (NUM_DUMMY_BITS > 0) begin  
      logic [NUM_DUMMY_BITS - 1 : 0] dummy_in;
      assign dummy_in = '0;
      assign data_in_buff_w_dummy = {data_in_buff, dummy_in};
      assign data_in_so_w_dummy = {data_in_so, dummy_in};
   end
   else begin
      assign data_in_buff_w_dummy = data_in_buff;
      assign data_in_so_w_dummy = data_in_so;
   end 
endgenerate
   
// We don't need data input flops for BRAM. We need it only to handle when rd_wr_addr_match_flag = 1
//It worked for LiM because it was triggered at negedge. So, here(at input flops) data would get captured in posedge and in LiM brick data would get captured in the following negedge. But for BRAM, data and address would get captured as posedge by the the BRAM.    
   
// INPUT FLOPS
always_ff @ (posedge clk) begin
   if(~rst_b) begin
      data_in_buff_reg <= 0;
      data_in_so_reg <= 0;
   end
   else if (wr_en_adv) begin
      data_in_buff_reg <= data_in_buff_w_dummy;
      data_in_so_reg <= data_in_so_w_dummy;   
   end   
end
  
// OUTPUT
wire [DATA_WIDTH - 1 : 0] ARBL_buff, ARBL_so;
wire [DATA_WIDTH + NUM_DUMMY_BITS - 1 : 0] ARBL_buff_w_dummy, ARBL_so_w_dummy;
   
assign ARBL_buff = rd_wr_addr_match_flag_buff ? data_in_buff_reg[DATA_WIDTH + NUM_DUMMY_BITS - 1 : NUM_DUMMY_BITS] : ARBL_buff_w_dummy[DATA_WIDTH + NUM_DUMMY_BITS - 1 : NUM_DUMMY_BITS];
assign ARBL_so = rd_wr_addr_match_flag_so ? data_in_so_reg[DATA_WIDTH + NUM_DUMMY_BITS - 1 : NUM_DUMMY_BITS] : ARBL_so_w_dummy[DATA_WIDTH + NUM_DUMMY_BITS - 1 : NUM_DUMMY_BITS];

assign dout_so_early = ARBL_so;
   
//this is for nonpipelined version   
//assign dout_buff = ARBL_buff;
//assign dout_so = ARBL_so; 

//this is for pipelined version
register #(.WIDTH(DATA_WIDTH)) reg_ARBL_buff(.q(dout_buff), .d(ARBL_buff), .clk, .enable(mandatory_bubble_buff), .rst_b(rst_b));
register #(.WIDTH(DATA_WIDTH)) reg_ARBL_so(.q(dout_so), .d(ARBL_so), .clk, .enable(mandatory_bubble_so), .rst_b(rst_b)); 
//=======================================================================

/*   
//=======================================================================   
//LiM memory   
genvar j;
generate
   for (j = 0; j < NUM_BRICK_SEG_HOR; j = j + 1) begin : block_hor
      sram_block #(.NUM_BRICKS(NUM_BRICK_SEG_VER), .WL_WIDTH(NUM_BRICK_SEG_VER * `LIM_BRICK_WORD_NUM)) lim_buff(.CLK(~clk), .BLK_RE(BRAM_RE), .DRWL(rd_wl), .DWWL(wr_wl), .WBL(data_in_buff_reg[`LIM_BRICK_WORD_SIZE * (j+1) - 1 : `LIM_BRICK_WORD_SIZE * j]), .ARBL(ARBL_buff_w_dummy[`LIM_BRICK_WORD_SIZE * (j+1) - 1 : `LIM_BRICK_WORD_SIZE * j]));

      sram_block #(.NUM_BRICKS(NUM_BRICK_SEG_VER), .WL_WIDTH(NUM_BRICK_SEG_VER * `LIM_BRICK_WORD_NUM)) lim_so(.CLK(~clk), .BLK_RE(BRAM_RE), .DRWL(rd_wl), .DWWL(wr_wl), .WBL(data_in_so_reg[`LIM_BRICK_WORD_SIZE * (j+1) - 1 : `LIM_BRICK_WORD_SIZE * j]), .ARBL(ARBL_so_w_dummy[`LIM_BRICK_WORD_SIZE * (j+1) - 1 : `LIM_BRICK_WORD_SIZE * j]));
   end
endgenerate
//=======================================================================
*/

   
//======================================================================= 
//FPGA memory
generate
   //buff
   if (NUM_BUFF_SO_WORDS_SEG > 255) begin
      bram_m20k #(.BL_WIDTH(DATA_WIDTH), .ADDR_WIDTH(BITS_ADDR_SEG), .WL_WIDTH(NUM_BUFF_SO_WORDS_SEG)) bram_m20k_buff(.CLK(clk), .rd_en(rd_en_buff_adv && !adv_rd_wr_addr_match_flag_buff), .wr_en(wr_en_adv), .rd_addr(adv_rd_addr_buff), .wr_addr(adv_wr_addr_buff), .WBL(data_in_buff_w_dummy), .ARBL(ARBL_buff_w_dummy));   
   end

   else if (NUM_BUFF_SO_WORDS_SEG > 31) begin
      bram_mlab #(.BL_WIDTH(DATA_WIDTH), .ADDR_WIDTH(BITS_ADDR_SEG), .WL_WIDTH(NUM_BUFF_SO_WORDS_SEG)) bram_mlab_buff(.CLK(clk), .rd_en(rd_en_buff_adv && !adv_rd_wr_addr_match_flag_buff), .wr_en(wr_en_adv), .rd_addr(adv_rd_addr_buff), .wr_addr(adv_wr_addr_buff), .WBL(data_in_buff_w_dummy), .ARBL(ARBL_buff_w_dummy)); 
   end 

   else begin //use register block based memory
      reg_mem #(.BL_WIDTH(DATA_WIDTH), .ADDR_WIDTH(BITS_ADDR_SEG), .WL_WIDTH(NUM_BUFF_SO_WORDS_SEG)) reg_buff(.CLK(clk), .rd_en(rd_en_buff_adv && !adv_rd_wr_addr_match_flag_buff), .wr_en(wr_en_adv), .rd_addr(adv_rd_addr_buff), .wr_addr(adv_wr_addr_buff), .WBL(data_in_buff_w_dummy), .ARBL(ARBL_buff_w_dummy)); 
   end 
endgenerate

generate
   //so
   if (NUM_BUFF_SO_WORDS_SEG * DEPTH_SO_Q > 255) begin
      bram_m20k #(.BL_WIDTH(DATA_WIDTH), .ADDR_WIDTH(BITS_ADDR_SEG_SO), .WL_WIDTH(NUM_BUFF_SO_WORDS_SEG * DEPTH_SO_Q)) bram_m20k_so(.CLK(clk), .rd_en(rd_en_so_adv && !adv_rd_wr_addr_match_flag_so), .wr_en(wr_en_adv), .rd_addr(adv_rd_addr_so), .wr_addr(adv_wr_addr_so), .WBL(data_in_so_w_dummy), .ARBL(ARBL_so_w_dummy));
   end

   else if (NUM_BUFF_SO_WORDS_SEG * DEPTH_SO_Q > 31) begin
      bram_mlab #(.BL_WIDTH(DATA_WIDTH), .ADDR_WIDTH(BITS_ADDR_SEG_SO), .WL_WIDTH(NUM_BUFF_SO_WORDS_SEG * DEPTH_SO_Q)) bram_mlab_so(.CLK(clk), .rd_en(rd_en_so_adv && !adv_rd_wr_addr_match_flag_so), .wr_en(wr_en_adv), .rd_addr(adv_rd_addr_so), .wr_addr(adv_wr_addr_so), .WBL(data_in_so_w_dummy), .ARBL(ARBL_so_w_dummy));
   end

   else begin
      reg_mem #(.BL_WIDTH(DATA_WIDTH), .ADDR_WIDTH(BITS_ADDR_SEG_SO), .WL_WIDTH(NUM_BUFF_SO_WORDS_SEG * DEPTH_SO_Q)) reg_so(.CLK(clk), .rd_en(rd_en_so_adv && !adv_rd_wr_addr_match_flag_so), .wr_en(wr_en_adv), .rd_addr(adv_rd_addr_so), .wr_addr(adv_wr_addr_so), .WBL(data_in_so_w_dummy), .ARBL(ARBL_so_w_dummy));
   end
endgenerate

//=======================================================================     


endmodule

