//
//---------------------------------------------------------------------------
//  Segment with either lim or reg 
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module merge_segment #(
   parameter
     SEG0 = 0, //pass 1 for segment 0	
     NEXT_STG_DEEP_SO = 0, //1 means next stage has deep SO (depth>1), 0 means mext stage has SO depth=1
     NUM_BUFF_SO_WORDS_SEG = `NUM_BUFF_SO_WORDS_SEG,
     NUM_BRICK_SEG_VER = `NUM_BRICK_SEG_VER,		   
     DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,
     DEPTH_SO_Q = 1, //this can vary from stage to stage
     BITS_SO_Q = 0,		       
     BITS_ADDR_SEG = `BITS_ADDR_SEG,
     BITS_ADDR_SEG_SO = BITS_ADDR_SEG + BITS_SO_Q,		       		       
     DEPTH_STG_RD_Q = 4, //this should be same for all stages
     BITS_STG_RD_Q = 2,	       
     LIM_OR_REG = 0) ( //0 means SRAM based memory and 1 means reg based memory
											 
   input rst_b, clk, mode, unit_en, ini_blk_slow_done,
   input [BITS_ADDR_SEG - 1 : 0] addr_stg_initialize_wr_extra,
   input [BITS_ADDR_SEG - 1 : 0] addr_in_q, 		          
   input rdq_full_prev_stg, log_rd_q, latest_tag_bit_next_stg,   				      
   input wr_en_stg_adv, rd_en_buff_adv, mandatory_bubble_buff,
   input [BITS_ADDR_SEG : 0] adv_rd_addr_buff_extra,
   input [BITS_ADDR_SEG : 0] adv2_wr_addr_stg_extra, adv_wr_addr_stg_extra,
   input [DATA_WIDTH - 1 : 0] data_in_seg,

   output log_rd_q_prev_stg, latest_tag_bit, 			    
   output [BITS_ADDR_SEG : 0] addr_in_q_prev_stg,
   output rdq_full, wr_en_next_stg_adv, rd_en_buff_next_stg_adv, mandatory_bubble_buff_next_stg,
   output [BITS_ADDR_SEG - 1 : 0] adv_rd_addr_buff_next_stg_extra,
   output [BITS_ADDR_SEG - 1 : 0] adv2_wr_addr_next_stg_extra, adv_wr_addr_next_stg_extra,
   output [DATA_WIDTH - 1 : 0] data_out_seg);

   wire [BITS_ADDR_SEG - 1 : 0] adv_rd_addr_buff = adv_rd_addr_buff_extra[BITS_ADDR_SEG : 1];
   wire [BITS_ADDR_SEG - 1 : 0] adv2_wr_addr_stg = adv2_wr_addr_stg_extra[BITS_ADDR_SEG : 1];
   wire [BITS_ADDR_SEG - 1 : 0] adv_wr_addr_stg = adv_wr_addr_stg_extra[BITS_ADDR_SEG : 1];

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
   wire [BITS_ADDR_SEG_SO - 1 : 0] adv_rd_addr_so, rd_addr_so;
   wire rd_addr_available, tag_bit_next_stg_update_pending;
      
   generate
   if(SEG0 == 0) begin
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
      //assign adv_rd_addr_woq_so = rdq_empty ? addr_in_q : rdq_dout;
                  
      if (NEXT_STG_DEEP_SO == 0) begin //if next stg doesn't have deep SO
	 assign adv_rd_addr_woq_so = rdq_empty ? addr_in_q : rdq_dout;
	 assign tag_bit_next_stg_update_pending = 1'b0;
      end
      else begin //if next stg has deep SO
	 if (BITS_ADDR_SEG == 1) begin//for stg1
	    assign adv_rd_addr_woq_so = !latest_tag_bit_next_stg;
	    assign tag_bit_next_stg_update_pending = 1'b0;
	 end
	 else begin//for stages >1
	    assign adv_rd_addr_woq_so = rdq_empty ? {addr_in_q[BITS_ADDR_SEG - 1 : 1], !latest_tag_bit_next_stg} : {rdq_dout[BITS_ADDR_SEG - 1 : 1], !latest_tag_bit_next_stg};
	    assign tag_bit_next_stg_update_pending = (adv_rd_addr_buff_next_stg_extra[BITS_ADDR_SEG - 1 : 1] == adv_wr_addr_next_stg_extra[BITS_ADDR_SEG - 1 : 1]) && wr_en_next_stg_adv;//this is needed to handle consecutive rd request from the same so of this stage.
	 end	 
      end
            
      //This works as the read q for this stage and write q for the next stage (exclude the lsb)
      sfifo #(.DSIZE(BITS_ADDR_SEG), .ASIZE(BITS_STG_RD_Q)) rdq
	(//input
	 .clk, .rst_b, .rd_en(rdq_rd_en), .wr_en(rdq_wr_en),
	 .data_in(rdq_din),
	 //output
	 .data_out(rdq_dout),
	 .full(rdq_full), .empty(rdq_empty));
   end // if (SEG0 == 0)

   else begin
      assign rdq_full = 1'b0; 
      assign adv_rd_addr_woq_so = 1'b0; 
      assign rd_addr_available = log_rd_q; //log_rd_q is actually out_fifo_wr_ready_slow_adv for stg0
   end
   endgenerate
   //=========================================================================================

   //=========================================================================================
   //this stage rd_en and previous stage q input address
   wire soq_empty_adv, soq_full_adv2;
     
   generate
      if(SEG0 == 0) begin
	 //stg_en means this stage is trying to move forward
	 assign stg_en_adv = unit_en && (mode == `MODE_WORK) && rd_addr_available && !mandatory_bubble_so;
	 //assign stg_en_adv = unit_en && (mode == `MODE_WORK) && rd_addr_available && !mandatory_bubble_so && !tag_bit_next_stg_update_pending; //we need this this stg is deep and next stg is also deep
	    
	 //rd_en means whether this stage reads SO
	 assign rd_en_so_adv = stg_en_adv && !rdq_full_prev_stg && !soq_empty_adv; //rdq for previous stg is logically the write qfor this stage. If we read SO, that means we have to write to SO too in any coming cycles. So write q has to be not full
      end
      else begin //for SEG0
	 assign stg_en_adv = unit_en && (mode == `MODE_WORK) && rd_addr_available;
	 assign rd_en_so_adv = stg_en_adv && !rdq_full_prev_stg && (!soq_empty_adv || wr_en_stg_adv);
      end
   endgenerate

   register #(.WIDTH(1)) reg_stg_en(.q(stg_en), .d(stg_en_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));    
   register #(.WIDTH(1)) reg_rd_en_so(.q(rd_en_so), .d(rd_en_so_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));
   
   register #(.WIDTH(BITS_ADDR_SEG)) reg_rd_addr_woq_so(.q(rd_addr_woq_so), .d(adv_rd_addr_woq_so), .clk(clk), .enable(rd_en_so_adv), .rst_b(rst_b)); 
   register #(.WIDTH(BITS_ADDR_SEG_SO)) reg_rd_addr_so(.q(rd_addr_so), .d(adv_rd_addr_so), .clk(clk), .enable(rd_en_so_adv), .rst_b(rst_b)); 
      
   logic [NUM_BUFF_SO_WORDS_SEG - 1 : 0] tag_column; 
   logic tag_bit, tag_input;
   
   generate
      if(SEG0 == 0) begin
	 if(DEPTH_SO_Q == 1) begin //we use this for big stages normally
	    assign tag_bit = tag_column[rd_addr_woq_so];
	    assign addr_in_q_prev_stg = {rd_addr_woq_so, !tag_bit};
	    assign log_rd_q_prev_stg = rd_en_so;
	 end
	 else begin //for deep SO
	    assign tag_bit = tag_column[adv_rd_addr_buff];
	    assign addr_in_q_prev_stg = {rd_addr_woq_so, 1'b0};//!tag_bit};//for deep SO, we don't care tag bit during log rd q, we care about it during actual read
	    assign log_rd_q_prev_stg = rd_en_so;
	 end
      end
      else begin //this is for seg 0
	 assign tag_bit = tag_column[rd_addr_woq_so];
	 assign addr_in_q_prev_stg = wr_en_stg_adv ? {adv_wr_addr_stg, !tag_input} : {adv_rd_addr_woq_so, !tag_bit};//as it is for SEG0, only the tag bit matters
	 assign log_rd_q_prev_stg = rd_en_so_adv;	 
      end
   endgenerate

   //assign latest_tag_bit = wr_en_stg_adv && rd_en_buff_adv && (adv_rd_addr_buff == adv_wr_addr_stg) ? tag_input : tag_bit;
    assign latest_tag_bit = tag_bit;
   //=========================================================================================

   //=========================================================================================
   //this stage SO read & write address 
   wire [BITS_ADDR_SEG_SO - 1 : 0] adv_wr_addr_stg_so;
      
   generate
      if(DEPTH_SO_Q > 1) begin
	 wire [BITS_SO_Q - 1 : 0] soq_rd_ptr_adv, soq_wr_ptr_adv2, soq_wr_ptr_adv;
	 ptr_packed_qs_g1 #(.NUM_OF_Q(NUM_BUFF_SO_WORDS_SEG), .BITS_ADDR_PACK(BITS_ADDR_SEG), .BITS_ADDR_EACH_Q(BITS_SO_Q)) soq_ptr_g1
	   (//input
	    .rst_b, .clk, .rd_ptr_inc(rd_en_so_adv), .wr_ptr_inc(wr_en_stg_adv),
            .rd_addr(adv_rd_addr_woq_so), .wr_addr(adv2_wr_addr_stg), 
            //output
	    .q_empty(soq_empty_adv), .q_full(soq_full_adv2),
            .rd_ptr_val(soq_rd_ptr_adv), .wr_ptr_val(soq_wr_ptr_adv2));
      
	 register #(.WIDTH(BITS_SO_Q)) reg_soq_wr_ptr_adv(.q(soq_wr_ptr_adv), .d(soq_wr_ptr_adv2), .clk(clk), .enable(1'b1), .rst_b(rst_b));
	 //---------------------------------------
	 if (SEG0 == 0) begin
	    assign adv_rd_addr_so = {adv_rd_addr_woq_so, soq_rd_ptr_adv};
	    assign adv_wr_addr_stg_so = {adv_wr_addr_stg, soq_wr_ptr_adv};
	 end
	 else begin
	    assign adv_rd_addr_so = soq_rd_ptr_adv;
	    assign adv_wr_addr_stg_so = soq_wr_ptr_adv;	 
	 end
	 //---------------------------------------
      end    
      
      else begin
	 ptr_packed_qs_e1 #(.NUM_OF_Q(NUM_BUFF_SO_WORDS_SEG), .BITS_ADDR_PACK(BITS_ADDR_SEG), .BITS_ADDR_EACH_Q(0)) soq_ptr_e1
	   (//input
	    .rst_b, .clk, .rd_ptr_inc(rd_en_so_adv), .wr_ptr_inc(wr_en_stg_adv),
            .rd_addr(adv_rd_addr_woq_so), .wr_addr(adv2_wr_addr_stg), 
            //output
	    .q_empty(soq_empty_adv), .q_full(soq_full_adv2));
      
      	 assign adv_rd_addr_so = adv_rd_addr_woq_so;
	 assign adv_wr_addr_stg_so = adv_wr_addr_stg;   
      end      
   endgenerate
   //=========================================================================================

   //=========================================================================================
   //next stage write addr and wr enable + next stage buff rd address and rd enable
   wire [BITS_ADDR_SEG - 1 : 0] adv_wr_addr_next_stg_extra_temp; 
   assign adv2_wr_addr_next_stg_extra = (mode == `MODE_POPULATE_ZERO && unit_en) ? addr_stg_initialize_wr_extra : rd_addr_woq_so; //exclude lsb for next stg //remains same for 2 cycles at least when mandatory_bubble_so exists
  
   register #(.WIDTH(BITS_ADDR_SEG)) reg_adv_wr_addr_next_stg_extra_temp(.q(adv_wr_addr_next_stg_extra_temp), .d(adv2_wr_addr_next_stg_extra), .clk(clk), .enable(rd_en_so), .rst_b(rst_b)); //use adv2 for so q counter read, use adv for total wr address decode only
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

   //Compare and tag bit control
   //========================================================================================
   logic [DATA_WIDTH - 1 : 0] data_in_buff, data_in_so, data_out_buff; 
   wire select;
   compare_select_simple #(.DATA_WIDTH(`DATA_WIDTH_ADD_STG)) comparator( 
      //input
      .din0(data_out_buff), .din1(data_in_seg), //data_out_buff should get preference. So it is imporatnt to assign is in the first input port din0
     //output			       
     .select);

   wire tag_bit_for_incoming_data = !tag_column[adv_wr_addr_stg];
   
   always_comb begin: compare
      if (mode == `MODE_WORK) begin //don't make in mode_reg. we want same cycle data as unit_en.
	 if (select == 1'b0) begin
	    data_in_buff = data_in_seg;
	    data_in_so = data_out_buff;
	    tag_input = tag_bit_for_incoming_data; 
	 end
	 else begin
 	    data_in_buff = data_out_buff;
	    data_in_so = data_in_seg; 
	    tag_input = !tag_bit_for_incoming_data;  
	 end 
      end 
      else begin 
	 ////data_in_buff = {{DATA_WIDTH - 2{1'b0}}, 2'b00};//make invalid and BUFF tags all 0 in zero prop mode
	 ////data_in_so = {{DATA_WIDTH - 2{1'b0}}, 2'b01};//make invalid and SO tags all 1 in zero prop mode
	 data_in_buff = '0;//make invalid and BUFF tags all 0 in zero prop mode
	 data_in_so = '0;//make invalid and SO tags all 1 in zero prop mode
	 //tag_input = (BITS_SO_Q > 0) ? !adv_wr_addr_stg_so[0] : 1'b1;
	 tag_input = 1'b0; 
      end 
   end // block: compare   

   always_ff @(posedge clk) begin    
      if(~rst_b) begin
	 tag_column <= '0;
      end
      //write
      //else if(wr_en_stg_adv) begin
      else if((wr_en_stg_adv && mode == `MODE_WORK) || (wr_en_stg_adv && unit_en && mode == `MODE_POPULATE_ZERO && !soq_full_adv2)) begin //soq_full_adv2 is needed for mode=0 state. it is equivalent to soq_full_adv   
         tag_column[adv_wr_addr_stg] <= tag_input; 
      end
   end 
   //========================================================================================  
   
   //just for waveform viewing purpose and debug
   //=============================================================================
   wire seg_out_valid, seg_in_valid;
   wire [`BITS_ROW_IDX - 1 : 0] seg_out_row_idx, seg_in_row_idx;	  
   wire [`DATA_PRECISION - 1 : 0] seg_out_value, seg_in_value;
 
   //assign seg_in_valid = data_in_seg[VI];
   assign seg_in_valid = data_in_seg[0];
   //assign seg_in_tag = data_in_seg[TI];
   assign seg_in_row_idx = data_in_seg[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   assign seg_in_value = data_in_seg[DATA_WIDTH - `BITS_ROW_IDX - 1 : DATA_WIDTH - `BITS_ROW_IDX - `DATA_PRECISION];

   //assign seg_out_valid = data_out_seg[VI];
   assign seg_out_valid = data_out_seg[0];
   //assign seg_out_tag = data_out_seg[TI];
   assign seg_out_row_idx = data_out_seg[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   assign seg_out_value = data_out_seg[DATA_WIDTH - `BITS_ROW_IDX - 1 : DATA_WIDTH - `BITS_ROW_IDX - `DATA_PRECISION];   
   //=============================================================================

wire adv_rd_wr_addr_match_flag_so = rd_en_so_adv && wr_en_stg_adv && (adv_rd_addr_so == adv_wr_addr_stg_so) && (mode == `MODE_WORK);
wire adv_rd_wr_addr_match_flag_buff = rd_en_buff_adv && wr_en_stg_adv && (adv_rd_addr_buff == adv_wr_addr_stg) && (mode == `MODE_WORK);
wire rd_wr_addr_match_flag_buff, rd_wr_addr_match_flag_so;
   
register #(.WIDTH(1)) reg_match_flag_so(.q(rd_wr_addr_match_flag_so), .d(adv_rd_wr_addr_match_flag_so), .clk(clk), .enable(1'b1), .rst_b(rst_b)); 
register #(.WIDTH(1)) reg_match_flag_buff(.q(rd_wr_addr_match_flag_buff), .d(adv_rd_wr_addr_match_flag_buff), .clk(clk), .enable(1'b1), .rst_b(rst_b)); 

   wire [DATA_WIDTH - 1 : 0] dout_so_early, data_out_so;   
   segment_memory #(
     //.NUM_BUFF_SO_WORDS_SEG(NUM_BUFF_SO_WORDS_SEG), .NUM_BRICK_SEG_VER(NUM_BRICK_SEG_VER), .BITS_ADDR_SEG(BITS_ADDR_SEG), .BITS_ADDR_SEG_SO(BITS_ADDR_SEG_SO), .DEPTH_SO_Q(DEPTH_SO_Q), .BITS_SO_Q(BITS_SO_Q)) seg_mem_lim (//for lim
     .NUM_BUFF_SO_WORDS_SEG(NUM_BUFF_SO_WORDS_SEG), .NUM_BRICK_SEG_VER(NUM_BRICK_SEG_VER), .BITS_ADDR_SEG(BITS_ADDR_SEG), .BITS_ADDR_SEG_SO(BITS_ADDR_SEG_SO), .DEPTH_SO_Q(DEPTH_SO_Q), .BITS_SO_Q(BITS_SO_Q), .NUM_DUMMY_BITS(0)) seg_mem_fpga (//for bram	
     //input
     .rst_b, .clk, .mandatory_bubble_so, .mandatory_bubble_buff,
     .rd_en_so_adv, .rd_en_buff_adv, .wr_en_adv(wr_en_stg_adv),
     .adv_rd_wr_addr_match_flag_so, .rd_wr_addr_match_flag_so,
     .adv_rd_wr_addr_match_flag_buff, .rd_wr_addr_match_flag_buff,
     .adv_rd_addr_buff, .adv_rd_addr_so,
     .adv_wr_addr_buff(adv_wr_addr_stg), .adv_wr_addr_so(adv_wr_addr_stg_so), 
     .data_in_buff, .data_in_so,
     //output		 
     .dout_so_early(dout_so_early),
     .dout_buff(data_out_buff), .dout_so(data_out_so));

generate
   if(SEG0 == 0) begin
      assign data_out_seg = data_out_so;
   end
   else begin
      assign data_out_seg = dout_so_early;
   end
endgenerate

endmodule
