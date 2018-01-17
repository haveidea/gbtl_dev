//
//---------------------------------------------------------------------------
// intermediate buffer for big blocks of DRAM page+connects with memory interface   
// include the data compression and radix sorting in here. receive the data from dram, decompress it and
// put it in different bins using radix sort. use async fifo as the bin. Probably we should replace the input segment bins with this async fifo   
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module page_buffer
  #(//parameter
    SERIAL_SLOW_BLK = 0,
    NUM_UNITs = `NUM_UNITs,
    BITS_SERIAL_SLOW_BLK = `BITS_TOTAl_INPUTS - `BITS_INPUT_ADDR_SLOW_BLK,
    LDQ_BUFF_SIZE = `LDQ_BUFF_SIZE,
    LDQ_DATA_WIDTH = `LDQ_DATA_WIDTH,
    LDQ_BUFF_RATIO_2DATA = `LDQ_BUFF_RATIO_2DATA,
    BITS_LDQ_BUFF_PER_LIST = `BITS_LDQ_BUFF_PER_LIST, 
    BLK_WIDTH_INPUT = `BLK_WIDTH_INPUT,
    NUM_INPUTs_PER_SEG_ARR = `NUM_INPUTs_PER_SEG_ARR,
    BITS_INPUT_ADDR_SLOW_BLK = `BITS_INPUT_ADDR_SLOW_BLK,
    BITS_TOTAL_PAGE_BUFF = BITS_INPUT_ADDR_SLOW_BLK + BITS_LDQ_BUFF_PER_LIST,
    WORD_WIDTH_INPUT = `WORD_WIDTH_INPUT,
    BITS_ADDR_LD_REQ_Q = `BITS_ADDR_LD_REQ_Q,
    BITS_ADDR_FILL_SVC_Q = `BITS_ADDR_FILL_SVC_Q,
    ALL_CTR_LENGTH = `BITS_INPUT_BIN_ADDR + `BITS_INPUT_BIN_ADDR + `BITS_INPUT_BIN_ADDR + 1,
    ALL_CTR_LENGTH_ALL_UNIT = NUM_UNITs * ALL_CTR_LENGTH)
   (//LDQ signals
    input clk_ldq, clk_slow, rst_b, unit_en, mode, ldq_addr_ready, ldq_data_valid,
    input [LDQ_DATA_WIDTH - 1: 0] ldq_data,
    input rcv_fill_req, //wr_en_page_buff,
    input [BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] bin_to_fill_addr_blk_slow,
    input [`BITS_ROW_IDX - 1 : 0] maxidx_pb,
    input [NUM_UNITs - 1 : 0][`BITS_INPUT_BIN_ADDR - 1 : 0] set_rd_ctr_pb, set_wr_ctr_pb,
    input [NUM_UNITs - 1 : 0][`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_pb,

    output wr_en_blk_slow_input, fill_req_accept_ready,
    output [BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] wr_addr_blk_slow_input, //list_to_ld_addr_blk_slow,
    output logic [`BLK_SLOW_PARR_WR_NUM - 1 : 0][WORD_WIDTH_INPUT - 1 : 0] data_in_blk_slow, 
    output [`BITS_ROW_IDX - 1 : 0] maxidx_input,    
    output logic [`NUM_UNITs - 1 : 0] [`BITS_INPUT_BIN_ADDR - 1 : 0] set_rd_ctr_input, set_wr_ctr_input,
    output logic [`NUM_UNITs - 1 : 0] [`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_input,
    output [`BITS_TOTAl_INPUTS - 1 : 0] ldq_addr,
    output ldq_addr_valid, ldq_data_ready);

   wire global_en;
   assign global_en = (mode == `MODE_WORK) && unit_en; 

   // Buffer for page block of 2KB for each list and fill service
   //====================================================================================
   //----------------------------------------------------------
   // 2KB storage per list using asynchronous fifo (sram based)
   wire rd_en_page_buff, wr_en_page_buff;
   wire [NUM_INPUTs_PER_SEG_ARR - 1 : 0] winc, rinc, wfull, rempty;
   wire [NUM_INPUTs_PER_SEG_ARR - 1 : 0] [BITS_LDQ_BUFF_PER_LIST - 1 : 0] waddr, raddr;
   wire [LDQ_DATA_WIDTH - 1 : 0] di_page_buff, do_page_buff;  
   wire [BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] rd_addr_page_buff, wr_addr_page_buff;

   assign di_page_buff = ldq_data;
   assign wr_en_page_buff = ldq_data_ready && ldq_data_valid;
   assign winc = wr_en_page_buff ? 1 << wr_addr_page_buff : '0;
   assign rinc = rd_en_page_buff ? 1 << rd_addr_page_buff : '0;
  
   genvar j0;
   generate
      for (j0 = 0; j0 < NUM_INPUTs_PER_SEG_ARR; j0 = j0 + 1) begin : page_ptrs
	 afifo_ptr_only #(.ASIZE(BITS_LDQ_BUFF_PER_LIST)) afifo_ptr_only 
	   (//input
	    .winc(winc[j0]), .wclk(clk_ldq), .wrst_n(rst_b), .rinc(rinc[j0]), .rclk(clk_slow), .rrst_n(rst_b),
	    //output
	    .wfull(wfull[j0]), .rempty(rempty[j0]), .waddr(waddr[j0]), .raddr(raddr[j0]));
      end
   endgenerate

   wire [BITS_LDQ_BUFF_PER_LIST - 1 : 0] waddr_list, raddr_list;
   wire [BITS_TOTAL_PAGE_BUFF - 1 : 0] rd_addr_total_pb, wr_addr_total_pb;   
   wire wfull_total_pb, rempty_total_pb;

   assign waddr_list = waddr[wr_addr_page_buff];
   assign raddr_list = raddr[rd_addr_page_buff]; 
   assign wr_addr_total_pb = {wr_addr_page_buff, waddr_list};
   assign rd_addr_total_pb = {rd_addr_page_buff, raddr_list};
   assign wfull_total_pb = wfull[wr_addr_page_buff];
   assign rempty_total_pb = rempty[rd_addr_page_buff];

   wire wen_sram;
   assign wen_sram = wr_en_page_buff && !wfull_total_pb;
   
   //this stores the radix sorted data values
   fifomem_asyn_sram #(.DATASIZE(LDQ_DATA_WIDTH), .ADDRSIZE(BITS_TOTAL_PAGE_BUFF)) afifo_sram_pb
     (.rdata(do_page_buff), .wdata(di_page_buff),
      .waddr(wr_addr_total_pb), .raddr(rd_addr_total_pb),
      //.wclken(wr_en_page_buff), .wfull(wfull_total_pb), .rclken(rd_en_page_buff), .rempty(rempty_total_pb),
      .wen(wen_sram),
      .wclk(clk_ldq), .rclk(clk_slow));

   //this stores the maximum radix among the ldq data og 64B block
   fifomem_asyn_sram #(.DATASIZE(`BITS_ROW_IDX), .ADDRSIZE(BITS_TOTAL_PAGE_BUFF)) afifo_sram_pb_maxidx
     (.rdata(maxidx_input), .wdata(maxidx_pb),
      .waddr(wr_addr_total_pb), .raddr(rd_addr_total_pb),
      //.wclken(wr_en_page_buff), .wfull(wfull_total_pb), .rclken(rd_en_page_buff), .rempty(rempty_total_pb),
      .wen(wen_sram),
      .wclk(clk_ldq), .rclk(clk_slow));
  
   wire [ALL_CTR_LENGTH_ALL_UNIT - 1 : 0] di_ctrs_pb, do_ctrs_pb;
   //this stores the radix sorted counters
   fifomem_asyn_sram #(.DATASIZE(ALL_CTR_LENGTH_ALL_UNIT), .ADDRSIZE(BITS_TOTAL_PAGE_BUFF)) afifo_sram_pb_ctrs
     (.rdata(do_ctrs_pb), .wdata(di_ctrs_pb),
      .waddr(wr_addr_total_pb), .raddr(rd_addr_total_pb),
      //.wclken(wr_en_page_buff), .wfull(wfull_total_pb), .rclken(rd_en_page_buff),.rempty(rempty_total_pb),
      .wen(wen_sram),
      .wclk(clk_ldq), .rclk(clk_slow));
   //----------------------------------------------------------

   //----------------------------------------------------------  
   //Issuing fill service. We have a queue for fill services too. This is in slow clock domain.
  
   wire fill_svc_q_full, fill_svc_q_empty, fill_svc_q_wr_en, fill_svc_q_rd_en, ld_req_q_full;
   assign fill_svc_q_wr_en = global_en && !fill_svc_q_full && rcv_fill_req;
   ///assign fill_req_accepted = fill_svc_q_wr_en;
   assign fill_req_accept_ready = !fill_svc_q_full;
      
   sfifo #(.DSIZE(BITS_INPUT_ADDR_SLOW_BLK), .ASIZE(BITS_ADDR_FILL_SVC_Q)) fill_svc_q
     (//input
      .clk(clk_slow), .rst_b, .rd_en(fill_svc_q_rd_en), .wr_en(fill_svc_q_wr_en),
      .data_in(bin_to_fill_addr_blk_slow),
      //output
      .data_out(rd_addr_page_buff),
      .full(fill_svc_q_full), .empty(fill_svc_q_empty));

   assign fill_svc_q_rd_en = (global_en && !fill_svc_q_empty && !rempty_total_pb) && ((raddr_list != LDQ_BUFF_RATIO_2DATA - 1) || (raddr_list == LDQ_BUFF_RATIO_2DATA - 1 && !ld_req_q_full));
   assign rd_en_page_buff = fill_svc_q_rd_en;
   register #(.WIDTH(1)) reg_rd_en_page_buff(.q(wr_en_blk_slow_input), .d(rd_en_page_buff), .clk(clk_slow), .enable(global_en), .rst_b(rst_b));   
   register #(.WIDTH(BITS_INPUT_ADDR_SLOW_BLK)) reg_rd_addr_page_buff(.q(wr_addr_blk_slow_input), .d(rd_addr_page_buff), .clk(clk_slow), .enable(global_en), .rst_b(rst_b));
   //----------------------------------------------------------
   //====================================================================================

   //Load requests queue. Write with clk_slow, read with clk_ldq
   //====================================================================================
   //---------------------------------------------------------------------
   //load request queue storage
   wire [BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] list_to_ld_addr_blk_slow;
   wire ld_req_q_empty, ld_req_q_wr_en, ld_req_q_rd_en;
   wire cur_ld_req_history;
   wire ldq_rcv_history_full;
   wire send_ld_req;
         
   assign ld_req_q_wr_en = (global_en && !ld_req_q_full) && ((rd_en_page_buff && raddr_list == LDQ_BUFF_RATIO_2DATA - 1) || (rempty_total_pb && !fill_svc_q_empty)) && !cur_ld_req_history; //the reading of buffer will wait until ld_req_q_wr_en is 1 in a sense. so we don't have to check if ld_req_q is full when valid_cur_ptr is 0. But when valid_cur_ptr is 1, we have to check whether ld_req_q is not full in case we have to record a load request. We can skip ld_req_q checking while valid_cur_ptr is 1. In that case, the list request will be generated when the buffer is completely empty. However, this may cause more bubbles in the pipeline
   ///assign ld_req_q_rd_en = ld_req_accepted; 
   assign ld_req_q_rd_en = send_ld_req && ldq_addr_ready; 
   //assign send_ld_req = !ld_req_q_empty; //send_ld_req remains active until accepted
   assign send_ld_req = global_en && !ld_req_q_empty && !ldq_rcv_history_full;
   assign ldq_addr_valid = send_ld_req;
      
   afifo #(.DSIZE(BITS_INPUT_ADDR_SLOW_BLK), .ASIZE(BITS_ADDR_LD_REQ_Q)) ld_req_q
     (//input
     .wdata(rd_addr_page_buff), .winc(ld_req_q_wr_en), .wclk(clk_slow), .wrst_n(rst_b),
     .rinc(ld_req_q_rd_en), .rclk(clk_ldq), .rrst_n(rst_b),
     //output
     .rdata(list_to_ld_addr_blk_slow),
     .wfull(ld_req_q_full), .rempty(ld_req_q_empty));

   wire [BITS_SERIAL_SLOW_BLK - 1 : 0] serial_slow_blk;
   assign serial_slow_blk = SERIAL_SLOW_BLK;
   assign ldq_addr = {serial_slow_blk, list_to_ld_addr_blk_slow};
   //--------------------------------------------------------------------- 
   //---------------------------------------------------------------------
   // load request history for individual lists. Used to avoid multiple load requests for same list       
   logic [`NUM_INPUTs_PER_SEG_ARR - 1 : 0] ld_req_history;
   assign cur_ld_req_history = ld_req_history[rd_addr_page_buff];
        
   always_ff @ (posedge clk_slow) begin //ld_req_history is in clk_slow domain
      if(~rst_b) begin
	 for (integer i1 = 0; i1 < NUM_INPUTs_PER_SEG_ARR; i1 = i1 + 1) begin
	    ld_req_history[i1] <= '0;
	 end
      end
      else if (ld_req_q_wr_en) begin
	 ld_req_history[rd_addr_page_buff] <= 1'b1;
      end
      else if (fill_svc_q_rd_en && raddr_list == 0) begin
	 ld_req_history[rd_addr_page_buff] <= 1'b0;
      end     
   end // always_ff @
   /// we maintain the history of ldq request in clk_slow domain. So we have deasserted the flags when the first 64B block of the 2K is read (instead of when 2K data is written win clk_ldq domain)
   //---------------------------------------------------------------------
   //====================================================================================

   // LDQ receive data history. This is totally in clk_ldq domain
   //====================================================================================
   wire ldq_rcv_history_empty, rd_en_ldq_rcv_history;
   logic [BITS_LDQ_BUFF_PER_LIST - 1 : 0] ld_data_ctr;
   assign rd_en_ldq_rcv_history =  wr_en_page_buff && (ld_data_ctr == LDQ_BUFF_RATIO_2DATA - 1);
   
   sfifo #(.DSIZE(BITS_INPUT_ADDR_SLOW_BLK), .ASIZE(`BITS_LDQ_DEPTH)) ldq_rcv_history
     (//input
      .clk(clk_ldq), .rst_b, .rd_en(rd_en_ldq_rcv_history), .wr_en(ld_req_q_rd_en),
      .data_in(list_to_ld_addr_blk_slow),
      //output
      .data_out(wr_addr_page_buff),
      .full(ldq_rcv_history_full), .empty(ldq_rcv_history_empty));

   //counter to track ld data blocks as they are smaller than page_buff
   always_ff @ (posedge clk_ldq) begin
      if(~rst_b) begin
	 ld_data_ctr <= '0;
      end
      else if (wr_en_page_buff) begin
	 ld_data_ctr <= ld_data_ctr + 1'b1;
      end
   end   

   assign ldq_data_ready = global_en && !ldq_rcv_history_empty;
   //====================================================================================
   
   //====================================================================================
   //separating the input words        
   genvar j1;
   generate
      for (j1 = 0; j1 < `BLK_SLOW_PARR_WR_NUM; j1 = j1 + 1) begin
	 assign data_in_blk_slow[j1] = do_page_buff[BLK_WIDTH_INPUT - WORD_WIDTH_INPUT*j1 - 1 : BLK_WIDTH_INPUT - WORD_WIDTH_INPUT*(j1 + 1)]; //notice that the MSB is the data for lower address (smaller index)
      end
   endgenerate

   //separating the input counters
   wire [NUM_UNITs - 1 : 0][ALL_CTR_LENGTH - 1 : 0] ctr_set;
   generate
      for (j1 = 0; j1 < `NUM_UNITs; j1 = j1 + 1) begin

	 assign di_ctrs_pb[ALL_CTR_LENGTH_ALL_UNIT - ALL_CTR_LENGTH*j1 - 1 : ALL_CTR_LENGTH_ALL_UNIT - ALL_CTR_LENGTH*(j1 + 1)] = {set_rd_ctr_pb[j1], set_wr_ctr_pb[j1], set_track_ctr_pb[j1]};

	 assign ctr_set[j1] = do_ctrs_pb[ALL_CTR_LENGTH_ALL_UNIT - ALL_CTR_LENGTH*j1 - 1 : ALL_CTR_LENGTH_ALL_UNIT - ALL_CTR_LENGTH*(j1 + 1)];

	 assign set_rd_ctr_input[j1] = ctr_set[j1][ALL_CTR_LENGTH - 1 : ALL_CTR_LENGTH - `BITS_INPUT_BIN_ADDR];
	 assign set_wr_ctr_input[j1] = ctr_set[j1][ALL_CTR_LENGTH - `BITS_INPUT_BIN_ADDR - 1 : ALL_CTR_LENGTH - 2*`BITS_INPUT_BIN_ADDR];
	 assign set_track_ctr_input[j1] = ctr_set[j1][`BITS_INPUT_BIN_ADDR : 0];
      end
   endgenerate

   /*
   //get rid of this later 
   always_comb begin      
      for (integer i1 = 0; i1 < `NUM_UNITs; i1 = i1 + 1) begin
   	 set_rd_ctr_input[i1] = '0;
	 set_wr_ctr_input[i1] = '0;
	 set_track_ctr_input[i1] = `BLK_SLOW_PARR_WR_NUM;
      end
   end
   */    
   //====================================================================================
   
endmodule   
