//
//---------------------------------------------------------------------------
//  Block of the merge network using multiple segments 
//******** Note on synchronizing 'write address', 'write data' and 'write enable' *********
//Normally, 'write address', 'write data' and 'write enable' all are ready on the same clk cycle (t).
//However, for the 'write decoder', the 'write address' and 'write enable' has to be delayed one cycle because the event of wordline enable and writing actually happens in the next cycle (t+1). Nonetheless, the 'write enable' signal plugged into the memory blocks should be the non-delayed 'write enable' (t) signal. This is because this 'write enable' signal only triggers the Flop to latch the input data.   
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module merge_blk_slow #(//this is an array of merge segments(stages) that works on slow clk speed
   parameter
     DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,
     INITIALIZE_SEG_ADDR_WIDTH = `INITIALIZE_SEG_ADDR_WIDTH) (
   input clk, rst_b, mode, wr_en_input, unit_en, out_fifo_wr_ready_slow_adv,
   input [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] wr_addr_input,
   input [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [`WORD_WIDTH_INPUT - 1 : 0] data_in_blk_slow, 
   input [`BITS_ROW_IDX - 1 : 0] maxidx_input,    
   input fill_req_accepted,
   input [`BITS_INPUT_BIN_ADDR - 1 : 0] set_wr_ctr_input, set_rd_ctr_input,
   input [`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_input,
   //output
   output logic blk_en_adv, 
   output logic ini_blk_slow_done, 
   output send_fill_req,
   output [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] bin_to_fill_addr_blk_slow,
   output [`NUM_INPUTs_PER_SEG_ARR - 1 : 0][`NUM_UNITs - 1 : 0] bin_empty_flags,
   output [DATA_WIDTH - 1 : 0] blk_out_data_tot);

//Initialize SRAM memories
//--------------------------------------------
logic [INITIALIZE_SEG_ADDR_WIDTH - 1 : 0] addr_seg_initialize_wr, addr_seg_initialize_wr_temp;
always_ff @(posedge clk) begin    
   if(~rst_b) begin
      addr_seg_initialize_wr <= 0;
      addr_seg_initialize_wr_temp <= 0; 
   end
   else if(unit_en && mode == `MODE_POPULATE_ZERO) begin //unit_en is an external signal. so for 0 address, wr_en might not be timed properly. therefore, 0 address is ensured by the _temp signal
      //addr_seg_initialize_wr <= addr_seg_initialize_wr + 1;
      addr_seg_initialize_wr <= addr_seg_initialize_wr_temp;
      addr_seg_initialize_wr_temp <= addr_seg_initialize_wr_temp + 1;
   end
end
   
always_ff @(posedge clk) begin    
   if(~rst_b) begin
       ini_blk_slow_done <= 1'b0;      
   end
   else if(unit_en && mode == `MODE_POPULATE_ZERO && addr_seg_initialize_wr == (1 << INITIALIZE_SEG_ADDR_WIDTH) - 1) begin
      ini_blk_slow_done <= 1'b1;
   end
end
//--------------------------------------------
wire [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] wr_addr_input_temp;
wire wr_en_input_temp = (unit_en && mode == `MODE_POPULATE_ZERO && !ini_blk_slow_done) ? 1'b1 : wr_en_input;
assign wr_addr_input_temp = (mode == `MODE_POPULATE_ZERO && unit_en) ? addr_seg_initialize_wr : wr_addr_input;   
					   
///wire [`NUM_STGs - `END_OF_FAST_STG - 1 : 0] addr_seg_rd, addr_seg_wr;//only addr is reverse of stage order
//wire [`NUM_STGs - `END_OF_FAST_STG - 1 : 0] adv_addr_seg_rd; 
//wire [(1<<(`NUM_STGs - `END_OF_FAST_STG))*2 - 2 : 0] wl_seg_rd, wl_seg_wr; //wordlines

//Just for simulation purpose
//--------------------------------------------
logic [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [`BITS_ROW_IDX - 1 : 0] data_in_row_idx;
logic [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [`DATA_PRECISION - 1 : 0] data_in_value;

always_comb begin
   for (integer i0 = 0; i0 < `BLK_SLOW_PARR_WR_NUM; i0 = i0 + 1) begin  
      data_in_row_idx[i0] = data_in_blk_slow[i0][`DATA_WIDTH_INPUT - 1 : `DATA_WIDTH_INPUT - `BITS_ROW_IDX];
      data_in_value[i0] = data_in_blk_slow[i0][`DATA_WIDTH_INPUT - `BITS_ROW_IDX -1 : 0];
   end
end
wire [`BITS_ROW_IDX - 1 : 0] blk_out_row_idx = blk_out_data_tot[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
wire [`DATA_PRECISION - 1 : 0] blk_out_value = blk_out_data_tot[DATA_WIDTH - `BITS_ROW_IDX -1 : DATA_WIDTH - `BITS_ROW_IDX - `DATA_PRECISION]; 
wire blk_out_valid = blk_out_data_tot[0];    
//--------------------------------------------   

/*   
//---addr_seg_wr_temp is used both time while data input and zero propagation. This is because we have to sweep through the address. mode and unit_en are of same cycle. They can be used together in logic. 
///assign addr_seg_wr_temp = (mode == `MODE_POPULATE_ZERO && unit_en) ? addr_seg_initialize_wr : addr_seg_rd;   
   
wire mandatory_bubble;
logic mode_reg;
register #(.WIDTH(1)) reg_mode(.q(mode_reg), .d(mode), .clk(clk), .enable(1'b1), .rst_b(rst_b));

wire blk_en_next; 
register #(.WIDTH(1)) reg_blk_en_next(.q(blk_en_next), .d(blk_en), .clk(clk), .enable(1'b1), .rst_b(rst_b));  
register #(.WIDTH(`NUM_STGs - `END_OF_FAST_STG)) reg_addr_seg_wr(.q(addr_seg_wr), .d(addr_seg_wr_temp), .clk(clk), .enable(1'b1), .rst_b(rst_b)); 

logic wr_pending, wr_pause, rd_en_buff_so_adv, rd_en_buff_so, wr_en_buff_so_adv, wr_en_buff_so, wr_en_input_temp;  
assign rd_en_buff_so_adv = (blk_en_adv & mode == `MODE_WORK) ? 1'b1 : 1'b0;
register #(.WIDTH(1)) reg_rd_en_buff_so(.q(rd_en_buff_so), .d(rd_en_buff_so_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));


   
///assign wr_pause = mode == `MODE_WORK && !blk_en_adv && blk_en && wr_en_buff_so;//even though the wr_en_buff_so logic may seem weird, it is correct. we actually stop the writing in the same cycle when blk_en_adv is deasserted. we check if wr_en_buff_so_adv was asserted in the previous cycle. If so, we pause that writing and make it pending.

assign wr_pause = !blk_en_adv && rd_en_buff_so; //when blk_en_adv is low and rd_en_buff_so is high, it means we should have written in the current cycle. But, the adv_rd_addr_seg needs to be flopped before we write at the same address (i.e. rd_addr_seg) during the current cycle (where blk_en_adv is low). So, we postpone the write to happen when blk_en_adv becomes high again (at this cycle the adv_rd_addr will be flopped). 
   
always_ff @(posedge clk) begin    
   if(~rst_b) begin
      wr_pending <= 1'b0;
   end
   else if (wr_pause && mode == `MODE_WORK) begin
      wr_pending <= 1'b1;
   end
   else if (wr_en_buff_so_adv && mode == `MODE_WORK) begin
      wr_pending <= 1'b0;
   end
end
   
assign wr_en_buff_so_adv = (unit_en && mode == `MODE_POPULATE_ZERO && !ini_blk_slow_done) ? 1'b1 : (rd_en_buff_so && !wr_pause) || (blk_en_adv && wr_pending) ? 1'b1 : 1'b0;//blk_en_adv is in same cycle of unit_en
register #(.WIDTH(1)) reg_wr_en_buff_so(.q(wr_en_buff_so), .d(wr_en_buff_so_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));
*/   
///Rationale
/*
We want to sync write enable with blk_en_adv so that output fifo empty signal can be responded in the same cycle. So we want to pause any write if there were actually any wr_en_adv active in the cycle before blk_en_adv is deasserted. So we pause exactly at same state and resume from the same state when blk_en_adv is asserted again.  
 
 At the very beginning after blk_en_adv is asserted, only rd_en_adv is asserted. No wr_en_adv is asserted before the cycle blk_en_adv is deasserted. Therefore, we don't activate any wr pending signal. However, due to rd_en signal, write will happen in the consecutive cycles even though blk_en_adv is deasserted. We don't inhibit this write because this write was not actually harm even though fifo is empty. This is beacuse in the last blk_en_adv = 1 cycle there was no wr_en_adv active signal. So it is okay to write later and move one stage ahead in the pipeline.
 
 Moreover, the consecutive write after rd_en_adv is required initially as the correct adv_addr_seg_rd(7F after 3F) requires write to happen.
 
 It would be good to make sure blk_en_adv is not asserted before the consecutive write at initially.  
*/
   
//register #(.WIDTH(`NUM_STGs - `END_OF_FAST_STG), .RESET_VALUE(7'b1111111)) reg_adv_addr_seg_rd(.q(addr_seg_rd), .d(adv_addr_seg_rd), .clk(clk), .enable(blk_en_adv && mode == `MODE_WORK), .rst_b(rst_b));//actually we need 7'b1000000. Need to make sure rd_addr and adv_rd_addr is not the same for seg1. We need 3F as the initial value for adv_addr_seg_rdadv_addr_seg_rd

///register #(.WIDTH(`NUM_STGs - `END_OF_FAST_STG), .RESET_VALUE('0)) reg_adv_addr_seg_rd(.q(addr_seg_rd), .d(adv_addr_seg_rd), .clk(clk), .enable(blk_en_adv && mode == `MODE_WORK), .rst_b(rst_b));   
   
//Normally during bin refill blk_en should be 0. However, at the very first time when we are filling up the bins, we want to do the zero propagation (initialize the memory) too. So at the very beginning we will keep blk_en 1 (while the mode will be zero_propagation_mode) when at the same time we will be filling up the bins for the very first time. The write address sweep from first to last for bin filling is utilized in writiting zeros (and set the valit bit and the tag) in the segment memory.
   
//Note: To intialize the memories, we need to initialize (Zero Propagate) by making blk_en =1 amd mode=MODE_POPULATE_ZERO and sweep accoss the address space. But this will not initialize the memory at the input stage. To do that, we need to make wr_en_input=1 and propagate proper value. Note, for multiple units, we not necessarily initialize them with all 0 (because of radix sort).

wire [`NUM_STGs - `END_OF_FAST_STG : 0] [DATA_WIDTH - 1 : 0] data_out_seg; //forward going   
wire [`NUM_STGs - `END_OF_FAST_STG : 0] log_rd_q_prev_stg, latest_tag_bit; //backward going
wire [`NUM_STGs - `END_OF_FAST_STG : 0] [`BITS_INPUT_ADDR_SLOW_BLK - 1: 0] addr_in_q; //backward going
wire [`NUM_STGs - `END_OF_FAST_STG : 0] rdq_full, wr_en_stg_adv, rd_en_buff_adv, mandatory_bubble_buff; //forward going      
wire [`NUM_STGs - `END_OF_FAST_STG : 0] [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] adv_rd_addr_buff_extra, adv2_wr_addr_stg_extra, adv_wr_addr_stg_extra; //forward going    
   
assign blk_out_data_tot = data_out_seg[0];   
assign log_rd_q_prev_stg[0] = out_fifo_wr_ready_slow_adv; //this is needed for stg0. make sure it is connected to stg_en_adv directly. if passed though q, then data might be read from stg0 when output fifo is full 
assign blk_en_adv = log_rd_q_prev_stg[1];
assign latest_tag_bit[0] = 1'b0; //irrelevant
   
//First stage/segment of the block 
//=============================================================================
    merge_segment #(.SEG0(1),    
          .NUM_BUFF_SO_WORDS_SEG(1),
	  .NUM_BRICK_SEG_VER(1), //brick is irrelevant here. We assign 1 just to use the same merge_segment module
          .DEPTH_SO_Q(1), .BITS_SO_Q(0),
          .DATA_WIDTH(DATA_WIDTH), .BITS_ADDR_SEG(1)) stg0(
	  //input										 
          .rst_b, .clk, .mode, .unit_en, .ini_blk_slow_done,
          .addr_stg_initialize_wr_extra(1'b0), //irrelevant		          
          .log_rd_q(log_rd_q_prev_stg[0]), .latest_tag_bit_next_stg(latest_tag_bit[0]),
	  .rdq_full_prev_stg(rdq_full[1]), 	      
          .wr_en_stg_adv(wr_en_stg_adv[1]), .rd_en_buff_adv(rd_en_buff_adv[1]),
          .mandatory_bubble_buff(mandatory_bubble_buff[1]),   
          .addr_in_q(1'b0), //irrelevant					   
          .adv_rd_addr_buff_extra(2'b0), //irrelevant
          .adv2_wr_addr_stg_extra(2'b0), //irrelevant
          .adv_wr_addr_stg_extra(2'b0), //irrelevant  
          .data_in_seg(data_out_seg[1]),
          //output
          .log_rd_q_prev_stg(log_rd_q_prev_stg[1]),
	  .latest_tag_bit(latest_tag_bit[1]),						   
          .addr_in_q_prev_stg(addr_in_q[1][1 : 0]),          
          .rdq_full(rdq_full[0]),
          .wr_en_next_stg_adv(wr_en_stg_adv[0]), .rd_en_buff_next_stg_adv(rd_en_buff_adv[0]),
          .mandatory_bubble_buff_next_stg(mandatory_bubble_buff[0]),				   
          .adv_rd_addr_buff_next_stg_extra(adv_rd_addr_buff_extra[0][0]), //irrelevant
          .adv2_wr_addr_next_stg_extra(adv2_wr_addr_stg_extra[0][0]), //irrelevant
          .adv_wr_addr_next_stg_extra(adv_wr_addr_stg_extra[0][0]), //irrelevant
          .data_out_seg(data_out_seg[0]));
//=============================================================================

//Rest of the stages/segments of the block 
//=============================================================================
genvar j0;
generate
   for (j0 = 1; j0 < `NUM_STGs - `END_OF_FAST_STG; j0 = j0 + 1) begin
      //localparam integer soq_depth = j0==1 || j0==2 ? 2 : 1;
      //localparam integer soq_bits = j0==1 || j0==2 ? 1 : 0;
      //localparam integer next_stg_deep_so = j0==2 || j0==3 ? 1 : 0;

      //localparam integer soq_depth = j0==1 ? 2 : 1;
      //localparam integer soq_bits = j0==1 ? 1 : 0;
      //localparam integer next_stg_deep_so = j0==2 ? 1 : 0;
      
      localparam integer soq_depth = 1;
      localparam integer soq_bits = 0;
      localparam integer next_stg_deep_so = 0;
      
    merge_segment #(.NEXT_STG_DEEP_SO(next_stg_deep_so),    
          .NUM_BUFF_SO_WORDS_SEG(1 << j0),
	  .NUM_BRICK_SEG_VER(1 << (j0 - `BITS_ADDR_LIM_BRICK)),
          .DEPTH_SO_Q(soq_depth), .BITS_SO_Q(soq_bits), 
          .DATA_WIDTH(DATA_WIDTH), .BITS_ADDR_SEG(j0)) stg(
	  //input										 
          .rst_b, .clk, .mode, .unit_en, .ini_blk_slow_done, 
          //.addr_stg_initialize_wr_extra(addr_seg_initialize_wr[`BITS_INPUT_ADDR_SLOW_BLK - 1 : `BITS_INPUT_ADDR_SLOW_BLK - j0]),//change this to use lsbs 
	  .addr_stg_initialize_wr_extra(addr_seg_initialize_wr[j0 - 1 : 0]), 	          
          .log_rd_q(log_rd_q_prev_stg[j0]), .latest_tag_bit_next_stg(latest_tag_bit[j0]),
          .rdq_full_prev_stg(rdq_full[j0 + 1]),     
          .wr_en_stg_adv(wr_en_stg_adv[j0 + 1]), .rd_en_buff_adv(rd_en_buff_adv[j0 + 1]),
          .mandatory_bubble_buff(mandatory_bubble_buff[j0 + 1]),
          .addr_in_q(addr_in_q[j0][j0 - 1 : 0]),           
          .adv_rd_addr_buff_extra(adv_rd_addr_buff_extra[j0 + 1][j0 : 0]),
          .adv2_wr_addr_stg_extra(adv2_wr_addr_stg_extra[j0 + 1][j0 : 0]),
          .adv_wr_addr_stg_extra(adv_wr_addr_stg_extra[j0 + 1][j0 : 0]),   
          .data_in_seg(data_out_seg[j0 + 1]),
          //output
          .log_rd_q_prev_stg(log_rd_q_prev_stg[j0 + 1]),
	  .latest_tag_bit(latest_tag_bit[j0 + 1]),						   
          .addr_in_q_prev_stg(addr_in_q[j0 + 1][j0 : 0]),
          .rdq_full(rdq_full[j0]),
          .wr_en_next_stg_adv(wr_en_stg_adv[j0]), .rd_en_buff_next_stg_adv(rd_en_buff_adv[j0]),
          .mandatory_bubble_buff_next_stg(mandatory_bubble_buff[j0]),	  	    
          .adv_rd_addr_buff_next_stg_extra(adv_rd_addr_buff_extra[j0][j0 - 1 : 0]),
          .adv2_wr_addr_next_stg_extra(adv2_wr_addr_stg_extra[j0][j0 - 1 : 0]),
          .adv_wr_addr_next_stg_extra(adv_wr_addr_stg_extra[j0][j0 - 1 : 0]),
          .data_out_seg(data_out_seg[j0]));
   end		  
endgenerate
//=============================================================================

//The last and biggest segment (input stage) of the block
//============================================================================= 			  
merge_segment_input #(
    .NUM_INPUT_WORDS_SEG((1<<(`BITS_INPUT_ADDR_SLOW_BLK))*`INPUT_BIN_SIZE),
    .NUM_BRICK_SEG_VER((1 << (`BITS_INPUT_ADDR_SLOW_BLK - `BITS_ADDR_LIM_BRICK))*`INPUT_BIN_SIZE),
    .DATA_WIDTH(`DATA_WIDTH_INPUT), .BITS_ADDR_SEG(`BITS_INPUT_ADDR_SLOW_BLK)) seg_input(
    //input
    .rst_b, .clk, .unit_en, .mode, .ini_blk_slow_done,
    .wr_en_input(wr_en_input_temp), //.out_fifo_wr_ready_slow_adv,		 
    .addr_stg_initialize_wr_extra(addr_seg_initialize_wr),
    .log_rd_q(log_rd_q_prev_stg[`BITS_INPUT_ADDR_SLOW_BLK]),
    .latest_tag_bit_next_stg(latest_tag_bit[`BITS_INPUT_ADDR_SLOW_BLK]),
    .addr_in_q(addr_in_q[`BITS_INPUT_ADDR_SLOW_BLK][`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0]), 
    .wr_addr_input(wr_addr_input_temp), 
    .data_in_input(data_in_blk_slow), .maxidx_input,
    .fill_req_accepted,
    .set_wr_ctr_input, .set_rd_ctr_input, .set_track_ctr_input,   
    //output  
    .rdq_full(rdq_full[`BITS_INPUT_ADDR_SLOW_BLK]),
    .wr_en_next_stg_adv(wr_en_stg_adv[`BITS_INPUT_ADDR_SLOW_BLK]),
    .rd_en_buff_next_stg_adv(rd_en_buff_adv[`BITS_INPUT_ADDR_SLOW_BLK]),
    .mandatory_bubble_buff_next_stg(mandatory_bubble_buff[`BITS_INPUT_ADDR_SLOW_BLK]),	    
    .adv_rd_addr_buff_next_stg_extra(adv_rd_addr_buff_extra[`BITS_INPUT_ADDR_SLOW_BLK]),
    .adv2_wr_addr_next_stg_extra(adv2_wr_addr_stg_extra[`BITS_INPUT_ADDR_SLOW_BLK]),
    .adv_wr_addr_next_stg_extra(adv_wr_addr_stg_extra[`BITS_INPUT_ADDR_SLOW_BLK]),  		    
    .data_out_input(data_out_seg[`BITS_INPUT_ADDR_SLOW_BLK]),
    .send_fill_req,
    .bin_to_fill_addr_blk_slow,
    .bin_empty_flags);
//=============================================================================
			  
endmodule
