//
//---------------------------------------------------------------------------
//  Segment with either lim or reg 
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module merge_segment_input #(
   parameter
     NEXT_STG_DEEP_SO = 0,			     
     NUM_UNITs = `NUM_UNITs, 
     NUM_INPUT_WORDS_SEG = `NUM_INPUTs_PER_SEG_ARR * `INPUT_BIN_SIZE,
     NUM_BRICK_SEG_VER = NUM_INPUT_WORDS_SEG >> `BITS_ADDR_LIM_BRICK,
     NUM_BRICK_SEG_VER_WO_BIN = `NUM_INPUTs_PER_SEG_ARR >> `BITS_ADDR_LIM_BRICK,		   
     DATA_WIDTH = `DATA_WIDTH_INPUT,
     WORD_WIDTH = `WORD_WIDTH_INPUT,
     DEPTH_STG_RD_Q = 4, //this should be same for all stages
     BITS_STG_RD_Q = 2,	 			     
     BITS_ADDR_SEG = `BITS_ADDR_SEG,
     BITS_ADDR_FILL_REQ_Q = `BITS_ADDR_FILL_REQ_Q) (
											 
   input rst_b, clk, unit_en, mode, ini_blk_slow_done, wr_en_input, log_rd_q, latest_tag_bit_next_stg,
   input [BITS_ADDR_SEG - 1 : 0] addr_stg_initialize_wr_extra, 
   input [BITS_ADDR_SEG - 1 : 0] addr_in_q, 
   input [BITS_ADDR_SEG - 1 : 0] wr_addr_input,  
   input [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [WORD_WIDTH - 1 : 0] data_in_input,
   input [`BITS_ROW_IDX - 1 : 0] maxidx_input, 
   input fill_req_accepted,
   input [`BITS_INPUT_BIN_ADDR - 1 : 0] set_wr_ctr_input, set_rd_ctr_input, 
   input [`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_input, 

   //output
   //output logic blk_en_adv, blk_en, mandatory_bubble_so, 
   output rdq_full, wr_en_next_stg_adv, rd_en_buff_next_stg_adv, mandatory_bubble_buff_next_stg,
   output [BITS_ADDR_SEG - 1 : 0] adv_rd_addr_buff_next_stg_extra,
   output [BITS_ADDR_SEG - 1 : 0] adv2_wr_addr_next_stg_extra, adv_wr_addr_next_stg_extra,
   output [`DATA_WIDTH_BUFF_SO_SEG - 1 : 0] data_out_input,
   output send_fill_req,
   output [BITS_ADDR_SEG - 1 : 0] bin_to_fill_addr_blk_slow,
   output logic [`NUM_INPUTs_PER_SEG_ARR - 1 : 0][NUM_UNITs - 1 : 0] bin_empty_flags);

wire global_en;
assign global_en = (mode == `MODE_WORK) && unit_en;   
logic adv_rd_wr_addr_match_flag, rd_wr_addr_match_flag;

   wire stg_en_adv, stg_en, rd_en_so_adv, rd_en_so;     
   //---------------------------------------------------------------------
   logic mandatory_bubble_so;
   //this is due to separating the logic after memory read + put it in separate pipeline. So throughput will be 1 element/2 cycles
   //logic mandatory_bubble_so; 
   always_ff @ (posedge clk) begin
      if(~rst_b) begin
	 mandatory_bubble_so <= 1'b0;
      end
      else if (rd_en_so_adv) begin
	 mandatory_bubble_so <= 1'b1; //when this is 1, actual rd/wr happens in SRAM
      end
      else begin
	 mandatory_bubble_so <= 1'b0;
      end
   end
   assign mandatory_bubble_buff_next_stg = mandatory_bubble_so;
   //---------------------------------------------------------------------
       
   // Stage read queue
   //=========================================================================================
   wire rdq_empty, rdq_rd_en, rdq_wr_en;
   wire [BITS_ADDR_SEG - 1 : 0] rdq_din, rdq_dout;
   wire [BITS_ADDR_SEG - 1 : 0] adv_rd_addr_woq_so, rd_addr_woq_so; //used to rd this stage so & next stg buff
           
   assign rdq_din = addr_in_q;   
    /*
   //use this to read address only from q
   assign rd_addr_available = !rdq_empty;  
   assign rdq_wr_en = log_rd_q;
   assign rdq_rd_en = rd_en_so_adv;
   assign adv_rd_addr_woq_so = rdq_dout;
   */
   
   //use this to get read address for this stage  directly from the next stage if q is empty. It can only happens between 2 stages. Doesn't create long combinational path as log_rd_q_next_stg is triggered by rd_en_so. If we had used rd_en_so_adv, then we could have an long combinational path
   assign rd_addr_available = rdq_empty ? log_rd_q : 1'b1;
   assign rdq_wr_en = rdq_empty ? log_rd_q && !rd_en_so_adv : log_rd_q;
   assign rdq_rd_en = rdq_empty ? 1'b0 : rd_en_so_adv;

   //if (NEXT_STG_DEEP_SO == 0) begin
      assign adv_rd_addr_woq_so = rdq_empty ? addr_in_q : rdq_dout; 
   /*end
   else begin
      assign adv_rd_addr_woq_so = rdq_empty ? {addr_in_q[BITS_ADDR_SEG - 1 : 1], !latest_tag_bit_next_stg} : {rdq_dout[BITS_ADDR_SEG - 1 : 1], !latest_tag_bit_next_stg}; 
   end*/
      
   //This works as the read q for this stage and write q for the next stage (exclude the lsb)
   sfifo #(.DSIZE(BITS_ADDR_SEG), .ASIZE(BITS_STG_RD_Q)) rdq
     (//input
      .clk, .rst_b, .rd_en(rdq_rd_en), .wr_en(rdq_wr_en),
      .data_in(rdq_din),
      //output
      .data_out(rdq_dout),
      .full(rdq_full), .empty(rdq_empty));
   //=========================================================================================
 
   //=========================================================================================  
   //stg_en means this stage is trying to move forward
   assign stg_en_adv = unit_en && (mode == `MODE_WORK) && !rdq_empty && !mandatory_bubble_so;
   //assign stg_en_adv = unit_en && (mode == `MODE_WORK) && rdq_full_prev_stg && !rdq_empty;
   register #(.WIDTH(1)) reg_stg_en(.q(stg_en), .d(stg_en_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));

   //rd_en means whether this stage reads SO
   //assign rd_en_so_adv = stg_en_adv && rdq_full_prev_stg && !rdq_empty && !soq_empty_adv && !adv_rd_wr_addr_match_flag;
   assign rd_en_so_adv = stg_en_adv && !adv_rd_wr_addr_match_flag; //!soq_empty_adv is equivalent to !bin_empty signal. we provide data even if bin is empty. not sure whether !adv_rd_wr_addr_match_flag is needed though 
   //rdq for previous stg is logically the write qfor this stage. If we read SO, that means we have to write to SO too in any coming cycles. So write q has to be not full  
   register #(.WIDTH(1)) reg_rd_en_so(.q(rd_en_so), .d(rd_en_so_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));
   
   register #(.WIDTH(BITS_ADDR_SEG)) reg_rd_addr_woq_so(.q(rd_addr_woq_so), .d(adv_rd_addr_woq_so), .clk(clk), .enable(rd_en_so_adv), .rst_b(rst_b)); 
   //register #(.WIDTH(BITS_ADDR_SEG_SO)) reg_rd_addr_so(.q(rd_addr_so), .d(adv_rd_addr_so), .clk(clk), .enable(rd_en_so_adv), .rst_b(rst_b));

   wire rd_en_input_adv = rd_en_so_adv;
   wire rd_en_input = rd_en_so;
   wire [BITS_ADDR_SEG - 1 : 0] adv_rd_addr_seg = adv_rd_addr_woq_so;
   wire [BITS_ADDR_SEG - 1 : 0] rd_addr_seg = rd_addr_woq_so;   
   //=========================================================================================

   //=========================================================================================
   //next stage write addr and wr enable + next stage buff rd address and en
   wire [BITS_ADDR_SEG - 1 : 0] adv_wr_addr_next_stg_extra_temp; 
   assign adv2_wr_addr_next_stg_extra = (mode == `MODE_POPULATE_ZERO && unit_en) ? addr_stg_initialize_wr_extra : rd_addr_woq_so; //exclude lsb for next stg //remains same for 2 cycles at least when mandatory_bubble_so exists
 
   register #(.WIDTH(BITS_ADDR_SEG)) reg_adv_wr_addr_next_stg_extra_temp(.q(adv_wr_addr_next_stg_extra_temp), .d(adv2_wr_addr_next_stg_extra), .clk(clk), .enable(stg_en), .rst_b(rst_b)); //use adv2 for so q counter read, use adv for total wr address decode only
   assign adv_wr_addr_next_stg_extra = (mode == `MODE_POPULATE_ZERO && unit_en) ? addr_stg_initialize_wr_extra : adv_wr_addr_next_stg_extra_temp;

   logic wr_pending_next_stg;
   always_ff @(posedge clk) begin    
      if(~rst_b) begin
	 wr_pending_next_stg <= 1'b0;
      end
      //else if (rd_en_so && !wr_en_next_stg_adv) begin
      else if (rd_en_so) begin	 
	 wr_pending_next_stg <= 1'b1;
      end
      //else if (wr_en_next_stg_adv) begin
      else if (!rd_en_so && wr_en_next_stg_adv) begin	 
	 wr_pending_next_stg <= 1'b0;
      end
   end
   //assign wr_en_next_stg_adv = (unit_en && mode == `MODE_POPULATE_ZERO && !ini_blk_slow_done) || (rd_en_so && !mandatory_bubble_so) || (rd_en_so_adv && wr_pending_next_stg);
   assign wr_en_next_stg_adv = (unit_en && mode == `MODE_POPULATE_ZERO && !ini_blk_slow_done) || (!mandatory_bubble_so && wr_pending_next_stg);

   assign rd_en_buff_next_stg_adv = rd_en_so_adv;
   assign adv_rd_addr_buff_next_stg_extra = adv_rd_addr_woq_so; 
   //=========================================================================================
   
wire wr_en_input_reg, mode_reg;
logic [BITS_ADDR_SEG - 1 : 0] wr_addr_input_reg;   
wire [DATA_WIDTH - 1 : 0] data_out_input_wo_tag_valid;
  
register #(.WIDTH(1)) reg_mode(.q(mode_reg), .d(mode), .clk(clk), .enable(1'b1), .rst_b(rst_b));
register #(.WIDTH(BITS_ADDR_SEG)) reg_wr_addr_input(.q(wr_addr_input_reg), .d(wr_addr_input), .clk(clk), .enable(1'b1), .rst_b(rst_b));   
register #(.WIDTH(1)) reg_wr_en_input(.q(wr_en_input_reg), .d(wr_en_input), .clk(clk), .enable(1'b1), .rst_b(rst_b));//rd_en_input_adv and wr_en_input are of same cycle

//Just for simulation purpose
//--------------------------------------------
logic [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [`BITS_ROW_IDX - 1 : 0] data_in_row_idx;
logic [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [`DATA_PRECISION - 1 : 0] data_in_value;

always_comb begin
   for (integer i0 = 0; i0 < `BLK_SLOW_PARR_WR_NUM; i0 = i0 + 1) begin  
      data_in_row_idx[i0] = data_in_input[i0][`DATA_WIDTH_INPUT - 1 : `DATA_WIDTH_INPUT - `BITS_ROW_IDX];
      data_in_value[i0] = data_in_input[i0][`DATA_WIDTH_INPUT - `BITS_ROW_IDX -1 : 0];
   end
end
//--------------------------------------------   
       
//Declaring the rd address, wr address and FIFO track counter table
//****************************************************************************************    
//Valiables with unpacked are not displayed in NCSim simulation, but works fine    
//Do the following if you want to see the variables in simulation
logic [`NUM_INPUTs_PER_SEG_ARR - 1 : 0] [`BITS_INPUT_BIN_ADDR - 1 : 0] bin_rd_addr_ctr;
logic [`NUM_INPUTs_PER_SEG_ARR - 1 : 0] [`BITS_INPUT_BIN_ADDR - 1 : 0] bin_wr_addr_ctr;   
// we need `BITS_INPUT_BIN_ADDR + 1 bits as we have to literally express the number (say 4(100)) of available words to read
logic [`NUM_INPUTs_PER_SEG_ARR - 1 : 0] [`BITS_INPUT_BIN_ADDR : 0] fifo_track_ctr;    
//****************************************************************************************  
  
//Reading the counters using decoded wordlines
//****************************************************************************************    
logic [`BITS_INPUT_BIN_ADDR - 1 : 0] current_rd_addr_ctr;
logic [`BITS_INPUT_BIN_ADDR - 1 : 0] current_wr_addr_ctr; 
logic [`BITS_INPUT_BIN_ADDR : 0] current_fifo_track_ctr_1, current_fifo_track_ctr_2;

assign current_rd_addr_ctr = bin_rd_addr_ctr[adv_rd_addr_seg];
assign current_wr_addr_ctr = bin_wr_addr_ctr[wr_addr_input]; 
assign current_fifo_track_ctr_1 = fifo_track_ctr[adv_rd_addr_seg];
assign current_fifo_track_ctr_2 = fifo_track_ctr[wr_addr_input]; 
   
//To ensure only one incrementer or decrementer is synthesized   
wire [`BITS_INPUT_BIN_ADDR - 1 : 0] bin_rd_addr_ctrPlus1, bin_wr_addr_ctrPlus1;
wire [`BITS_INPUT_BIN_ADDR : 0] fifo_track_ctrPlus1, fifo_track_ctrMinus1;

assign bin_rd_addr_ctrPlus1 = current_rd_addr_ctr + 1'b1; 
////assign bin_wr_addr_ctrPlus1 = current_wr_addr_ctr + 1'b1;
assign bin_wr_addr_ctrPlus1 = current_wr_addr_ctr + `BLK_SLOW_PARR_WR_NUM;
   
////assign fifo_track_ctrPlus1 = current_fifo_track_ctr_2 + 1'b1; 
assign fifo_track_ctrPlus1 = current_fifo_track_ctr_2 + `BLK_SLOW_PARR_WR_NUM; 
assign fifo_track_ctrMinus1 = current_fifo_track_ctr_1 - 1'b1;

logic bin_empty, bin_empty_prev;
assign bin_empty = (fifo_track_ctr[adv_rd_addr_seg] == 0) ? 1 : 0;
register #(.WIDTH(1)) reg_bin_empty(.q(bin_empty_prev), .d(bin_empty), .clk(clk), .enable(rd_en_input_adv), .rst_b(rst_b));

assign adv_rd_wr_addr_match_flag = wr_en_input && (wr_addr_input == adv_rd_addr_seg) ? 1'b1 : 1'b0;//dnt use rn_en as this flag is needed for blk_en_adv signal
assign rd_wr_addr_match_flag = wr_en_input_reg && rd_en_input && (wr_addr_input_reg == rd_addr_seg) ? 1'b1 : 1'b0;
//****************************************************************************************
   
//Bin empty flags   
//========================================================================================      
logic [`NUM_INPUTs_PER_SEG_ARR - 1 : 0][NUM_UNITs : 0] bin_empty_flags_w_extra;
wire log_fill_req_active;
wire sending_fill_req_bin_empty;
   
always_ff @ (posedge clk) begin
   if(~rst_b) begin
      for (integer i3 = 0; i3 < `NUM_INPUTs_PER_SEG_ARR; i3 = i3 + 1) begin
	 bin_empty_flags_w_extra[i3] <= '0;
      end
   end
   else if (log_fill_req_active && (wr_en_input && (set_track_ctr_input != 0)) && adv_rd_addr_seg != wr_addr_input) begin
      bin_empty_flags_w_extra[adv_rd_addr_seg] <= '1;
      bin_empty_flags_w_extra[wr_addr_input] <= '0;
   end
   else if (log_fill_req_active && (wr_en_input && (set_track_ctr_input != 0)) && adv_rd_addr_seg == wr_addr_input) begin
      bin_empty_flags_w_extra[wr_addr_input] <= '0;
   end   
   else if (log_fill_req_active && !(wr_en_input && (set_track_ctr_input != 0))) begin
      bin_empty_flags_w_extra[adv_rd_addr_seg] <= '1;
   end
   else if (!log_fill_req_active && (wr_en_input && (set_track_ctr_input != 0))) begin
      bin_empty_flags_w_extra[wr_addr_input] <= '0;
   end
end // always_ff @
  
assign sending_fill_req_bin_empty = bin_empty_flags_w_extra[bin_to_fill_addr_blk_slow][0]; //because data might have already written before fill req is actually sent (due to other unit's request)
  
//assign bin_empty_flags = bin_empty_flags_w_extra[`NUM_INPUTs_PER_SEG_ARR - 1 : 0][NUM_UNITs : 1];
always_comb begin      
   for (integer i2 = 0; i2 < `NUM_INPUTs_PER_SEG_ARR; i2 = i2 + 1) begin
      bin_empty_flags[i2] = bin_empty_flags_w_extra[i2][NUM_UNITs : 1];
   end
end
//========================================================================================      
    
//Controlling the counters and related flags   
//========================================================================================     
integer i;

always_ff @ (posedge clk) begin //make sure to integrate global_en now as input stage is also 0 initialized
   if(~rst_b) begin
      for (i = 0; i < `NUM_INPUTs_PER_SEG_ARR; i = i + 1) begin
	 fifo_track_ctr[i] <= '0;
	 bin_rd_addr_ctr[i] <= '0;
	 bin_wr_addr_ctr[i] <= '0;
      end
   end
   else if(global_en && rd_en_input_adv && wr_en_input && (adv_rd_addr_seg == wr_addr_input)) begin//never happen 
      fifo_track_ctr[wr_addr_input] <= set_track_ctr_input;
      bin_rd_addr_ctr[wr_addr_input] <= set_rd_ctr_input;
      bin_wr_addr_ctr[wr_addr_input] <= set_wr_ctr_input;
   end
   else if(global_en && (rd_en_input_adv && !bin_empty) && wr_en_input && (adv_rd_addr_seg != wr_addr_input)) begin
      fifo_track_ctr[wr_addr_input] <= set_track_ctr_input;
      bin_rd_addr_ctr[wr_addr_input] <= set_rd_ctr_input;
      bin_wr_addr_ctr[wr_addr_input] <= set_wr_ctr_input;

      fifo_track_ctr[adv_rd_addr_seg] <= fifo_track_ctrMinus1;
      bin_rd_addr_ctr[adv_rd_addr_seg] <= bin_rd_addr_ctrPlus1;
   end
   else if(global_en && (rd_en_input_adv && !bin_empty) && !wr_en_input) begin      
      fifo_track_ctr[adv_rd_addr_seg] <= fifo_track_ctrMinus1;
      bin_rd_addr_ctr[adv_rd_addr_seg] <= bin_rd_addr_ctrPlus1;
   end   
   else if(global_en && !(rd_en_input_adv && !bin_empty) && wr_en_input) begin
      fifo_track_ctr[wr_addr_input] <= set_track_ctr_input;
      bin_rd_addr_ctr[wr_addr_input] <= set_rd_ctr_input;
      bin_wr_addr_ctr[wr_addr_input] <= set_wr_ctr_input;
   end    
end   
//========================================================================================   
   
//Fill queue and blk_en signals   
//========================================================================================   
//if the early request isn't logged, the later request when the bin is empty will definitely be logged   
wire log_fill_req, log_fill_req_early;//early reqest will avoid bubbles when possible   
assign log_fill_req_early = global_en && rd_en_input_adv && fifo_track_ctr[adv_rd_addr_seg] == 1 && (!wr_en_input || (wr_en_input && adv_rd_addr_seg != wr_addr_input));//this will be active only for one cycle   
assign log_fill_req = global_en && bin_empty;//this will be active until data bin is received  
assign log_fill_req_active = log_fill_req || log_fill_req_early;
     
//---------------------------------------------------------------------
//Issuing fill request. We have a queue for the fill requests too
//Sending the fill req through FIFO. It also breaks the comb path for the adv_rd_addr. And also can issue fill request for any state of the bin (i.e. even before it is empty to avoid cycle losses to refill)   
wire fill_req_q_full, fill_req_q_empty, fill_req_q_rd_en, fill_req_q_wr_en;
wire cur_fill_req_history;
  
assign fill_req_q_wr_en = (global_en && !fill_req_q_full) && (log_fill_req_early || log_fill_req) && !cur_fill_req_history;
assign fill_req_q_rd_en = global_en && (fill_req_accepted || (!fill_req_q_empty && !sending_fill_req_bin_empty)); 
assign send_fill_req = global_en && !fill_req_q_empty && sending_fill_req_bin_empty; //send_fill_req remains active until accepted

//this should be big enough to store one request for each list   
sfifo #(.DSIZE(BITS_ADDR_SEG), .ASIZE(BITS_ADDR_FILL_REQ_Q)) fill_req_q 
  (//input
   .clk, .rst_b, .rd_en(fill_req_q_rd_en), .wr_en(fill_req_q_wr_en),
   .data_in(adv_rd_addr_seg),
   //output
   .data_out(bin_to_fill_addr_blk_slow),
   .full(fill_req_q_full), .empty(fill_req_q_empty));
//---------------------------------------------------------------------   
   
//---------------------------------------------------------------------
// Fill request history for the lists. Used to avoid multiple requests for same list       
logic [`NUM_INPUTs_PER_SEG_ARR - 1 : 0] fill_req_history; //one bit more to keep all read separate 
assign cur_fill_req_history = fill_req_history[adv_rd_addr_seg];

always_ff @ (posedge clk) begin
   if(~rst_b) begin
      for (integer i1 = 0; i1 < `NUM_INPUTs_PER_SEG_ARR; i1 = i1 + 1) begin
	 fill_req_history[i1] <= '0;
      end
   end
   else if (fill_req_q_wr_en && wr_en_input && adv_rd_addr_seg != wr_addr_input) begin
      fill_req_history[adv_rd_addr_seg] <= '1;
      fill_req_history[wr_addr_input] <= '0;
   end
   else if (fill_req_q_wr_en && wr_en_input && adv_rd_addr_seg == wr_addr_input) begin//this case will not happen
      fill_req_history[adv_rd_addr_seg] <= '1;
   end   
   else if (fill_req_q_wr_en && !wr_en_input) begin
      fill_req_history[adv_rd_addr_seg] <= '1;
   end
   else if (!fill_req_q_wr_en && wr_en_input) begin
      fill_req_history[wr_addr_input] <= '0;
   end
end // always_ff @
//---------------------------------------------------------------------

///assign blk_en_adv = (mode == `MODE_WORK) && unit_en && out_fifo_wr_ready_slow_adv && !adv_rd_wr_addr_match_flag && !mandatory_bubble_so;
//we incorporated rd_wr_addr_match_flag because when data is written, even if we want to read the last element of the bin (as the bin is empty and want to move on), the element read will be something unwanted due to write //we don't need to need to check whether fill q is writable and log_fill_req is asserted. This is because the q is long enough to log one request for each list.  
   
///register #(.WIDTH(1)) reg_blk_en(.q(blk_en), .d(blk_en_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));
//========================================================================================   

//Decoding from the bin counters & the entire input for the segment
//========================================================================================
wire [BITS_ADDR_SEG + `BITS_INPUT_BIN_ADDR - 1 : 0] adv_rd_addr_seg_w_bin, wr_addr_input_w_bin;
wire [`BITS_INPUT_BIN_ADDR - 1 : 0] highest_rd_addr_ctr;
assign highest_rd_addr_ctr = '1;

wire [`BITS_ROW_IDX - 1 : 0] dout_maxidx, dout_maxidx_reg;

assign adv_rd_addr_seg_w_bin = bin_empty ? {highest_rd_addr_ctr, adv_rd_addr_seg} : {current_rd_addr_ctr, adv_rd_addr_seg}; //inluding highest counter bin is probably unnecessary
assign wr_addr_input_w_bin = {current_wr_addr_ctr, wr_addr_input};

assign data_out_input = bin_empty_prev ? {dout_maxidx_reg, `DATA_PRECISION'b0, 1'b0} : {data_out_input_wo_tag_valid, 1'b1}; 
   
wire [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [WORD_WIDTH - 1 : 0] data_in_input_temp;
assign data_in_input_temp = (mode == `MODE_POPULATE_ZERO && unit_en) ? '0 : data_in_input; //Also need to zero initialize input bins. This is because we read the the last bins rowidx even if bin is empty.
wire [`BITS_ROW_IDX - 1 : 0] maxidx_input_temp = (mode == `MODE_POPULATE_ZERO && unit_en) ? '0 : maxidx_input;
   
segment_memory_input #(
    //.NUM_INPUT_WORDS_SEG(NUM_INPUT_WORDS_SEG), .NUM_BRICK_SEG_VER(NUM_BRICK_SEG_VER), .NUM_BRICK_SEG_VER_WO_BIN(NUM_BRICK_SEG_VER_WO_BIN), .BITS_ADDR_SEG(BITS_ADDR_SEG)) seg_mem_input_lim (//for lim
    .NUM_INPUT_WORDS_SEG(NUM_INPUT_WORDS_SEG), .NUM_BRICK_SEG_VER(NUM_BRICK_SEG_VER), .NUM_BRICK_SEG_VER_WO_BIN(NUM_BRICK_SEG_VER_WO_BIN), .BITS_ADDR_SEG(BITS_ADDR_SEG), .NUM_DUMMY_BITS(0)) seg_mem_input_bram ( //for bram  	
    //input
    .rst_b, .clk, .mandatory_bubble_so,
    .rd_en_adv(rd_en_input_adv), .wr_en_adv(wr_en_input),
    .adv_rd_wr_addr_match_flag, .rd_wr_addr_match_flag,
    .adv_rd_addr_seg_w_bin, .wr_addr_input_w_bin,			 
    .data_in_input(data_in_input_temp),
    //output											 
    .data_out_input_wo_tag_valid);
//========================================================================================   

//============================================================================
// Maximum index storage
   bram_m20k #(.BL_WIDTH(`BITS_ROW_IDX), .ADDR_WIDTH(BITS_ADDR_SEG), .WL_WIDTH(`NUM_INPUTs_PER_SEG_ARR)) maximum_index_input(.CLK(clk), .rd_en(rd_en_input_adv), .wr_en(wr_en_input), .rd_addr(adv_rd_addr_seg), .wr_addr(wr_addr_input), .WBL(maxidx_input_temp), .ARBL(dout_maxidx));

   //we flop it because now the pipeline for logic is separate
   register #(.WIDTH(`BITS_ROW_IDX)) reg_dout_maxidx(.q(dout_maxidx_reg), .d(dout_maxidx), .clk, .enable(mandatory_bubble_so), .rst_b(rst_b));
   
//============================================================================        
     
   //just for debug
   wire seg_out_valid;
   wire [`BITS_ROW_IDX - 1 : 0] seg_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] seg_out_value; 
   
   assign seg_out_valid = data_out_input[0];
   assign seg_out_row_idx = data_out_input[`DATA_WIDTH_BUFF_SO_SEG - 1 : `DATA_WIDTH_BUFF_SO_SEG - `BITS_ROW_IDX];
   assign seg_out_value = data_out_input[`DATA_WIDTH_BUFF_SO_SEG - `BITS_ROW_IDX - 1 : `DATA_WIDTH_BUFF_SO_SEG - `BITS_ROW_IDX - `DATA_PRECISION];   
   		     
endmodule
