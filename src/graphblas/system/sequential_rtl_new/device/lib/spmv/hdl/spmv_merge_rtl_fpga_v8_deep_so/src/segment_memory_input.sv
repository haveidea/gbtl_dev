//
//---------------------------------------------------------------------------
// SRAM memory block for input segment 
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module segment_memory_input #(
   parameter
     NUM_INPUT_WORDS_SEG = `NUM_INPUTs_PER_SEG_ARR * `INPUT_BIN_SIZE,
     NUM_BRICK_SEG_VER = NUM_INPUT_WORDS_SEG >> `BITS_ADDR_LIM_BRICK,
     NUM_BRICK_SEG_VER_WO_BIN = `NUM_INPUTs_PER_SEG_ARR >> `BITS_ADDR_LIM_BRICK,      
     NUM_BRICK_SEG_HOR = `NUM_BRICK_SEG_HOR_INPUT,		   
     DATA_WIDTH = `DATA_WIDTH_INPUT,
     NUM_DUMMY_BITS = `NUM_DUMMY_BITS_SEG_MEM_INPUT,
     BITS_ADDR_LIM_BRICK = `BITS_ADDR_LIM_BRICK,		      
     BITS_ADDR_SEG = `BITS_ADDR_SEG,
     BITS_ADDR_SEG_W_BIN = BITS_ADDR_SEG + `BITS_INPUT_BIN_ADDR) (

   input rst_b, clk, rd_en_adv, wr_en_adv, 
   input adv_rd_wr_addr_match_flag, rd_wr_addr_match_flag, mandatory_bubble_so,
   input [BITS_ADDR_SEG_W_BIN - 1 : 0] adv_rd_addr_seg_w_bin, wr_addr_input_w_bin,
   input [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [DATA_WIDTH - 1 : 0] data_in_input,

   output [DATA_WIDTH - 1 : 0] data_out_input_wo_tag_valid);

genvar j0;   

//Bin select for read (wr happens in all bins simultaneously)
//============================================================================    
wire [`INPUT_BIN_SIZE - 1 : 0] bin_select_adv;
wire [DATA_WIDTH + NUM_DUMMY_BITS - 1 : 0] ARBL_w_dummy;
wire [`INPUT_BIN_SIZE - 1 : 0] [DATA_WIDTH + NUM_DUMMY_BITS - 1 : 0] ARBL_w_dummy_bin;
   
//------------------------------------------------------
generate 
   if (`BITS_INPUT_BIN_ADDR > 0) begin  
      wire [`BITS_INPUT_BIN_ADDR - 1 : 0] bin_addr_adv, bin_addr;
      assign bin_addr_adv = adv_rd_addr_seg_w_bin[BITS_ADDR_SEG_W_BIN - 1 : BITS_ADDR_SEG_W_BIN - `BITS_INPUT_BIN_ADDR]; 
      assign bin_select_adv = rd_en_adv && !adv_rd_wr_addr_match_flag ? 1 << bin_addr_adv : '0; 
   
      register #(.WIDTH(`BITS_INPUT_BIN_ADDR)) reg_bin_addr(.q(bin_addr), .d(bin_addr_adv), .clk, .enable(rd_en_adv && !adv_rd_wr_addr_match_flag), .rst_b(rst_b));
      assign ARBL_w_dummy = ARBL_w_dummy_bin[bin_addr];
   end
   else begin
      wire bin_addr_adv;
      assign bin_addr_adv = '0; 
      assign bin_select_adv = rd_en_adv && !adv_rd_wr_addr_match_flag ? 1 << bin_addr_adv : '0;
      assign ARBL_w_dummy = ARBL_w_dummy_bin;
   end
endgenerate
//------------------------------------------------------
  
//============================================================================ 

/*   
//This part is only needed for ASIC. Comment out for FPGA    
//=======================================================================
//Wordlines + rd/wr enables     
wire [BITS_ADDR_LIM_BRICK - 1 : 0] adv_rd_addr_BRAM, adv_wr_addr_BRAM;
assign adv_rd_addr_BRAM = adv_rd_addr_seg_w_bin[BITS_ADDR_LIM_BRICK - 1 : 0];
assign adv_wr_addr_BRAM = wr_addr_input_w_bin[BITS_ADDR_LIM_BRICK - 1 : 0];  
   
wire [NUM_BRICK_SEG_VER_WO_BIN - 1 : 0] BRAM_RE_wo_bin_adv, BRAM_WE_wo_bin_adv;
wire [NUM_BRICK_SEG_VER_WO_BIN * `LIM_BRICK_WORD_NUM - 1 : 0] rd_wl_adv, wr_wl_adv; //wo bin  
wire [`LIM_BRICK_WORD_NUM - 1 : 0] single_brick_rd_wl_adv, single_brick_wr_wl_adv;
assign single_brick_rd_wl_adv = rd_en_adv && !adv_rd_wr_addr_match_flag ? 1 << adv_rd_addr_BRAM : '0;
assign single_brick_wr_wl_adv = wr_en_adv ? 1 << adv_wr_addr_BRAM : '0;

generate
   for (j0 = 0; j0 < NUM_BRICK_SEG_VER_WO_BIN; j0 = j0 + 1) begin  
      assign rd_wl_adv[`LIM_BRICK_WORD_NUM * (j0 + 1) - 1 : `LIM_BRICK_WORD_NUM * j0] = BRAM_RE_wo_bin_adv[j0] ? single_brick_rd_wl_adv : '0;
      assign wr_wl_adv[`LIM_BRICK_WORD_NUM * (j0 + 1) - 1 : `LIM_BRICK_WORD_NUM * j0] = BRAM_WE_wo_bin_adv[j0] ? single_brick_wr_wl_adv : '0;      
   end
endgenerate   
   
logic [`INPUT_BIN_SIZE - 1 : 0][NUM_BRICK_SEG_VER_WO_BIN - 1 : 0] BRAM_RE_w_bin_adv;
logic [`INPUT_BIN_SIZE - 1 : 0][NUM_BRICK_SEG_VER_WO_BIN * `LIM_BRICK_WORD_NUM - 1 : 0] rd_wl_w_bin_adv, wr_wl_w_bin_adv;  

always_comb begin
   for (integer i1 = 0; i1 < `INPUT_BIN_SIZE; i1 = i1 + 1) begin  
      rd_wl_w_bin_adv[i1] = bin_select_adv[i1] && rd_en_adv && !adv_rd_wr_addr_match_flag ? rd_wl_adv : '0;
      wr_wl_w_bin_adv[i1] = wr_en_adv ? wr_wl_adv : '0; //as we write in parallel
      BRAM_RE_w_bin_adv[i1] = bin_select_adv[i1] && rd_en_adv && !adv_rd_wr_addr_match_flag ? BRAM_RE_wo_bin_adv : '0;  
   end
end   

wire [`INPUT_BIN_SIZE - 1 : 0][NUM_BRICK_SEG_VER_WO_BIN - 1 : 0] BRAM_RE_w_bin;
wire [`INPUT_BIN_SIZE - 1 : 0][NUM_BRICK_SEG_VER_WO_BIN * `LIM_BRICK_WORD_NUM - 1 : 0] rd_wl_w_bin, wr_wl_w_bin;  
     
register2D #(.WIDTH1(`INPUT_BIN_SIZE), .WIDTH2(NUM_BRICK_SEG_VER_WO_BIN * `LIM_BRICK_WORD_NUM)) reg_rd_wl(.q(rd_wl_w_bin), .d(rd_wl_w_bin_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));

register2D #(.WIDTH1(`INPUT_BIN_SIZE), .WIDTH2(NUM_BRICK_SEG_VER_WO_BIN * `LIM_BRICK_WORD_NUM)) reg_wr_wl(.q(wr_wl_w_bin), .d(wr_wl_w_bin_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));

register2D #(.WIDTH1(`INPUT_BIN_SIZE), .WIDTH2(NUM_BRICK_SEG_VER_WO_BIN)) reg_BRAM_RE(.q(BRAM_RE_w_bin), .d(BRAM_RE_w_bin_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));
   
//------------------------------------------------------
generate 
   if (BITS_ADDR_SEG - BITS_ADDR_LIM_BRICK > 0) begin  
      wire [BITS_ADDR_SEG - BITS_ADDR_LIM_BRICK - 1 : 0] adv_BRAM_RE_addr, adv_BRAM_WE_addr;
      assign adv_BRAM_RE_addr = adv_rd_addr_seg_w_bin[BITS_ADDR_SEG - 1 : BITS_ADDR_LIM_BRICK]; 
      assign adv_BRAM_WE_addr = wr_addr_input_w_bin[BITS_ADDR_SEG - 1 : BITS_ADDR_LIM_BRICK]; 
      assign BRAM_RE_wo_bin_adv = rd_en_adv && !adv_rd_wr_addr_match_flag ? 1 << adv_BRAM_RE_addr : '0;
      assign BRAM_WE_wo_bin_adv = wr_en_adv ? 1 << adv_BRAM_WE_addr : '0; 
   end
   else begin
      wire adv_BRAM_RE_addr, adv_BRAM_WE_addr;
      assign adv_BRAM_RE_addr = '0; 
      assign adv_BRAM_WE_addr = '0; 
      assign BRAM_RE_wo_bin_adv = rd_en_adv && !adv_rd_wr_addr_match_flag ? 1 << adv_BRAM_RE_addr : '0;
      assign BRAM_WE_wo_bin_adv = wr_en_adv ? 1 << adv_BRAM_WE_addr : '0; 
   end
endgenerate
//------------------------------------------------------
//=======================================================================
*/
    
//============================================================================    
logic [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [DATA_WIDTH + NUM_DUMMY_BITS - 1 : 0] data_in_input_w_dummy;
logic [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [DATA_WIDTH + NUM_DUMMY_BITS - 1 : 0] data_in_input_reg;
   
generate 
   if (NUM_DUMMY_BITS > 0) begin  
      logic [NUM_DUMMY_BITS - 1 : 0] dummy_in;
      assign dummy_in = '0;
      for (j0 = 0; j0 < `BLK_SLOW_PARR_WR_NUM; j0 = j0 + 1) begin      
	 assign data_in_input_w_dummy[j0] = {data_in_input[j0], dummy_in};	
      end
   end
   else begin
      assign data_in_input_w_dummy = data_in_input;
   end
endgenerate

//We don't need data input flops for BRAM. We need it only to handle when rd_wr_addr_match_flag = 1
//It worked for LiM because it was triggered at negedge. So, here(at input flops) data would get captured in posedge and in LiM brick data would get captured in the following negedge. But for BRAM, data and address would get captured as posedge by the the BRAM.
   
// INPUT FLOPS 
always_ff @ (posedge clk) begin
   if(~rst_b) begin
      for (integer i0 = 0; i0 < `BLK_SLOW_PARR_WR_NUM; i0 = i0 + 1) begin
	 data_in_input_reg[i0] <= '0;
      end
   end
   else if (wr_en_adv) begin
      data_in_input_reg <= data_in_input_w_dummy;

      //data_in_input_reg <= data_in_input[`BLK_SLOW_PARR_WR_NUM - 1]; //so the first data of the block. last data will not work. -- I dont think this is correct 
   end   
end

// Output
wire [DATA_WIDTH - 1 : 0] ARBL;
   
//assign ARBL = rd_wr_addr_match_flag ? data_in_input_reg : ARBL_w_dummy [DATA_WIDTH + NUM_DUMMY_BITS - 1 : NUM_DUMMY_BITS];

//we don't care about the rd_wr_addr_match_flag as in this scenario blk_en_adv is deasserted. so no need to handle
assign ARBL = ARBL_w_dummy [DATA_WIDTH + NUM_DUMMY_BITS - 1 : NUM_DUMMY_BITS];   

//this is for nonpipelined version   
//assign data_out_input_wo_tag_valid = ARBL;

//this is for pipelined version
register #(.WIDTH(DATA_WIDTH)) reg_ARBL(.q(data_out_input_wo_tag_valid), .d(ARBL), .clk, .enable(mandatory_bubble_so), .rst_b(rst_b));
//============================================================================   

/*
//=======================================================================   
//LiM memory   
genvar j1;
generate
   for (j1 = 0; j1 < `BLK_SLOW_PARR_WR_NUM; j1 = j1 + 1) begin : bin //this should be `INPUT_BIN_SIZE
      for (j0 = 0; j0 < NUM_BRICK_SEG_HOR; j0 = j0 + 1) begin : block_hor
	 sram_block #(.NUM_BRICKS(NUM_BRICK_SEG_VER_WO_BIN), .WL_WIDTH(NUM_BRICK_SEG_VER_WO_BIN * `LIM_BRICK_WORD_NUM)) lim_input(.CLK(~clk), .BLK_RE(BRAM_RE_w_bin[j1]), .DRWL(rd_wl_w_bin[j1]), .DWWL(wr_wl_w_bin[j1]), .WBL(data_in_input_reg[j1][`LIM_BRICK_WORD_SIZE * (j0+1) - 1 : `LIM_BRICK_WORD_SIZE * j0]), .ARBL(ARBL_w_dummy_bin[j1][`LIM_BRICK_WORD_SIZE * (j0+1) - 1 : `LIM_BRICK_WORD_SIZE * j0]));
      end
   end
endgenerate
//=======================================================================
*/

   
//======================================================================= 
//FPGA memory
   wire [BITS_ADDR_SEG - 1 : 0] adv_rd_addr_seg, adv_wr_addr_seg;
   assign adv_rd_addr_seg = adv_rd_addr_seg_w_bin[BITS_ADDR_SEG - 1 : 0];
   assign adv_wr_addr_seg = wr_addr_input_w_bin[BITS_ADDR_SEG - 1 : 0];

   genvar j1;  
   generate
      for (j1 = 0; j1 < `BLK_SLOW_PARR_WR_NUM; j1 = j1 + 1) begin : bin //this should be `INPUT_BIN_SIZE
	 bram_m20k #(.BL_WIDTH(DATA_WIDTH), .ADDR_WIDTH(BITS_ADDR_SEG), .WL_WIDTH(`NUM_INPUTs_PER_SEG_ARR)) bram_input(.CLK(clk), .rd_en(bin_select_adv[j1] && rd_en_adv && !adv_rd_wr_addr_match_flag), .wr_en(wr_en_adv), .rd_addr(adv_rd_addr_seg), .wr_addr(adv_wr_addr_seg), .WBL(data_in_input_w_dummy[j1]), .ARBL(ARBL_w_dummy_bin[j1]));
   end
   endgenerate
//=======================================================================     

   
endmodule

