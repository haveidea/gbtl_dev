//
//---------------------------------------------------------------------------
// Accumulator block. Includes all accumulator stages.   
//
//  
//---------------------------------------------------------------------------
//
//
// SpMV Definitions: Numerical parameters of the SpMV core
// 
// 

//---------------------------Not regular design parameter-------------------------------
//**************************************************************************************
`define DATA_PRECISION 32
`define SIG_WIDTH 23
`define EXP_WIDTH 8
`define IEEE_COMPLIANCE 0
`define ISIGN 1
`define INST_FAITHFUL_ROUND 0
`define STATUS_WIDTH 8
`define RND_WIDTH 3
`define RND_NEAREST 0
`define RND_UP 2
`define RND_DOWN 3
`define NUM_STG_ADDER_PIPE 2
`define NUM_FP_ADDER_PER_UNIT 4
`define NUM_PARALLEL_ADDER 4
`define BITS_ADDER_SELECT_CTR 2
`define BITS_ROW_IDX 32
`define BITS_VALID_DATA 1
`define BITS_INPUT_TAG 1
`define MODE_POPULATE_ZERO 0
`define MODE_WORK 1
`define LIM_BRICK_WORD_SIZE 32
`define LIM_BRICK_WORD_NUM 32
`define BITS_ADDR_LIM_BRICK 5
`define INPUT_ELE_WIDTH_MATLAB 64
`define TOT_IN_WIDTH 32768
`define BITS_TOT_IN_WIDTH 15
`define TOT_IN_WIDTH_RATIO_2DATA 64
`define BITS_IN_CTR_PER_LIST 6
//**************************************************************************************

//-------------------------------Regular design parameter------------------------------
//**************************************************************************************
`define INPUT_BIN_SIZE 8
`define BITS_INPUT_BIN_ADDR 3
`define NUM_INPUTs 512
`define BITS_TOTAl_INPUTS 9
`define NUM_SEG_PER_STG 4
`define NUM_INPUTs_PER_SEG_ARR 128
`define BITS_RADIX_SORT 3
`define NUM_UNITs 8
`define BITS_UNIT_SELECTION 3
`define UNIT_INIT_BIT 29
`define NUM_STGs 9
`define BITS_ADDR_UNIT 9
`define END_OF_FAST_STG 2
`define START_OF_BIG_STG 7
`define DATA_WIDTH_BUFF_SO_SEG 65
`define TAG_INDEX_DATA_BUFF_SO_SEG 0
`define VALID_INDEX_DATA_BUFF_SO_SEG 1
`define DATA_WIDTH_INPUT 64
`define WORD_WIDTH_INPUT 64
`define NUM_BRICK_SEG_HOR 3
`define NUM_DUMMY_BITS_SEG_MEM 31
`define NUM_BRICK_SEG_HOR_INPUT 2
`define NUM_DUMMY_BITS_SEG_MEM_INPUT 0
`define BITS_INPUT_ADDR_SLOW_BLK 7
`define SLOW_BLK_BUFF_SIZE 8
`define BITS_SLOW_BLK_BUFF_ADDR 3
`define CLK_DIV_RATIO 2
`define DIV_RATIO_HALF 1
`define BITS_DIV_RATIO_HALF 0
`define DATA_WIDTH_ADD_STG 65
`define BITS_BLK_FAST_OUT_Q 3
`define BITS_BLK_FAST_FIFO 3
`define BITS_ADDER_OUT_Q 3
`define NUM_ACCUM_STG 1
`define INITIALIZE_SEG_ADDR_WIDTH 7
//**************************************************************************************

//--------------------------Load Store queue parameters---------------------------
//**************************************************************************************
`define DRAM_ADDR_WIDTH 32
`define LOAD_ADDR_WIDTH 21
`define LOAD_ADDR_ALIGNMENT_WIDTH 11
`define STORE_ADDR_WIDTH 21
`define STORE_ADDR_ALIGNMENT_WIDTH 11
`define LDQ_DEPTH 16
`define BITS_LDQ_DEPTH 4
`define STQ_DEPTH 16
`define BITS_STQ_DEPTH 4
`define LDQ_DATA_WIDTH 512
`define STQ_DATA_WIDTH 256
`define LDQ_BUFF_SIZE 16384
`define STQ_BUFF_SIZE 32768
`define LDQ_BUFF_RATIO_2DATA 32
`define BITS_LDQ_BUFF_PER_LIST 5
`define STQ_BUFF_RATIO_2DATA 128
`define BITS_STQ_BUFF_PER_UNIT 7
`define STQ_BUFF_MIN_RATIO_2DATA 64
`define BLK_WIDTH_INPUT 512
`define BLK_SLOW_PARR_WR_NUM 8
`define INPUT_BLK_RATIO_2WORD 8
`define BITS_ADDR_LD_REQ_Q 4
`define BITS_ADDR_FILL_SVC_Q 4
`define BITS_ADDR_FILL_REQ_Q 7
//**************************************************************************************

//--------------------------Data output Scan-chain parameters---------------------------
//**************************************************************************************
`define NUM_OUTPUT_WORDS_PER_UNIT 16
`define BITS_OUTPUT_ADDR_PER_UNIT 4
//**************************************************************************************

//------------------These should be inhereted parameters in the modules-----------------
//**************************************************************************************
`define NUM_BRICK_SEG_VER 16
`define NUM_BUFF_SO_WORDS_SEG 512
`define BITS_ADDR_SEG 9
//**************************************************************************************

//-------------------------Radix Sort parameters----------------------------------------
//**************************************************************************************
`define STREAM_WIDTH 8
`define LOG_STREAM_WIDTH 3
`define NUM_BIOTONIC_STGS_TOT 6
//**************************************************************************************



module accum_blk 
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_ADD_STG,
    BITS_ROW_IDX = `BITS_ROW_IDX,
    BITS_ADDER_OUT_Q = `BITS_ADDER_OUT_Q,
    NUM_ACCUM_STG = `NUM_ACCUM_STG) 
   (//input
    input clk, rst_b, unit_en, mode, data_ended,
    input [DATA_WIDTH - 1 : 0] di,
    
    //handshaking signals
    input prev_blk_rd_ready, next_blk_rd_en,
    output en_blk, out_q_rd_ready, 
    
    //output
    output [DATA_WIDTH - 1 : 0] do_accum_blk_out_q);

   ////assign en_blk = en_stg;
   wire en_global;
   assign en_global = (mode == `MODE_WORK && unit_en);

   
   //Accumulator stages including special last edge
   //=========================================================================================
   wire [NUM_ACCUM_STG : 0] [DATA_WIDTH - 1 : 0] di_stg;
   wire [NUM_ACCUM_STG : 0] prev_stg_rd_ready; 
   wire [NUM_ACCUM_STG : 0] en_stg;
   
   wire [DATA_WIDTH - 1 : 0] do_accum_stg_out_q_last;
   wire out_q_rd_ready_last; 
   wire en_stg_last;

   assign prev_stg_rd_ready[0] = prev_blk_rd_ready;
   assign en_stg[NUM_ACCUM_STG] = en_stg_last; 
   assign en_blk = en_stg[0];
   assign out_q_rd_ready = out_q_rd_ready_last;

   assign di_stg[0] = di; 
   assign do_accum_blk_out_q = do_accum_stg_out_q_last; //original
   //assign do_accum_blk_out_q = di_stg[1];///temp
   
genvar j0;
generate  
for (j0 = 0; j0 < NUM_ACCUM_STG; j0 = j0 + 1) begin    
   accum_stg #(.DATA_WIDTH(DATA_WIDTH), .BITS_ROW_IDX(BITS_ROW_IDX), .BITS_ADDER_OUT_Q(BITS_ADDER_OUT_Q)) accum_stg
     (//input
      .clk, .rst_b, .en_global, .data_ended, .di(di_stg[j0]),
      //handshaking signals
      .prev_stg_rd_ready(prev_stg_rd_ready[j0]),
      //.next_stg_rd_en(prev_stg_rd_ready[j0+1]),//for debug
      .next_stg_rd_en(en_stg[j0+1]),
      .en_stg(en_stg[j0]), .out_q_rd_ready(prev_stg_rd_ready[j0+1]),
      //output
      .do_accum_stg_out_q(di_stg[j0+1]));
end 
endgenerate

   //assign en_stg_last = prev_stg_rd_ready[NUM_ACCUM_STG];//temp. for debug

   //temp. just for debug
   integer i0;
   assign i0 = 1;
   wire    blk_fast_out_valid;
   wire [`BITS_ROW_IDX - 1 : 0] blk_fast_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] blk_fast_out_value;      
   assign blk_fast_out_valid = di_stg[1][0];
   assign blk_fast_out_row_idx = di_stg[1][`DATA_WIDTH_ADD_STG - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX];
   assign blk_fast_out_value = di_stg[1][`DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - `DATA_PRECISION];
   

   //Last Accumulator Stage
   accum_stg_last #(.DATA_WIDTH(DATA_WIDTH), .BITS_ROW_IDX(BITS_ROW_IDX), .BITS_ADDER_OUT_Q(BITS_ADDER_OUT_Q)) accum_stg_last
     (//input
      .clk, .rst_b, .en_global, .data_ended, .di(di_stg[NUM_ACCUM_STG]),
      //handshaking signals
      .prev_stg_rd_ready(prev_stg_rd_ready[NUM_ACCUM_STG]), .next_stg_rd_en(next_blk_rd_en),
      .en_stg(en_stg_last), .out_q_rd_ready(out_q_rd_ready_last),
      //output
      .do_accum_stg_out_q(do_accum_stg_out_q_last));
 
   //=========================================================================================

   /*
   //Accumulator stages without last stage
   //=========================================================================================
   wire [NUM_ACCUM_STG : 0] [DATA_WIDTH - 1 : 0] di_stg;
   wire [NUM_ACCUM_STG : 0] prev_stg_rd_ready; 
   wire [NUM_ACCUM_STG : 0] en_stg;
   
   //handshaking signals
   assign prev_stg_rd_ready[0] = prev_blk_rd_ready;
   assign en_stg[NUM_ACCUM_STG] = next_blk_rd_en;
   assign en_blk = en_stg[0];
   assign out_q_rd_ready = prev_stg_rd_ready[NUM_ACCUM_STG];

   assign di_stg[0] = di;
   assign do_accum_blk_out_q = di_stg[NUM_ACCUM_STG];
  
genvar j0;
generate  
for (j0 = 0; j0 < NUM_ACCUM_STG; j0 = j0 + 1) begin    
   accum_stg #(.DATA_WIDTH(DATA_WIDTH), .BITS_ROW_IDX(BITS_ROW_IDX), .BITS_ADDER_OUT_Q(BITS_ADDER_OUT_Q)) accum_stg
     (//input
      .clk, .rst_b, .en_global, .data_ended, .di(di_stg[j0]),
      //handshaking signals
      .prev_stg_rd_ready(prev_stg_rd_ready[j0]), .next_stg_rd_en(en_stg[j0+1]),
      .en_stg(en_stg[j0]), .out_q_rd_ready(prev_stg_rd_ready[j0+1]),
      //output
      .do_accum_stg_out_q(di_stg[j0+1]));
end 
endgenerate
   //=========================================================================================
   */
      
endmodule // accum_blk
//
//---------------------------------------------------------------------------
// Accumulator stage last   
//
//  
//---------------------------------------------------------------------------
//

module accum_stg_last 
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_ADD_STG,
    BITS_ROW_IDX = `BITS_ROW_IDX,
    BITS_ADDER_OUT_Q = `BITS_ADDER_OUT_Q) 
   (//input
    input clk, rst_b, en_global, data_ended, 
    input [DATA_WIDTH - 1 : 0] di,
			
    //handshaking signals
    input prev_stg_rd_ready, next_stg_rd_en,
    output en_stg, out_q_rd_ready,
  
   //output 
    output [DATA_WIDTH - 1 : 0] do_accum_stg_out_q);

   //---------------Last stage additional signals before adder-----------------
   wire [BITS_ROW_IDX - 1 : 0] issued_row_idx_last;
   wire issued_valid_last;
   wire sth_issued;
   wire halt_conflict, conflict_add_issue;
      
   wire [BITS_ROW_IDX - 1 : 0] add_out_row_idx_last;
   wire add_out_valid_last;   
   wire [`DATA_PRECISION - 1 : 0] add_out_value_last; 
   wire [DATA_WIDTH - 1 : 0] do_accum_stg_last;
   //--------------------------------------------------------------------------

   wire out_q_wr_ready, move_pipe_okay, no_halt;
   ///assign en_stg = move_pipe_okay && no_halt;
   ///assign move_pipe_okay = en_global && prev_stg_rd_ready && out_q_wr_ready;
   assign no_halt = !halt_conflict;
   
   assign en_stg = prev_stg_rd_ready && move_pipe_okay && no_halt; //en_stg means whether data should get inside this stage
   assign move_pipe_okay = en_global && out_q_wr_ready; //move_pipe_okay means whether the adder pipeline should move forward
         
   //Adder input and activation
   //=========================================================================================
   wire str0_issue, str1_issue, add_issue, bypass_issue;
   wire valid_di, valid_storage0, valid_storage1, adder_in_valid;   
   wire [BITS_ROW_IDX - 1 : 0] row_idx_storage0, row_idx_storage1, adder_in_row_idx;
   wire [`DATA_PRECISION - 1 : 0] value_storage0, value_storage1, adder_in0_value, adder_in1_value;
   logic [DATA_WIDTH - 1 : 0] storage0, storage1, storage0_input, storage1_input;
   
   assign valid_di = di[0];          
   assign valid_storage0 = storage0[0];
   assign valid_storage1 = storage1[0];
   assign row_idx_storage0 = storage0[DATA_WIDTH - 1 : DATA_WIDTH - BITS_ROW_IDX];
   assign row_idx_storage1 = storage1[DATA_WIDTH - 1 : DATA_WIDTH - BITS_ROW_IDX];
   assign value_storage0 = storage0[DATA_WIDTH - BITS_ROW_IDX - 1 : DATA_WIDTH - BITS_ROW_IDX - `DATA_PRECISION];
   assign value_storage1 = storage1[DATA_WIDTH - BITS_ROW_IDX - 1 : DATA_WIDTH - BITS_ROW_IDX - `DATA_PRECISION];

   assign halt_conflict = (valid_storage0 && issued_valid_last) && (row_idx_storage0 == issued_row_idx_last) && (!add_out_valid_last || (add_out_valid_last && (issued_row_idx_last != add_out_row_idx_last)));      
   assign conflict_add_issue = en_stg && (valid_storage0 && issued_valid_last && add_out_valid_last) && (row_idx_storage0 == issued_row_idx_last) && (issued_row_idx_last == add_out_row_idx_last);

   assign sth_issued = add_issue || bypass_issue || conflict_add_issue;

   assign add_issue = en_stg && valid_storage0 && valid_storage1 && (row_idx_storage0 == row_idx_storage1);
   assign bypass_issue = en_stg && valid_storage1 && valid_storage0 && (row_idx_storage0 != row_idx_storage1);

   assign str0_issue = en_stg && (valid_di || add_issue || conflict_add_issue);
   assign storage0_input = (en_stg && valid_di) ? di : (add_issue || conflict_add_issue? '0 : storage0);

   assign str1_issue = en_stg && (add_issue || (str0_issue && valid_storage0) || bypass_issue);
   assign storage1_input = (add_issue || conflict_add_issue)? '0 : (str0_issue && valid_storage0)? storage0 : bypass_issue? '0 : storage1;
   
   register #(.WIDTH(DATA_WIDTH)) reg_storage0(.q(storage0), .d(storage0_input), .clk(clk), .enable(str0_issue), .rst_b(rst_b));
   register #(.WIDTH(DATA_WIDTH)) reg_storage1(.q(storage1), .d(storage1_input), .clk(clk), .enable(str1_issue), .rst_b(rst_b));

   assign adder_in_valid = (conflict_add_issue || add_issue)? valid_storage0 : bypass_issue? valid_storage1 : 0;
   assign adder_in_row_idx = (conflict_add_issue || add_issue)? row_idx_storage0 : bypass_issue ? row_idx_storage1 : '0;
   assign adder_in0_value = (conflict_add_issue || add_issue) ? value_storage0 : '0;
   assign adder_in1_value = conflict_add_issue? add_out_value_last : (add_issue || bypass_issue) ? value_storage1 : '0;
      
   register #(.WIDTH(BITS_ROW_IDX)) reg_issued_row_idx_last(.q(issued_row_idx_last), .d(adder_in_row_idx), .clk(clk), .enable(sth_issued), .rst_b(rst_b));
   register #(.WIDTH(1)) reg_issued_valid_last(.q(issued_valid_last), .d(adder_in_valid), .clk(clk), .enable(sth_issued), .rst_b(rst_b)); 
   
   //Note: if invalid data comes when en_stg=1, the adder will pass the data in storage1. This is probably not ideal. For only one adder stage this might not be a big problem. But for multiple adder stages, we should not pass the data in storage1 just because new invalid data came in. We can control it by putiing more logic with add_en in the upper level of hierarchy.
   //=========================================================================================

   // Adder stage
   //================================================================================   
   wire data_valid;   
   wire [BITS_ROW_IDX - 1 : 0] data_row_idx;
   assign data_valid = adder_in_valid;
   assign data_row_idx = adder_in_row_idx;
      
   wire add_out_valid;   
   wire [BITS_ROW_IDX - 1 : 0] add_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] add_out_value;
   wire [DATA_WIDTH - 1 : 0] do_accum_stg;
       
   adder_pipe_w_ctrl add_pipe
     (//input
      .clk, .rst_b,
      .adder_select(1'b1), .ena(move_pipe_okay), 
      .data_in0(adder_in0_value), .data_in1(adder_in1_value), 
      .data_valid, .data_row_idx,
      //output
      .data_valid_reg(add_out_valid), .data_row_idx_reg(add_out_row_idx),
      .add_result(add_out_value));
   
   assign do_accum_stg = {add_out_row_idx, add_out_value, add_out_valid};
   //================================================================================

   // Last stage additional signals after adder
   //================================================================================
   wire str_add_out, release_last;
   //assign str_add_out = (move_pipe_okay && add_out_valid) || (release_last && no_halt && move_pipe_okay) || (conflict_add_issue && move_pipe_okay);
   assign str_add_out = (move_pipe_okay && add_out_valid) || release_last || conflict_add_issue;
   ///assign release_last = en_stg && (issued_row_idx_last != add_out_row_idx_last) && !conflict_add_issue;   
   assign release_last = move_pipe_okay && (issued_row_idx_last != add_out_row_idx_last) && !conflict_add_issue;
   

   wire input_add_out_valid_last;   
   wire [BITS_ROW_IDX - 1 : 0] input_add_out_row_idx_last;
   wire [`DATA_PRECISION - 1 : 0] input_add_out_value_last;

  assign input_add_out_valid_last = conflict_add_issue ? '0 : add_out_valid;//ori
  assign input_add_out_row_idx_last = conflict_add_issue ? '0 : add_out_row_idx;
  assign input_add_out_value_last = conflict_add_issue ? '0 : add_out_value;
  // assign input_add_out_valid_last = add_out_valid;//debug
  // assign input_add_out_row_idx_last = add_out_row_idx;
  // assign input_add_out_value_last = add_out_value;

   
   register #(.WIDTH(BITS_ROW_IDX)) reg_add_out_row_idx_last(.q(add_out_row_idx_last), .d(input_add_out_row_idx_last), .clk(clk), .enable(str_add_out), .rst_b(rst_b));
   register #(.WIDTH(1)) reg_add_out_valid_last(.q(add_out_valid_last), .d(input_add_out_valid_last), .clk(clk), .enable(str_add_out), .rst_b(rst_b));//ori
   //register #(.WIDTH(1)) reg_add_out_valid_last(.q(add_out_valid_last), .d(input_add_out_valid_last), .clk(clk), .enable(1'b1), .rst_b(rst_b));//debug
   
   register #(.WIDTH(`DATA_PRECISION)) reg_add_out_value_last(.q(add_out_value_last), .d(input_add_out_value_last), .clk(clk), .enable(str_add_out), .rst_b(rst_b));

   assign do_accum_stg_last = {add_out_row_idx_last, add_out_value_last, add_out_valid_last};
   //================================================================================
 
   // Output Fifo for Adder Stage
   //=========================================================================================
   wire fifo_full, fifo_empty, rd_en_q, wr_en_q;
   assign out_q_wr_ready = !fifo_full;
   assign out_q_rd_ready = !fifo_empty;
   ///assign rd_en_q = next_stg_rd_en;
   assign rd_en_q = next_stg_rd_en && !fifo_empty;
   assign wr_en_q = release_last && add_out_valid_last;
      
   sfifo #(.DSIZE(DATA_WIDTH), .ASIZE(BITS_ADDER_OUT_Q)) fifo_fast_out
     (//input
      .clk, .rst_b, .rd_en(rd_en_q), .wr_en(wr_en_q),
      .data_in(do_accum_stg_last),
      //output
      .data_out(do_accum_stg_out_q),
      .full(fifo_full), .empty(fifo_empty));
   //=========================================================================================
     

endmodule // accum_stg_last
//
//---------------------------------------------------------------------------
// Accumulator stage   
//
//  
//---------------------------------------------------------------------------
//

module accum_stg 
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_ADD_STG,
    BITS_ROW_IDX = `BITS_ROW_IDX,
    BITS_ADDER_OUT_Q = `BITS_ADDER_OUT_Q) 
   (//input
    input clk, rst_b, en_global, data_ended, 
    input [DATA_WIDTH - 1 : 0] di,
			
    //handshaking signals
    input prev_stg_rd_ready, next_stg_rd_en,
    output en_stg, out_q_rd_ready,
  
    //output 
    output [DATA_WIDTH - 1 : 0] do_accum_stg_out_q);

   wire out_q_wr_ready;
   assign en_stg = en_global && prev_stg_rd_ready && out_q_wr_ready;
   
   //-------------------------Adder input and activation-----------------------
   wire str0_issue, str1_issue, add_issue, bypass_issue;
   wire valid_di, valid_storage0, valid_storage1;   
   wire [BITS_ROW_IDX - 1 : 0] row_idx_storage0, row_idx_storage1;
   wire [`DATA_PRECISION - 1 : 0] value_storage0, value_storage1, adder_in0, adder_in1;
   logic [DATA_WIDTH - 1 : 0] 	  storage0, storage1, storage0_input, storage1_input;
   
   assign valid_di = di[0];          
   assign valid_storage0 = storage0[0];
   assign valid_storage1 = storage1[0];
   assign row_idx_storage0 = storage0[DATA_WIDTH - 1 : DATA_WIDTH - BITS_ROW_IDX];
   assign row_idx_storage1 = storage1[DATA_WIDTH - 1 : DATA_WIDTH - BITS_ROW_IDX];
   assign value_storage0 = storage0[DATA_WIDTH - BITS_ROW_IDX - 1 : DATA_WIDTH - BITS_ROW_IDX - `DATA_PRECISION];
   assign value_storage1 = storage1[DATA_WIDTH - BITS_ROW_IDX - 1 : DATA_WIDTH - BITS_ROW_IDX - `DATA_PRECISION];
   
   assign add_issue = en_stg && valid_storage0 && valid_storage1 && (row_idx_storage0 == row_idx_storage1);
   assign bypass_issue = en_stg && valid_storage1 && valid_storage0 && (row_idx_storage0 != row_idx_storage1);

   assign str0_issue = (en_stg && valid_di) || add_issue;
   assign storage0_input = (en_stg && valid_di) ? di : (add_issue ? '0 : storage0);

   assign str1_issue = add_issue || (str0_issue && valid_storage0) || bypass_issue;
   assign storage1_input = add_issue? '0 : (str0_issue && valid_storage0)? storage0 : bypass_issue? '0 : storage1;
   
   register #(.WIDTH(DATA_WIDTH)) reg_storage0(.q(storage0), .d(storage0_input), .clk(clk), .enable(str0_issue), .rst_b(rst_b));
   register #(.WIDTH(DATA_WIDTH)) reg_storage1(.q(storage1), .d(storage1_input), .clk(clk), .enable(str1_issue), .rst_b(rst_b));
      
   assign adder_in0 = add_issue ? value_storage0 : '0;
   assign adder_in1 = (add_issue || bypass_issue) ? value_storage1 : '0;
      
   //Note: if invalid data comes when en_stg=1, the adder will pass the data in storage1. This is probably not ideal. For only one adder stage this might not be a big problem. But for multiple adder stages, we should not pass the data in storage1 just because new invalid data came in. We can control it by putiing more logic with add_en in the upper level of hierarchy.
   //----------------------------------------------------------------------------

/*   
   //Round Robin adder signals
   //---------------------------------------------------------------------------- 
   wire data_valid;   
   wire [BITS_ROW_IDX - 1 : 0] data_row_idx;
   wire [`DATA_PRECISION - 1 : 0] data_value;
   
   assign data_valid = valid_storage1;
   assign data_row_idx = row_idx_storage1;
   //assign data_value = value_storage1;

   wire add_out_valid;   
   wire [BITS_ROW_IDX - 1 : 0] add_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] add_out_value;
   wire [`STATUS_WIDTH - 1 : 0] add_status;

   assign data_out_add_stg = {add_out_row_idx, add_out_value, add_out_valid};

   wire [`NUM_RR_ADDER - 1 :0] add_out_valid_arr;   
   wire [`NUM_RR_ADDER - 1 :0] [BITS_ROW_IDX - 1 : 0] add_out_row_idx_arr;
   wire [`NUM_RR_ADDER - 1 :0] [`DATA_PRECISION - 1 : 0] add_out_value_arr;
   wire [`NUM_RR_ADDER - 1 :0] [`STATUS_WIDTH - 1 : 0] add_status_arr;

   logic [`BITS_RR_ADD_SELECT_CTR - 1 :0] adder_select_ctr;
   logic [`NUM_RR_ADDER - 1 : 0] adder_select;

   wire	add_en_enhanced;
   assign add_en_enhanced = add_en && (add_issue || bypass_issue);
     
   assign adder_select = add_en_enhanced ? 1 << adder_select_ctr : 0;  
   
   integer i0;
   always_ff @ (posedge clk) begin
      if(~rst_b || (adder_select_ctr == `NUM_RR_ADDER - 1 && add_en_enhanced)) begin
	 adder_select_ctr <= '0;
      end
      else if (add_en_enhanced && adder_select_ctr < `NUM_RR_ADDER - 1) begin
         adder_select_ctr <= adder_select_ctr + 1;
      end
   end 

   assign add_out_valid = add_out_valid_arr[adder_select_ctr] & add_en_enhanced;
   assign add_out_row_idx = add_out_row_idx_arr[adder_select_ctr];
   assign add_out_value = add_out_value_arr[adder_select_ctr];
   assign add_status = add_status_arr[adder_select_ctr];

   genvar j0;
   generate
      for (j0 = 0; j0 < `NUM_RR_ADDER; j0 = j0 + 1) begin : add_rr
					    
	 adder_single adder
	   (//input
	    .clk, .rst_b, .adder_select(adder_select[j0]), 
	    .data_in0(adder_in0), .data_in1(adder_in1), 
	    .data_valid, .data_row_idx,
	    //output
	    .data_valid_reg(add_out_valid_arr[j0]), .data_row_idx_reg(add_out_row_idx_arr[j0]),
	    .z_inst(add_out_value_arr[j0]), .status(add_status_arr[j0]));
      end
   endgenerate
   //----------------------------------------------------------------------------  
*/
   // Adder stage
   //================================================================================   
   wire data_valid;   
   wire [BITS_ROW_IDX - 1 : 0] data_row_idx;
   assign data_valid = (add_issue || bypass_issue) ? valid_storage1 : 0;
   assign data_row_idx = (add_issue || bypass_issue) ? row_idx_storage1 : '0;
   
   wire add_en_enhanced;
   assign add_en_enhanced = add_issue || bypass_issue;

   wire add_out_valid;   
   wire [BITS_ROW_IDX - 1 : 0] add_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] add_out_value;
   wire [DATA_WIDTH - 1 : 0] do_accum_stg;
       
   //adder_comb_w_ctrl add_comb
   adder_pipe_w_ctrl add_pipe  
     (//input
      .clk, .rst_b,
      .adder_select(1'b1), .ena(en_stg), //we want to activate addition at every cycle output is sampled 
      .data_in0(adder_in0), .data_in1(adder_in1), 
      .data_valid, .data_row_idx,
      //output
      .data_valid_reg(add_out_valid), .data_row_idx_reg(add_out_row_idx),
      .add_result(add_out_value));
   
   assign do_accum_stg = {add_out_row_idx, add_out_value, add_out_valid};
   //================================================================================

   // Output Fifo for Adder Stage
   //=========================================================================================
   wire fifo_full, fifo_empty, rd_en_q, wr_en_q;
   //wire [DATA_WIDTH - 1 : 0] do_accum_stg_out_q_temp;
   assign out_q_wr_ready = !fifo_full;
   assign out_q_rd_ready = !fifo_empty;
   assign rd_en_q = next_stg_rd_en; //original
   //assign rd_en_q = !fifo_empty; //temp
   assign wr_en_q = add_out_valid && en_stg;
      
   sfifo #(.DSIZE(DATA_WIDTH), .ASIZE(BITS_ADDER_OUT_Q)) fifo_fast_out
     (//input
      .clk, .rst_b, .rd_en(rd_en_q), .wr_en(wr_en_q),
      .data_in(do_accum_stg),
      //output
      .data_out(do_accum_stg_out_q),
      .full(fifo_full), .empty(fifo_empty));      
   //=========================================================================================

   //debug only
   wire q_out_valid;   
   wire [BITS_ROW_IDX - 1 : 0] q_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] q_out_value;
   assign q_out_valid = do_accum_stg_out_q[0] && !fifo_empty;
   assign q_out_row_idx = do_accum_stg_out_q[`DATA_WIDTH_ADD_STG - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX];
   assign q_out_value = do_accum_stg_out_q[`DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - `DATA_PRECISION];

   
   
endmodule // accum_stg
//
//---------------------------------------------------------------------------
// Pipelined adder   
//
//  
//---------------------------------------------------------------------------
//

module adder_pipe_w_ctrl
  #(
    parameter
    NUM_STG_ADDER_PIPE = `NUM_STG_ADDER_PIPE)
   (
    input clk, rst_b, adder_select, ena,
    input [`DATA_PRECISION - 1 : 0] data_in0, data_in1,
    input data_valid,
    input [`BITS_ROW_IDX - 1 : 0] data_row_idx,
    
    output logic data_valid_reg,
    output logic [`BITS_ROW_IDX - 1 : 0] data_row_idx_reg,
    output [`DATA_PRECISION - 1 : 0] add_result);

   //logic [`DATA_PRECISION - 1 : 0] data_in0_reg, data_in1_reg;
   logic [1 : 0] 		   aclr;
   assign aclr = rst_b ? 2'b00 : 2'b11;
        
   single_adder_pipe3 adder_bb(
      .aclr(aclr),		 
      //.ax(data_in0_reg),
      //.ay(data_in1_reg),
      .ax(data_in0),
      .ay(data_in1),
      .clk(clk), .ena(ena),			       
      .result(add_result));
   
   logic [NUM_STG_ADDER_PIPE : 0] [`BITS_ROW_IDX - 1 : 0] row_idx_internal;
   logic [NUM_STG_ADDER_PIPE : 0] [1 : 0] valid_internal;//actually need 1 dimensional array. but single dimension creates error in simulation because of two always block assignment. 
   
   always_ff @ (posedge clk) begin
      if(!rst_b) begin
	 //ena <= 0;
	 //data_in0_reg <= '0;
	 //data_in1_reg <= '0;
	 valid_internal[0] <= '0;
	 row_idx_internal[0] <= '0;
      end
      //else if (adder_select) begin
      else if (ena) begin	 
	 //ena <= adder_select;
	 //data_in0_reg <= data_in0;
	 //data_in1_reg <= data_in1;
	 valid_internal[0] <= {1'b0, data_valid};
	 row_idx_internal[0] <= data_row_idx;
      end
   end
      
   integer i0;
   always_ff @ (posedge clk) begin
      if(~rst_b) begin
	 for (i0 = 0; i0 < NUM_STG_ADDER_PIPE; i0 = i0 + 1) begin
	    valid_internal[i0+1] <= '0;
	    row_idx_internal[i0+1] <= '0;
	 end
      end
      if (ena) begin
	 for (i0 = 0; i0 < NUM_STG_ADDER_PIPE; i0 = i0 + 1) begin
	    valid_internal[i0+1] <= valid_internal[i0];
	    row_idx_internal[i0+1] <= row_idx_internal[i0];
	 end
      end
   end
   assign data_valid_reg = valid_internal[NUM_STG_ADDER_PIPE][0];
   assign data_row_idx_reg = row_idx_internal[NUM_STG_ADDER_PIPE];
   
endmodule 
//
//---------------------------------------------------------------------------
// Asynchronous FIFO with SRAM based memory   
//
//  
//---------------------------------------------------------------------------
//

//=========================== Buffer ==================================
module fifomem_asyn_sram 
  #(parameter 
    DATASIZE = `DATA_WIDTH_BUFF_SO_SEG, // Memory data word width
    ADDRSIZE = `BITS_SLOW_BLK_BUFF_ADDR) // Number of mem address bits
   (//input
    input [DATASIZE - 1 : 0] wdata,
    input [ADDRSIZE - 1 : 0] waddr, raddr,
    //input wclken, wfull, wclk, rclken, rempty, rclk,
    input wen, wclk, rclk,
    
    output logic [DATASIZE - 1 : 0] rdata);
   
   // RTL Verilog memory model
   parameter DEPTH = 1 << ADDRSIZE;
   reg [DATASIZE - 1 : 0] mem [0 : DEPTH - 1];
   //assign rdata = mem[raddr];

   //Tool wil have hardtime to infer this code block
   /*
   always_ff @(posedge rclk) begin    
      if(rclken && !rempty) rdata <= mem[raddr];
      else rdata <= '0;
   end
    */ 
   always_ff @(posedge rclk) begin    
      rdata <= mem[raddr];
   end
   
   always_ff @(posedge wclk) begin
      //if (wclken && !wfull) mem[waddr] <= wdata;
      if (wen) mem[waddr] <= wdata;
   end
   
endmodule
//=====================================================================

//=====================================================================
module afifo_ptr_only 
  #(parameter 
    ASIZE = `BITS_SLOW_BLK_BUFF_ADDR)
   (//input
    input winc, wclk, wrst_n,
    input rinc, rclk, rrst_n,
    output wfull, rempty,
    output [ASIZE-1:0] waddr, raddr);
   
wire [ASIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;
sync_r2w #(.ADDRSIZE(ASIZE)) sync_r2w (.wq2_rptr(wq2_rptr), .rptr(rptr), .wclk(wclk), .wrst_n(wrst_n));
sync_w2r #(.ADDRSIZE(ASIZE)) sync_w2r (.rq2_wptr(rq2_wptr), .wptr(wptr), .rclk(rclk), .rrst_n(rrst_n));

/*   
fifomem_asyn_sram #(.DATASIZE(DSIZE), .ADDRSIZE(ASIZE)) fifomem_sram
(.rdata(rdata), .wdata(wdata),
.waddr(waddr), .raddr(raddr),
.wclken(winc), .wfull(wfull), .rclken(rinc), .rempty(rempty),
.wclk(wclk), .rclk(rclk));
*/
   
rptr_empty #(.ADDRSIZE(ASIZE)) rptr_empty
(.rempty(rempty),
.raddr(raddr),
.rptr(rptr), .rq2_wptr(rq2_wptr),
.rinc(rinc), .rclk(rclk),
.rrst_n(rrst_n));
   
wptr_full #(.ADDRSIZE(ASIZE)) wptr_full
(.wfull(wfull), .waddr(waddr),
.wptr(wptr), .wq2_rptr(wq2_rptr),
.winc(winc), .wclk(wclk),
.wrst_n(wrst_n));
endmodule // afifo_ptr_only
//=====================================================================
//
//---------------------------------------------------------------------------
// Asynchronous FIFO   
//
//  
//---------------------------------------------------------------------------
//

module afifo 
  #(parameter 
    DSIZE = `DATA_WIDTH_BUFF_SO_SEG,
    ASIZE = `BITS_SLOW_BLK_BUFF_ADDR)
   (//input
    input [DSIZE-1:0] wdata,
    input winc, wclk, wrst_n,
    input rinc, rclk, rrst_n,
    output [DSIZE-1:0] rdata,
    output wfull, rempty);
   
wire [ASIZE-1:0] waddr, raddr;
wire [ASIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;

sync_r2w #(.ADDRSIZE(ASIZE)) sync_r2w (.wq2_rptr(wq2_rptr), .rptr(rptr),
.wclk(wclk), .wrst_n(wrst_n));

sync_w2r #(.ADDRSIZE(ASIZE)) sync_w2r (.rq2_wptr(rq2_wptr), .wptr(wptr),
.rclk(rclk), .rrst_n(rrst_n));
   
fifomem_asyn #(.DATASIZE(DSIZE), .ADDRSIZE(ASIZE)) fifomem
(.rdata(rdata), .wdata(wdata),
.waddr(waddr), .raddr(raddr),
.wclken(winc), .wfull(wfull),
.wclk(wclk));

rptr_empty #(.ADDRSIZE(ASIZE)) rptr_empty
(.rempty(rempty),
.raddr(raddr),
.rptr(rptr), .rq2_wptr(rq2_wptr),
.rinc(rinc), .rclk(rclk),
.rrst_n(rrst_n));
   
wptr_full #(.ADDRSIZE(ASIZE)) wptr_full
(.wfull(wfull), .waddr(waddr),
.wptr(wptr), .wq2_rptr(wq2_rptr),
.winc(winc), .wclk(wclk),
.wrst_n(wrst_n));
endmodule

//=========================== Buffer ==================================
module fifomem_asyn 
  #(parameter 
    DATASIZE = `DATA_WIDTH_BUFF_SO_SEG, // Memory data word width
    ADDRSIZE = `BITS_SLOW_BLK_BUFF_ADDR) // Number of mem address bits
   (//input
    input [DATASIZE - 1 : 0] wdata,
    input [ADDRSIZE - 1 : 0] waddr, raddr,
    input wclken, wfull, wclk,
    output [DATASIZE - 1 : 0] rdata);
   
   // RTL Verilog memory model
   parameter DEPTH = 1 << ADDRSIZE;
   reg [DATASIZE - 1 : 0] mem [0 : DEPTH - 1];
   assign rdata = mem[raddr];
   always_ff @(posedge wclk) begin
     if (wclken && !wfull) mem[waddr] <= wdata;
   end
   
endmodule
//=====================================================================

//============ Read / Write Pointer Synchronizers =====================
module sync_r2w 
  #(parameter ADDRSIZE = 4)
   (//input
    input [ADDRSIZE:0] rptr,
    input wclk, wrst_n,
    output reg [ADDRSIZE:0] wq2_rptr);
   
reg [ADDRSIZE:0] wq1_rptr;

always @(posedge wclk)
  if (!wrst_n) {wq2_rptr,wq1_rptr} <= 0;
  else {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};
endmodule

module sync_w2r 
  #(parameter ADDRSIZE = 4)
   (//input
    input [ADDRSIZE:0] 	    wptr,
    input 		    rclk, rrst_n,
    output reg [ADDRSIZE:0] rq2_wptr);
   
reg [ADDRSIZE:0] rq1_wptr;

always @(posedge rclk)
if (!rrst_n) {rq2_wptr,rq1_wptr} <= 0;
else {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};
endmodule
//=====================================================================

//====================== Buffer Empty =================================
module rptr_empty 
  #(parameter ADDRSIZE = 4)
   (
    input [ADDRSIZE :0] rq2_wptr,
    input rinc, rclk, rrst_n, 
    output reg rempty,
    output [ADDRSIZE-1:0] raddr,
    output reg [ADDRSIZE :0] rptr);
   
reg [ADDRSIZE:0] rbin;
wire [ADDRSIZE:0] rgraynext, rbinnext;
   
//-------------------
// GRAYSTYLE2 pointer
//-------------------
always @(posedge rclk)
if (!rrst_n) {rbin, rptr} <= 0;
else {rbin, rptr} <= {rbinnext, rgraynext};
// Memory read-address pointer (okay to use binary to address memory)
assign raddr = rbin[ADDRSIZE-1:0];
assign rbinnext = rbin + (rinc & ~rempty);
assign rgraynext = (rbinnext>>1) ^ rbinnext;

//---------------------------------------------------------------
// FIFO empty when the next rptr == synchronized wptr or on reset
//---------------------------------------------------------------
assign rempty_val = (rgraynext == rq2_wptr);
always @(posedge rclk)
if (!rrst_n) rempty <= 1'b1;
else rempty <= rempty_val;
endmodule // rptr_empty
//=====================================================================


//========================= Buffer Full ===============================
module wptr_full 
  #(parameter ADDRSIZE = 4)
   (//input
    input [ADDRSIZE :0] wq2_rptr,
    input winc, wclk, wrst_n,
    output reg wfull,
    output [ADDRSIZE-1:0] waddr,
    output reg [ADDRSIZE :0] wptr);
   
reg [ADDRSIZE:0] wbin;
wire [ADDRSIZE:0] wgraynext, wbinnext;

// GRAYSTYLE2 pointer
always @(posedge wclk)
if (!wrst_n) {wbin, wptr} <= 0;
else {wbin, wptr} <= {wbinnext, wgraynext};

// Memory write-address pointer (okay to use binary to address memory)
assign waddr = wbin[ADDRSIZE-1:0];
assign wbinnext = wbin + (winc & ~wfull);
assign wgraynext = (wbinnext>>1) ^ wbinnext;

//------------------------------------------------------------------
// Simplified version of the three necessary full-tests:
// assign wfull_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
// (wgnext[ADDRSIZE-1] !=wq2_rptr[ADDRSIZE-1]) &&
// (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0]));
//------------------------------------------------------------------
assign wfull_val = (wgraynext == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1],wq2_rptr[ADDRSIZE-2:0]});
always @(posedge wclk)
if (!wrst_n) wfull <= 1'b0;
else wfull <= wfull_val;
endmodule
//=====================================================================





//
//---------------------------------------------------------------------------
// Top module for Asynchronous FIFOs (10spmv_fpga) between slow and fast merge blocks   
// 
//  
//---------------------------------------------------------------------------
//

module afifo_top_slow_fast 
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,
    DATA_WIDTH_ADD_STG = `DATA_WIDTH_ADD_STG,
    SLOW_BLK_BUFF_SIZE = `SLOW_BLK_BUFF_SIZE,
    BITS_SLOW_BLK_BUFF_ADDR = `BITS_SLOW_BLK_BUFF_ADDR,
    NUM_SLOW_BLK = `NUM_SEG_PER_STG,
    VI = `VALID_INDEX_DATA_BUFF_SO_SEG)
   (//input
    input clk, clk_slow, rst_b, unit_en, mode, next_stg_rd_en,
    input [NUM_SLOW_BLK - 1 : 0] blk_en_adv_slow,
    input [NUM_SLOW_BLK - 1 : 0] [DATA_WIDTH - 1 : 0] data_out_blk_slow,
    input [NUM_SLOW_BLK - 1 : 0] en_intake_fifo_slow_blk,
  
    //output
    output logic [NUM_SLOW_BLK - 1 : 0] fifo_empty,
    output logic [NUM_SLOW_BLK - 1 : 0] out_fifo_wr_ready_slow, out_fifo_wr_ready_slow_adv,
    output [NUM_SLOW_BLK - 1 : 0] [DATA_WIDTH_ADD_STG - 1 : 0] data_out_fifo);

   logic [NUM_SLOW_BLK - 1 : 0] fifo_wr_en, fifo_rd_en, fifo_full;//,fifo_empty;
   logic [NUM_SLOW_BLK - 1 : 0] [DATA_WIDTH_ADD_STG - 1 : 0] din;
      
   integer i0;
   always_comb begin
      for (i0 = 0; i0 < NUM_SLOW_BLK; i0 = i0 + 1) begin
	 din[i0] = data_out_blk_slow[i0][DATA_WIDTH - 1 : DATA_WIDTH - DATA_WIDTH_ADD_STG];
	 //fifo_wr_en[i0] = (mode == `MODE_WORK && unit_en) ? blk_en_adv_slow[i0] && data_out_blk_slow[i0][VI] : 1'b0;
	 fifo_wr_en[i0] = (mode == `MODE_WORK && unit_en) ? blk_en_adv_slow[i0] && din[i0][0] : 1'b0;
       	 fifo_rd_en[i0] = (next_stg_rd_en)? en_intake_fifo_slow_blk[i0] & ~fifo_empty[i0] : 1'b0;
	 out_fifo_wr_ready_slow_adv[i0] = (mode == `MODE_WORK) ? !fifo_full[i0] : 1'b0;  
      end   
   end
   ////assign blk_en_fast = (mode == `MODE_WORK) ? unit_en & ~(|in_fifo_rd_halt_fast) & wr_ready_blk_fast_out_q : 1'b0;// only integrate unit_en and mode with any kind of blk_en, not with fifo_ready/empty, intake_enable or rd_halt kind of signals
   register #(.WIDTH(NUM_SLOW_BLK)) reg_out_fifo(.q(out_fifo_wr_ready_slow), .d(out_fifo_wr_ready_slow_adv), .clk(clk_slow), .enable(1'b1), .rst_b(rst_b));


//-------------------------------------------------------------   
//just for plot
wire [NUM_SLOW_BLK - 1 : 0][`BITS_ROW_IDX - 1 : 0] afifo_out_row_idx;
wire [NUM_SLOW_BLK - 1 : 0][`DATA_PRECISION - 1 : 0] afifo_out_value;
wire [NUM_SLOW_BLK - 1 : 0]afifo_out_valid;   

wire [NUM_SLOW_BLK - 1 : 0][`BITS_ROW_IDX - 1 : 0] afifo_in_row_idx;
wire [NUM_SLOW_BLK - 1 : 0][`DATA_PRECISION - 1 : 0] afifo_in_value;
wire [NUM_SLOW_BLK - 1 : 0]afifo_in_valid;      
//-------------------------------------------------------------   

   
   //FIFO Asynchronous
   //=========================================================================================
   genvar j0;
   generate
      for (j0 = 0; j0 < NUM_SLOW_BLK; j0 = j0 + 1) begin : afifo
 
	 afifo #(.DSIZE(DATA_WIDTH_ADD_STG), .ASIZE(BITS_SLOW_BLK_BUFF_ADDR)) fifo_slow_fast
	  (//input
	   .wdata(din[j0]), .winc(fifo_wr_en[j0]), .wclk(clk_slow), .wrst_n(rst_b),
	   .rinc(fifo_rd_en[j0]), .rclk(clk), .rrst_n(rst_b),
	   //output
           .rdata(data_out_fifo[j0]),
           .wfull(fifo_full[j0]),
           .rempty(fifo_empty[j0]));

//--------------------------------------------------------------
//just for plot	 
assign afifo_out_row_idx[j0] = data_out_fifo[j0][DATA_WIDTH_ADD_STG - 1 : DATA_WIDTH_ADD_STG - `BITS_ROW_IDX];
assign afifo_out_value[j0] = data_out_fifo[j0][DATA_WIDTH_ADD_STG - `BITS_ROW_IDX -1 : DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - `DATA_PRECISION];
assign afifo_out_valid[j0] = data_out_fifo[j0][0];     	 
assign afifo_in_row_idx[j0] = din[j0][DATA_WIDTH_ADD_STG - 1 : DATA_WIDTH_ADD_STG - `BITS_ROW_IDX];
assign afifo_in_value[j0] = din[j0][DATA_WIDTH_ADD_STG - `BITS_ROW_IDX -1 : DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - `DATA_PRECISION];
assign afifo_in_valid[j0] = din[j0][0];  
//--------------------------------------------------------------	 
      end
   endgenerate
  //=========================================================================================


   
endmodule
// Copyright 2007 Altera Corporation. All rights reserved.  
// Altera products are protected under numerous U.S. and foreign patents, 
// maskwork rights, copyrights and other intellectual property laws.  
//
// This reference design file, and your use thereof, is subject to and governed
// by the terms and conditions of the applicable Altera Reference Design 
// License Agreement (either as signed by you or found at www.altera.com).  By
// using this reference design file, you indicate your acceptance of such terms
// and conditions between you and Altera Corporation.  In the event that you do
// not agree with such terms and conditions, you may not use the reference 
// design file and please promptly destroy any copies you have made.
//
// This reference design file is being provided on an "as-is" basis and as an 
// accommodation and therefore all warranties, representations or guarantees of 
// any kind (whether express, implied or statutory) including, without 
// limitation, warranties of merchantability, non-infringement, or fitness for
// a particular purpose, are specifically disclaimed.  By making this reference
// design file available, Altera expressly does not recommend, suggest or 
// require that this reference design file be used in combination with any 
// other product not provided by Altera.
/////////////////////////////////////////////////////////////////////////////


// baeckler - 02-13-2007
//
// 'base' is a one hot signal indicating the first request
// that should be considered for a grant.  Followed by higher
// indexed requests, then wrapping around.
//

module arbiter (
	req, grant, base
);

parameter WIDTH = 16;

input [WIDTH-1:0] req;
output [WIDTH-1:0] grant;
input [WIDTH-1:0] base;

wire [2*WIDTH-1:0] double_req = {req,req};
wire [2*WIDTH-1:0] double_grant = double_req & ~(double_req-base);
assign grant = double_grant[WIDTH-1:0] | double_grant[2*WIDTH-1:WIDTH];
	
endmodule
//
//---------------------------------------------------------------------------
// bitonic sort network. look into documentation for terminologies - bitonic-sort-hw-development.pptx
//
//  
//---------------------------------------------------------------------------
//

module bitonic_sort_network
  #(//parameter
    STREAM_WIDTH = `STREAM_WIDTH,
    LOG_STREAM_WIDTH = `LOG_STREAM_WIDTH,
    DATA_WIDTH = `BITS_ROW_IDX + `DATA_PRECISION,
    NUM_BIOTONIC_STGS_TOT = `NUM_BIOTONIC_STGS_TOT,
    NUM_BLOCKS = LOG_STREAM_WIDTH)
   (input clk, rst_b, enable,   
    input [STREAM_WIDTH - 1 : 0][DATA_WIDTH - 1 : 0] din,
    output logic [STREAM_WIDTH - 1 : 0][DATA_WIDTH - 1 : 0] dout);

   logic [NUM_BIOTONIC_STGS_TOT : 0][STREAM_WIDTH - 1 : 0][DATA_WIDTH + LOG_STREAM_WIDTH - 1 : 0] dpipe;
   logic [STREAM_WIDTH - 1 : 0][LOG_STREAM_WIDTH - 1 : 0] stream_id;

   always_comb begin
      for (integer i0 = 0; i0 < STREAM_WIDTH; i0 = i0 + 1) begin 
	 stream_id[i0] = i0;
	 dpipe[0][i0] = {din[i0], stream_id[i0]}; //stream id is required for bitonic sort as the serial is used to determine the output serial when radix are same
	 dout[i0] = dpipe[NUM_BIOTONIC_STGS_TOT][i0][DATA_WIDTH + LOG_STREAM_WIDTH - 1 : LOG_STREAM_WIDTH];
      end
   end

   //assign dpipe[0] = din;
   //assign dout = dpipe[NUM_BIOTONIC_STGS_TOT];
      
   genvar j0_blk, j1_stg, j2_grp, j3_subgrp, j4_comp_subgrp;
   //genvar num_grps, num_stgs, ele_gap, num_comps_per_stg, num_comps_per_stg_per_grp, num_ele_per_grp, up_down, serial_dpipe;
   generate
      //localparam integer serial_dpipe = 0;
      for (j0_blk = 0; j0_blk < NUM_BLOCKS; j0_blk = j0_blk + 1) begin : blks

	 localparam integer num_grps = STREAM_WIDTH/(1 << (j0_blk+1));
	 localparam integer num_stgs = j0_blk + 1;
	 //localparam integer num_comps_per_stg = 1 << j0_blk; //number of comparators per stage
	
	 localparam integer num_comps_per_stg_per_grp = 1 << j0_blk; //num_comps_per_stg / num_grps;
	 localparam integer num_ele_per_grp = 2 * num_comps_per_stg_per_grp;
	 for (j1_stg = 0; j1_stg < num_stgs; j1_stg = j1_stg + 1) begin : stgs
	    
	    localparam integer serial_dpipe = (1 << j0_blk) + j1_stg;
	    localparam integer ele_gap = 1 << (j0_blk - j1_stg);

	    localparam integer num_subgrps = 1 << j1_stg;
	    localparam integer num_comps_per_stg_per_subgrp = 1 << (j0_blk - j1_stg); //num_comps_per_stg_per_grp/num_subgrps;
	    localparam integer num_ele_per_subgrp = 2 * num_comps_per_stg_per_subgrp;
	    
	    for (j2_grp = 0; j2_grp < num_grps; j2_grp = j2_grp + 1) begin : grps
	       localparam integer up_down = j2_grp % 2; //1 means up, 0 means down. down is bigger idx goes lower(i.e. ascending)
	       
	       for (j3_subgrp = 0; j3_subgrp < num_subgrps; j3_subgrp = j3_subgrp + 1) begin : subgrps
	       
		  for (j4_comp_subgrp = 0; j4_comp_subgrp < num_comps_per_stg_per_subgrp; j4_comp_subgrp = j4_comp_subgrp + 1) begin : comps
	              
		     bitonic_ud_comparator #(.UP_OR_DN(up_down), .SERIAL_DPIPE(serial_dpipe)) bit_sort(
		      //SERIAL_DPIPE parameter is passed just for debug 
		      //input
		      .clk, .rst_b, .enable,   
                      .din0(dpipe[serial_dpipe - 1][j2_grp * num_ele_per_grp + j3_subgrp * num_ele_per_subgrp + j4_comp_subgrp]), 
		      .din1(dpipe[serial_dpipe - 1][j2_grp * num_ele_per_grp + j3_subgrp * num_ele_per_subgrp + j4_comp_subgrp + ele_gap]),
		      //output		       
                      .dout0(dpipe[serial_dpipe][j2_grp * num_ele_per_grp + j3_subgrp * num_ele_per_subgrp + j4_comp_subgrp]), 
                      .dout1(dpipe[serial_dpipe][j2_grp * num_ele_per_grp + j3_subgrp * num_ele_per_subgrp + j4_comp_subgrp + ele_gap]));
		  end	       
	       end 
	    end
	 end
      end

   endgenerate

//------------------------------------
//just for debug
logic [NUM_BIOTONIC_STGS_TOT : 0][STREAM_WIDTH - 1 : 0][`BITS_ROW_IDX - 1 : 0] dpipe_rowidx;
   
always_comb begin
   for (integer i1 = 0; i1 < NUM_BIOTONIC_STGS_TOT + 1; i1 = i1 + 1) begin 
      for (integer i0 = 0; i0 < STREAM_WIDTH; i0 = i0 + 1) begin 
	 
	 dpipe_rowidx[i1][i0] = dpipe[i1][i0][DATA_WIDTH + LOG_STREAM_WIDTH - 1 : DATA_WIDTH + LOG_STREAM_WIDTH - `BITS_ROW_IDX];
      end
   end
end
//-----------------------------------  


   
endmodule // bitonic_sort_network

   
//
//---------------------------------------------------------------------------
// bitonic up/dowm comparator
//
//  
//---------------------------------------------------------------------------
//

module bitonic_ud_comparator
  #(//parameter
    SERIAL_DPIPE = 1, //just for debug
    UP_OR_DN = 0, //1 means up, 0 means down. Down is for ascending order. Up for descending.
    LOG_STREAM_WIDTH = `LOG_STREAM_WIDTH,
    BITS_UNIT_SELECTION = `BITS_UNIT_SELECTION,
    UNIT_INIT_BIT = `UNIT_INIT_BIT,
    DATA_WIDTH = `BITS_ROW_IDX + `DATA_PRECISION + LOG_STREAM_WIDTH)
   (input clk, rst_b, enable,   
    input [DATA_WIDTH - 1 : 0] din0, din1,
    output logic [DATA_WIDTH - 1 : 0] dout0, dout1);

   wire [7 : 0] serial_dpipe; //just for debug
   assign serial_dpipe = SERIAL_DPIPE;
      
   //==============================================================================
   //------------------------------------------------------------
   // Make the bitonic sorter entirely pipelined
   wire [DATA_WIDTH - 1 : 0] din0_reg, din1_reg;
   
   register #(.WIDTH(DATA_WIDTH)) reg_din0(.q(din0_reg), .d(din0), .clk(clk), .enable(enable), .rst_b(rst_b));
   register #(.WIDTH(DATA_WIDTH)) reg_din1(.q(din1_reg), .d(din1), .clk(clk), .enable(enable), .rst_b(rst_b)); 
   //------------------------------------------------------------
   //------------------------------------------------------------
   // Make the bitonic sorter entirely combinational
   //assign din0_reg = din0;
   //assign din1_reg = din1;
   //------------------------------------------------------------
   //==============================================================================
   
   wire [`BITS_ROW_IDX - 1 : 0] index0, index1;
   assign index0 = din0_reg[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   assign index1 = din1_reg[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   
   wire [BITS_UNIT_SELECTION - 1 : 0] radix0, radix1;
   assign radix0 = index0[BITS_UNIT_SELECTION - 1 : 0];
   assign radix1 = index1[BITS_UNIT_SELECTION - 1 : 0];

   wire [LOG_STREAM_WIDTH - 1 : 0] stream_id0, stream_id1;
   assign stream_id0 = din0_reg[LOG_STREAM_WIDTH - 1 : 0];
   assign stream_id1 = din1_reg[LOG_STREAM_WIDTH - 1 : 0];
   
   generate 
      if (UP_OR_DN == 0) begin : down_comp 
	 always_comb begin   
	    unique if (radix0 < radix1) begin
	       dout0 = din0_reg;
	       dout1 = din1_reg;     
	    end
	    else if(radix0 > radix1) begin
	       dout0 = din1_reg;
	       dout1 = din0_reg;  
	    end
	    else if (radix0 == radix1 && stream_id0 < stream_id1) begin
	       dout0 = din0_reg;
	       dout1 = din1_reg;     
	    end	    
	    else begin
	       dout0 = din1_reg;
	       dout1 = din0_reg;     
	    end		    
	 end
      end // block: down_comp
      
      else begin : up_comp  
	 always_comb begin  
	    unique if (radix0 > radix1) begin
	       dout0 = din0_reg;
	       dout1 = din1_reg;     
	    end
	    else if (radix0 < radix1) begin
	       dout0 = din1_reg;
	       dout1 = din0_reg;  
	    end
	    //for up comparators make it descending depending on stream id
	    else if (radix0 == radix1 && stream_id0 > stream_id1) begin
	       dout0 = din0_reg;
	       dout1 = din1_reg;     
	    end	    
	    else begin
	       dout0 = din1_reg;
	       dout1 = din0_reg;     
	    end	     
	 end
      end // block: up_comp
   endgenerate

/*
    generate 
      if (UP_OR_DN == 0) begin : down_comp 
	 always_comb begin   
	    unique if (radix0 <= radix1) begin
	       dout0 = din0_reg;
	       dout1 = din1_reg;     
	    end
	    else begin
	       dout0 = din1_reg;
	       dout1 = din0_reg;  
	    end     
	 end
      end // block: down_comp
      
      else begin : up_comp  
	 always_comb begin  
	    unique if (radix0 >= radix1) begin
	       dout0 = din0_reg;
	       dout1 = din1_reg;     
	    end
	    else begin
	       dout0 = din1_reg;
	       dout1 = din0_reg;  
	    end     
	 end
      end // block: up_comp
   endgenerate
 
*/ 


   
endmodule

 
//
//---------------------------------------------------------------------------
// FPGA block memory for M20K 
//  
//  
//---------------------------------------------------------------------------
//


//`timescale `TIME_SCALE

module bram_m20k(CLK, rd_en, wr_en, rd_addr, wr_addr, WBL, ARBL);
   
   parameter 
     BL_WIDTH = `LIM_BRICK_WORD_SIZE,
     ADDR_WIDTH = `BITS_ADDR_LIM_BRICK,	
     WL_WIDTH = `LIM_BRICK_WORD_NUM;
   
   input CLK, rd_en, wr_en;
   input [ADDR_WIDTH - 1 : 0] rd_addr, wr_addr;
   input [BL_WIDTH - 1 : 0] WBL;    
   output logic [BL_WIDTH - 1 : 0] ARBL;			  
   
   logic [BL_WIDTH - 1 : 0] mem_brick [(2**ADDR_WIDTH) - 1 : 0]; 
  
   always @(posedge CLK) begin    
      //read
      if(rd_en)
	ARBL <= mem_brick[rd_addr];
      //else
	//ARBL <= 'bz;
      //else
	//ARBL <= '0;
      //write
      if(wr_en)
	mem_brick[wr_addr] <= WBL;
   end
     
endmodule
//
//---------------------------------------------------------------------------
// FPGA block memory for M20K 
//  
//  
//---------------------------------------------------------------------------
//


//`timescale `TIME_SCALE

module bram_mlab(CLK, rd_en, wr_en, rd_addr, wr_addr, WBL, ARBL);
   
   parameter 
     BL_WIDTH = `LIM_BRICK_WORD_SIZE,
     ADDR_WIDTH = `BITS_ADDR_LIM_BRICK,	
     WL_WIDTH = `LIM_BRICK_WORD_NUM;
   
   input CLK, rd_en, wr_en;
   input [ADDR_WIDTH - 1 : 0] rd_addr, wr_addr;
   input [BL_WIDTH - 1 : 0] WBL;    
   output logic [BL_WIDTH - 1 : 0] ARBL;			  
   
   (* ramstyle="MLAB,no_rw_check" *) logic [BL_WIDTH - 1 : 0] mem_brick [(2**ADDR_WIDTH) - 1 : 0]; 
  
   always @(posedge CLK) begin    
      //read
      if(rd_en)
	ARBL <= mem_brick[rd_addr];
      //else
	//ARBL <= 'bz;
      //else
	//ARBL <= '0;
      //write
      if(wr_en)
	mem_brick[wr_addr] <= WBL;
   end
     
endmodule
//
//---------------------------------------------------------------------------
// SRAM memory block for input segment 
//  
//  
//---------------------------------------------------------------------------
//

module segment_memory_input_sram #(
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
   input adv_rd_wr_addr_match_flag, rd_wr_addr_match_flag, mandatory_bubble,
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
register #(.WIDTH(DATA_WIDTH)) reg_ARBL(.q(data_out_input_wo_tag_valid), .d(ARBL), .clk, .enable(mandatory_bubble), .rst_b(rst_b));
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

//
//---------------------------------------------------------------------------
// SRAM memory block for segment for both buffer and stage output
//  
//  
//---------------------------------------------------------------------------
//

module segment_memory_sram #(
   parameter
     NUM_BUFF_SO_WORDS_SEG = `NUM_BUFF_SO_WORDS_SEG,
     NUM_BRICK_SEG_VER = `NUM_BRICK_SEG_VER,
     BITS_ADDR_SEG = `BITS_ADDR_SEG,	
     BITS_ADDR_LIM_BRICK = `BITS_ADDR_LIM_BRICK,		    
     NUM_BRICK_SEG_HOR = `NUM_BRICK_SEG_HOR,		   
     DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,
     NUM_DUMMY_BITS = `NUM_DUMMY_BITS_SEG_MEM) (

   input rst_b, clk, rd_en_adv, wr_en_adv, 
   input adv_rd_wr_addr_match_flag, rd_wr_addr_match_flag, mandatory_bubble,
   input [BITS_ADDR_SEG - 1 : 0] adv_rd_addr_seg, adv_wr_addr_seg,
   input [DATA_WIDTH - 1 : 0] data_in_buff, data_in_so,
							  
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
   
assign ARBL_buff = rd_wr_addr_match_flag ? data_in_buff_reg[DATA_WIDTH + NUM_DUMMY_BITS - 1 : NUM_DUMMY_BITS] : ARBL_buff_w_dummy[DATA_WIDTH + NUM_DUMMY_BITS - 1 : NUM_DUMMY_BITS];
assign ARBL_so = rd_wr_addr_match_flag ? data_in_so_reg[DATA_WIDTH + NUM_DUMMY_BITS - 1 : NUM_DUMMY_BITS] : ARBL_so_w_dummy[DATA_WIDTH + NUM_DUMMY_BITS - 1 : NUM_DUMMY_BITS];

//this is for nonpipelined version   
//assign dout_buff = ARBL_buff;
//assign dout_so = ARBL_so; 

//this is for pipelined version
register #(.WIDTH(DATA_WIDTH)) reg_ARBL_buff(.q(dout_buff), .d(ARBL_buff), .clk, .enable(mandatory_bubble), .rst_b(rst_b));
register #(.WIDTH(DATA_WIDTH)) reg_ARBL_so(.q(dout_so), .d(ARBL_so), .clk, .enable(mandatory_bubble), .rst_b(rst_b)); 
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

   if (NUM_BUFF_SO_WORDS_SEG > 255) begin

      bram_m20k #(.BL_WIDTH(DATA_WIDTH), .ADDR_WIDTH(BITS_ADDR_SEG), .WL_WIDTH(NUM_BUFF_SO_WORDS_SEG)) bram_buff(.CLK(clk), .rd_en(rd_en_adv && !adv_rd_wr_addr_match_flag), .wr_en(wr_en_adv), .rd_addr(adv_rd_addr_seg), .wr_addr(adv_wr_addr_seg), .WBL(data_in_buff_w_dummy), .ARBL(ARBL_buff_w_dummy));

      bram_m20k #(.BL_WIDTH(DATA_WIDTH), .ADDR_WIDTH(BITS_ADDR_SEG), .WL_WIDTH(NUM_BUFF_SO_WORDS_SEG)) bram_so(.CLK(clk), .rd_en(rd_en_adv && !adv_rd_wr_addr_match_flag), .wr_en(wr_en_adv), .rd_addr(adv_rd_addr_seg), .wr_addr(adv_wr_addr_seg), .WBL(data_in_so_w_dummy), .ARBL(ARBL_so_w_dummy));
      
   end

   else begin

      bram_mlab #(.BL_WIDTH(DATA_WIDTH), .ADDR_WIDTH(BITS_ADDR_SEG), .WL_WIDTH(NUM_BUFF_SO_WORDS_SEG)) bram_buff(.CLK(clk), .rd_en(rd_en_adv && !adv_rd_wr_addr_match_flag), .wr_en(wr_en_adv), .rd_addr(adv_rd_addr_seg), .wr_addr(adv_wr_addr_seg), .WBL(data_in_buff_w_dummy), .ARBL(ARBL_buff_w_dummy));

      bram_mlab #(.BL_WIDTH(DATA_WIDTH), .ADDR_WIDTH(BITS_ADDR_SEG), .WL_WIDTH(NUM_BUFF_SO_WORDS_SEG)) bram_so(.CLK(clk), .rd_en(rd_en_adv && !adv_rd_wr_addr_match_flag), .wr_en(wr_en_adv), .rd_addr(adv_rd_addr_seg), .wr_addr(adv_wr_addr_seg), .WBL(data_in_so_w_dummy), .ARBL(ARBL_so_w_dummy));

   end 

endgenerate
//=======================================================================     


endmodule

//
//---------------------------------------------------------------------------
// Fast merge block with fast stages 
// This is an array of merge stages that works on fast clk speed
//  
//---------------------------------------------------------------------------
//

module merge_blk_fast_fifo_based 
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_ADD_STG,
    END_OF_FAST_STG = `END_OF_FAST_STG,
    NUM_SLOW_BLK = `NUM_SEG_PER_STG,
    BITS_BLK_FAST_OUT_Q = `BITS_BLK_FAST_OUT_Q)
   (
    input clk, rst_b, mode, unit_en, next_blk_rd_en,
    input [NUM_SLOW_BLK - 1 : 0] [DATA_WIDTH - 1 : 0] data_in_blk_fast,
    input [NUM_SLOW_BLK - 1 : 0] prev_blk_fifo_empty,    

    output blk_fast_rd_en_stg0, rd_ready_blk_fast_out_q,  
    output [NUM_SLOW_BLK - 1 : 0] en_intake_fifo_slow_blk,					  
    output [DATA_WIDTH - 1 : 0] do_blk_fast_out_q);

   wire global_en;
   assign global_en = unit_en && (mode == `MODE_WORK);
     
   //wire [(1<<`END_OF_FAST_STG) - 2 : 0] atom_en;
   logic [(1<<`END_OF_FAST_STG)*2 - 2 : 0] [DATA_WIDTH - 1 : 0] atom_data_out;
   wire [(1<<`END_OF_FAST_STG)*2 - 2 : 0] stg_fifo_full;					
   wire [(1<<`END_OF_FAST_STG)*2 - 2 : 0] stg_fifo_wr_en; 
      
   //Stages of the fast block
   //*********************************************************************************
   genvar i;
   generate
      for (i = 0; i < `END_OF_FAST_STG; i = i + 1) begin
      	 merge_stage_fast_fifo_based
	   #(//parameters
	     .NUM_ATOMS(1 << i)) fast_stg
           (//input										 
            .rst_b, .clk, .global_en,
	    .next_fifo_full(stg_fifo_full[(1 << (i+1)) - 2 : (1 << i) - 1]), 
	    .fifo_wr_en(stg_fifo_wr_en[(1 << (i+2)) - 2 : (1 << (i+1)) - 1]),
            .data_in(atom_data_out[(1 << (i+2)) - 2 : (1 << (i+1)) - 1]),
	    //output
	    .fifo_full(stg_fifo_full[(1 << (i+2)) - 2 : (1 << (i+1)) - 1]),	    
	    .next_fifo_wr_en(stg_fifo_wr_en[(1 << (i+1)) - 2 : (1 << i) - 1]), 	    
            .data_out(atom_data_out[(1 << (i+1)) - 2 : (1 << i) - 1]));
      end
   endgenerate
   //*********************************************************************************
  
   assign en_intake_fifo_slow_blk = ~stg_fifo_full[(1 << (`END_OF_FAST_STG + 1)) - 2 : (1 << `END_OF_FAST_STG) - 1];
   assign stg_fifo_wr_en[(1 << (`END_OF_FAST_STG + 1)) - 2 : (1 << `END_OF_FAST_STG) - 1] = blk_fast_rd_en_stg0 ? en_intake_fifo_slow_blk & (~prev_blk_fifo_empty) : '0;
   assign atom_data_out[(1 << (`END_OF_FAST_STG + 1)) - 2 : (1 << `END_OF_FAST_STG) - 1] = data_in_blk_fast; 
      
   assign blk_fast_rd_en_stg0 = global_en;
         
   // Output Fifo for fast block
   //=========================================================================================
   wire fifo_full, fifo_empty;
   assign stg_fifo_full[0] = fifo_full;   

   assign rd_ready_blk_fast_out_q = !fifo_empty;
   
   sfifo #(.DSIZE(DATA_WIDTH), .ASIZE(BITS_BLK_FAST_OUT_Q)) fifo_fast_out
     (//input
      .clk, .rst_b, .rd_en(next_blk_rd_en), .wr_en(stg_fifo_wr_en[0]),
      .data_in(atom_data_out[0]),
      //output
      .data_out(do_blk_fast_out_q),
      .full(fifo_full), .empty(fifo_empty));
   //=========================================================================================


   //for debug only
   wire [DATA_WIDTH - 1 : 0] data_out_blk_fast;
   assign data_out_blk_fast = atom_data_out[0];
   
   wire blk_fast_out_valid;
   wire [`BITS_ROW_IDX - 1 : 0] blk_fast_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] blk_fast_out_value;      
   assign blk_fast_out_valid = data_out_blk_fast[0];
   assign blk_fast_out_row_idx = data_out_blk_fast[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   assign blk_fast_out_value = data_out_blk_fast[DATA_WIDTH - `BITS_ROW_IDX - 1 : DATA_WIDTH - `BITS_ROW_IDX - `DATA_PRECISION];
   
   
endmodule // merge_blk_fast_fifo_based
//
//---------------------------------------------------------------------------
//  2 input comparator
//  
//  
//---------------------------------------------------------------------------
//

module compare_select_simple #(
   parameter
     DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG)(			       
     //DATA_WIDTH = `DATA_WIDTH_ADD_STG) (
					
   input [DATA_WIDTH - 1 : 0] din0, din1,
   output logic 	      select);

   wire [`BITS_ROW_IDX - 1 : 0] rowidx0, rowidx1;
     
   assign rowidx0 = din0[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   assign rowidx1 = din1[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
      
always_comb begin   
   unique if (rowidx0 <= rowidx1) begin
      select = 1'b0;
   end
   else begin
      select = 1'b1;
   end
end   
endmodule
//
//---------------------------------------------------------------------------
// Fast merge stage comprising atoms   
//  
//  
//---------------------------------------------------------------------------
//

module merge_stage_fast_fifo_based 
  #(
    parameter
    NUM_ATOMS = 1,
    DATA_WIDTH = `DATA_WIDTH_ADD_STG)
   (//input
    input rst_b, clk, global_en, 
    input [NUM_ATOMS - 1 : 0] next_fifo_full, 
    input [(NUM_ATOMS << 1) - 1 : 0] fifo_wr_en,      
    input [(NUM_ATOMS << 1) - 1 : 0] [DATA_WIDTH - 1 : 0] data_in,
        
    //enable signals are generated inside the rd/wr cycle				      
    output [(NUM_ATOMS << 1) - 1 : 0] fifo_full,
    output [NUM_ATOMS - 1 : 0] next_fifo_wr_en,  	    
    output [NUM_ATOMS - 1 : 0] [DATA_WIDTH - 1 : 0] data_out);

   genvar i;
   generate
      for (i = 0; i < NUM_ATOMS; i = i + 1) begin 
	 merge_atom_fast_fifo_based atom
         (//input
	  .rst_b, .clk, .global_en, .next_fifo_full(next_fifo_full[i]),
          .f0_wr_en(fifo_wr_en[(i<<1)]), .f1_wr_en(fifo_wr_en[(i<<1) + 1]),
	  .din_f0(data_in[(i<<1)]), .din_f1(data_in[(i<<1) + 1]),
	  
	  //output
	  .next_fifo_wr_en(next_fifo_wr_en[i]),
	  .f0_full(fifo_full[(i<<1)]), .f1_full(fifo_full[(i<<1) + 1]),
	  .data_out(data_out[i]));
      end     
   endgenerate
   
endmodule 
   

	  
//
//---------------------------------------------------------------------------
//  Minimum building block of the fast merge network  
//  
//  
//---------------------------------------------------------------------------
//

module merge_atom_fast_fifo_based 
  #(
    parameter		   
    DATA_WIDTH = `DATA_WIDTH_ADD_STG,
    BITS_BLK_FAST_FIFO = `BITS_BLK_FAST_FIFO) 
   (//input
    input rst_b, clk, global_en, next_fifo_full, f0_wr_en, f1_wr_en,
    input [DATA_WIDTH - 1 : 0] din_f0, din_f1,
    
    //enable signals are generated inside the rd/wr cycle				      
    output next_fifo_wr_en, f0_full, f1_full, 			    
    output logic [DATA_WIDTH - 1 : 0] data_out);

   // Output Fifo for fast block
   //=========================================================================================
   wire f0_empty, f1_empty;
   logic f0_rd_en, f1_rd_en;
   wire [DATA_WIDTH - 1 : 0] dout_f0, dout_f1;
   			      
   sfifo #(.DSIZE(DATA_WIDTH), .ASIZE(BITS_BLK_FAST_FIFO)) f0
     (//input
      .clk, .rst_b, .rd_en(f0_rd_en), .wr_en(f0_wr_en),
      .data_in(din_f0),
      //output
      .data_out(dout_f0),
      .full(f0_full), .empty(f0_empty));
   
   sfifo #(.DSIZE(DATA_WIDTH), .ASIZE(BITS_BLK_FAST_FIFO)) f1
     (//input
      .clk, .rst_b, .rd_en(f1_rd_en), .wr_en(f1_wr_en),
      .data_in(din_f1),
      //output
      .data_out(dout_f1),
      .full(f1_full), .empty(f1_empty));  
   //=========================================================================================
  
   //=========================================================================================   
   //Comparator
   wire select;
   compare_select_simple #(.DATA_WIDTH(DATA_WIDTH)) comparator( 
     //input			       
     .din0(dout_f0), .din1(dout_f1), 
     //output			       
     .select);

   always_comb begin
      if (select == 1'b0) begin
	 data_out = dout_f0;
      end
      else begin
	 data_out = dout_f1;  
      end 
   end    
   //=========================================================================================

   logic atom_en;
   assign atom_en = global_en ? !next_fifo_full & !f0_empty & !f1_empty : 1'b0;
   assign next_fifo_wr_en = atom_en;
   assign f0_rd_en = atom_en && !select;
   assign f1_rd_en = atom_en && select;

   //just for debug
   wire f0_valid, f1_valid;
   wire [`BITS_ROW_IDX - 1 : 0] f0_row_idx, f1_row_idx;
   wire [`DATA_PRECISION - 1 : 0] f0_value, f1_value;      
   assign f0_valid = dout_f0[0];
   assign f0_row_idx = dout_f0[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   assign f0_value = dout_f0[DATA_WIDTH - `BITS_ROW_IDX - 1 : DATA_WIDTH - `BITS_ROW_IDX - `DATA_PRECISION];

   assign f1_valid = dout_f1[0];
   assign f1_row_idx = dout_f1[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
   assign f1_value = dout_f1[DATA_WIDTH - `BITS_ROW_IDX - 1 : DATA_WIDTH - `BITS_ROW_IDX - `DATA_PRECISION];
   
endmodule // merge_atom_fast_fifo_based
// single_adder_pipe3.v

// Generated using ACDS version 16.1 196

//---------------------------------------------------------------------------
// this module calculates the rd, wr and trach counter values for each block of input data
//
//  
//---------------------------------------------------------------------------
//
module single_adder_pipe3 (
	result,
	aclr,
	ax,
	ay,
	clk,
	ena)/* synthesis synthesis_greybox=0 */;
output reg 	[31:0] result;
input 	[1:0] aclr;
input 	[31:0] ax;
input 	[31:0] ay;
input 	clk;
input 	ena;

always @ (posedge clk)
if(aclr != 2'b00)
    result <= 'h0;
else if(ena)
  result = ax + ay;


endmodule

module input_fifo_ctr_calc
  #(//parameter
    NUM_UNITs = `NUM_UNITs,
    BITS_UNIT_SELECTION = `BITS_UNIT_SELECTION,
    UNIT_INIT_BIT = `UNIT_INIT_BIT,
    DATA_WIDTH = `BITS_ROW_IDX + `DATA_PRECISION,
    STREAM_WIDTH = `STREAM_WIDTH,
    LOG_STREAM_WIDTH = `LOG_STREAM_WIDTH,
    NUM_BIOTONIC_STGS_TOT = `NUM_BIOTONIC_STGS_TOT,
    NUM_ADDTREE_STGS = LOG_STREAM_WIDTH,
    EXTRA_DELAY_PIPE = NUM_BIOTONIC_STGS_TOT - NUM_ADDTREE_STGS - 1) //extra 1 cycle as we flop the incoming data first. So we need to delay the pipeline (6 - 3 - 1 = 2) cycles for 8 streaming width of the bitonic sort
   (input clk, rst_b, enable,   
    input [STREAM_WIDTH - 1 : 0][DATA_WIDTH - 1 : 0] din,

    output logic [NUM_UNITs - 1 : 0] [`BITS_INPUT_BIN_ADDR - 1 : 0] set_rd_ctr_pb, set_wr_ctr_pb,
    output logic [NUM_UNITs - 1 : 0] [`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_pb);

   logic [STREAM_WIDTH - 1 : 0] [`BITS_ROW_IDX - 1 : 0] index_adv;
   //assign index_adv[STREAM_WIDTH - 1 : 0] = din[STREAM_WIDTH - 1 : 0][DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];  
   always_comb begin      
      for (integer i11 = 0; i11 < STREAM_WIDTH; i11 = i11 + 1) begin
         index_adv[i11] = din[i11][DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
      end
   end 
  
   logic [STREAM_WIDTH - 1 : 0][BITS_UNIT_SELECTION - 1 : 0] radix, radix_adv;
   //assign radix_adv[STREAM_WIDTH - 1 : 0] = index[STREAM_WIDTH - 1 : 0][BITS_UNIT_SELECTION - 1 : 0];
   always_comb begin      
      for (integer i12 = 0; i12 < STREAM_WIDTH; i12 = i12 + 1) begin
         radix_adv[i12] = index_adv[i12][BITS_UNIT_SELECTION - 1 : 0];
      end
   end 
     
  register2D #(.WIDTH1(STREAM_WIDTH), .WIDTH2(BITS_UNIT_SELECTION)) reg_radix(.q(radix), .d(radix_adv), .clk(clk), .enable(enable), .rst_b(rst_b));

   //for track ctr
   //================================================================================
   //-----------------------------------------------------------
   //Comapring unit selection bits to see how many element each unit should get 
   logic [NUM_UNITs - 1 : 0][STREAM_WIDTH - 1 : 0] unit_match_flag;

   integer unsigned i0, i1;
   always_comb begin      
      for (i0 = 0; i0 < NUM_UNITs; i0 = i0 + 1) begin
	 for (i1 = 0; i1 < STREAM_WIDTH; i1 = i1 + 1) begin
            unit_match_flag[i0][i1] = (radix[i1] == i0) ? 1'b1 : 1'b0;
	 end
      end
   end
   //-----------------------------------------------------------
   //-----------------------------------------------------------
   //Adder tree
   //logic [NUM_UNITs - 1 : 0][STREAM_WIDTH - 1 : 0][LOG_STREAM_WIDTH - 1 : 0] addtree_din; 
   //logic [NUM_UNITs - 1 : 0][LOG_STREAM_WIDTH - 1 : 0] addtree_dout;
   logic [NUM_UNITs - 1 : 0][STREAM_WIDTH - 1 : 0][LOG_STREAM_WIDTH : 0] addtree_din; 
   logic [NUM_UNITs - 1 : 0][LOG_STREAM_WIDTH : 0] addtree_dout; 
   
   integer unsigned i2, i3;
   always_comb begin      
      for (i2 = 0; i2 < NUM_UNITs; i2 = i2 + 1) begin
	 for (i3 = 0; i3 < STREAM_WIDTH; i3 = i3 + 1) begin
            //addtree_din[i2][i3] = {{LOG_STREAM_WIDTH - 1{1'b0}}, unit_match_flag[i2][i3]};
	    addtree_din[i2][i3] = {{LOG_STREAM_WIDTH{1'b0}}, unit_match_flag[i2][i3]};
	 end
      end
   end 

   genvar j0;
    generate
       for (j0 = 0; j0 < NUM_UNITs; j0 = j0 + 1) begin
	  input_ctr_addtree #(.DATA_WIDTH(LOG_STREAM_WIDTH + 1)) addtree
	    (//input
	     .rst_b, .clk, .enable, 
	     .din(addtree_din[j0]), .dout(addtree_dout[j0]));
      end
    endgenerate  
   //-----------------------------------------------------------
   //================================================================================
   
    //for rd ctr
   //================================================================================
   //-----------------------------------------------------------
   //Comapring unit selection bits to see how many element each unit should get 
   logic [NUM_UNITs - 1 : 0][STREAM_WIDTH - 1 : 0] unit_match_flag_incr;

   integer unsigned i4, i5;
   always_comb begin
      unit_match_flag_incr[0] = '0;
      for (i4 = 1; i4 < NUM_UNITs; i4 = i4 + 1) begin
            unit_match_flag_incr[i4] = unit_match_flag[i4 - 1] | unit_match_flag_incr[i4 - 1] ;
      end
   end
   //-----------------------------------------------------------
   //-----------------------------------------------------------
   //Adder tree
   //logic [NUM_UNITs - 1 : 0][STREAM_WIDTH - 1 : 0][LOG_STREAM_WIDTH - 1 : 0] addtree_din_incr; 
   //logic [NUM_UNITs - 1 : 0][LOG_STREAM_WIDTH - 1 : 0] addtree_dout_incr; 
   logic [NUM_UNITs - 1 : 0][STREAM_WIDTH - 1 : 0][LOG_STREAM_WIDTH : 0] addtree_din_incr; 
   logic [NUM_UNITs - 1 : 0][LOG_STREAM_WIDTH : 0] addtree_dout_incr; 
   
   integer unsigned i6, i7;
   always_comb begin      
      for (i6 = 0; i6 < NUM_UNITs; i6 = i6 + 1) begin
	 for (i7 = 0; i7 < STREAM_WIDTH; i7 = i7 + 1) begin
            addtree_din_incr[i6][i7] = {{LOG_STREAM_WIDTH{1'b0}}, unit_match_flag_incr[i6][i7]};
	 end
      end
   end 

   genvar j1;
    generate
       for (j1 = 0; j1 < NUM_UNITs; j1 = j1 + 1) begin
	  input_ctr_addtree #(.DATA_WIDTH(LOG_STREAM_WIDTH + 1)) addtree_incr
	    (//input
	     .rst_b, .clk, .enable, 
	     .din(addtree_din_incr[j1]), .dout(addtree_dout_incr[j1]));
      end
    endgenerate  
   //-----------------------------------------------------------
   //================================================================================

   // Delay and final assignments
   //================================================================================
   ///logic [EXTRA_DELAY_PIPE : 0] [NUM_UNITs - 1 : 0][LOG_STREAM_WIDTH - 1 : 0] addtree_dout_temp, addtree_dout_incr_temp;
   logic [EXTRA_DELAY_PIPE : 0][NUM_UNITs - 1 : 0][LOG_STREAM_WIDTH : 0] addtree_dout_temp, addtree_dout_incr_temp;

   
   assign addtree_dout_temp[0] = addtree_dout;
   assign addtree_dout_incr_temp[0] = addtree_dout_incr;

   always_ff @(posedge clk) begin
     if (~rst_b)
       for (integer i8 = 1; i8 < EXTRA_DELAY_PIPE + 1; i8 = i8 + 1) begin
	  for (integer i9 = 0; i9 < NUM_UNITs; i9 = i9 + 1) begin
	     addtree_dout_temp[i8][i9] <= '0;
	     addtree_dout_incr_temp[i8][i9] <= '0;
	  end
       end
     else if (enable) begin
	for (integer i10 = 1; i10 < EXTRA_DELAY_PIPE + 1; i10 = i10 + 1) begin
	   addtree_dout_temp[i10] <= addtree_dout_temp[i10 - 1];
	   addtree_dout_incr_temp[i10] <= addtree_dout_incr_temp[i10 - 1];
	end
     end
   end

   ///assign set_rd_ctr_pb = addtree_dout_incr_temp[EXTRA_DELAY_PIPE][NUM_UNITs - 1 : 0][`BITS_INPUT_BIN_ADDR - 1 : 0];
   ///assign set_wr_ctr_pb = '0; //we probably don't care about wr counters
   ///assign set_track_ctr_pb = addtree_dout_temp[EXTRA_DELAY_PIPE];

   always_comb begin      
      for (integer i13 = 0; i13 < NUM_UNITs; i13 = i13 + 1) begin//shouldn't addtree_dout_x should have 1 bit more width? Change accordingly
         set_rd_ctr_pb[i13] = addtree_dout_incr_temp[EXTRA_DELAY_PIPE][i13][`BITS_INPUT_BIN_ADDR - 1 : 0];
	 set_wr_ctr_pb[i13] = '0;
	 set_track_ctr_pb[i13] = addtree_dout_temp[EXTRA_DELAY_PIPE][i13];
      end
   end 
   //================================================================================  
   
endmodule // input_fifo_ctr_calc


module input_ctr_addtree 
  #(//parameter
    STREAM_WIDTH = `STREAM_WIDTH,
    LOG_STREAM_WIDTH = `LOG_STREAM_WIDTH,
    NUM_ADDTREE_STGS = `LOG_STREAM_WIDTH,
    DATA_WIDTH = `LOG_STREAM_WIDTH + 1)
   (input rst_b, clk, enable, 
    input [STREAM_WIDTH - 1 : 0] [DATA_WIDTH - 1 : 0] din,			      
    output [DATA_WIDTH - 1 : 0] dout);

   wire [(1 << NUM_ADDTREE_STGS)*2 - 2 : 0] [DATA_WIDTH - 1 : 0] addtree_data; //addtree_data[0] is final output

   genvar j0;
   generate
      for (j0 = 0; j0 < NUM_ADDTREE_STGS; j0 = j0 + 1) begin
      	 input_ctr_addtree_stg #(.NUM_ATOMS(1 << j0), .DATA_WIDTH(LOG_STREAM_WIDTH + 1)) addtree_stg
           (//input										 
            .rst_b, .clk, .enable,
	    .din(addtree_data[(1 << (j0+2)) - 2 : (1 << (j0+1)) - 1]),
	    //output
	    .dout(addtree_data[(1 << (j0+1)) - 2 : (1 << j0) - 1]));
      end
   endgenerate

   assign dout = addtree_data[0];
   assign addtree_data[(1 << (NUM_ADDTREE_STGS + 1)) - 2 : (1 << NUM_ADDTREE_STGS) - 1] = din[STREAM_WIDTH - 1 : 0];
   
endmodule 


module input_ctr_addtree_stg 
  #(//parameter
    NUM_ATOMS = 1,
    DATA_WIDTH = `LOG_STREAM_WIDTH + 1)
   (input rst_b, clk, enable, 
    input [(NUM_ATOMS << 1) - 1 : 0] [DATA_WIDTH - 1 : 0] din,			      
    output [NUM_ATOMS - 1 : 0] [DATA_WIDTH - 1 : 0] dout);

   genvar j0;
   generate
      for (j0 = 0; j0 < NUM_ATOMS; j0 = j0 + 1) begin 
	 input_ctr_addtree_atom #(.DATA_WIDTH(DATA_WIDTH)) addtree_atom
         (//input
	  .rst_b, .clk, .enable,
	  .din0(din[(j0<<1)]), .din1(din[(j0<<1) + 1]),
	  //output
	  .dout(dout[j0]));
      end     
   endgenerate
endmodule // input_ctr_addtree_stg


module input_ctr_addtree_atom
  #(//parameter
    NUM_UNITs = `NUM_UNITs,
    DATA_WIDTH = `LOG_STREAM_WIDTH + 1) //because log of stream width is the bits needed for max add value
   (input clk, rst_b, enable,   
    input [DATA_WIDTH - 1 : 0] din0, din1,
    output [DATA_WIDTH - 1 : 0] dout);

   //==============================================================================
   //------------------------------------------------------------
   // Make the addtree entirely pipelined
   wire [DATA_WIDTH - 1 : 0] din0_reg, din1_reg;
   
   register #(.WIDTH(DATA_WIDTH)) reg_din0(.q(din0_reg), .d(din0), .clk(clk), .enable(enable), .rst_b(rst_b));
   register #(.WIDTH(DATA_WIDTH)) reg_din1(.q(din1_reg), .d(din1), .clk(clk), .enable(enable), .rst_b(rst_b)); 
   //------------------------------------------------------------
   //------------------------------------------------------------
   // Make the addtree entirely combinational
   //assign din0_reg = din0;
   //assign din1_reg = din1;
   //------------------------------------------------------------
   //==============================================================================

   assign dout = din0_reg + din1_reg;  
endmodule // input_ctr_addtree_atom



//
//---------------------------------------------------------------------------
// All the parallel slow merge blocks   
//
//  
//---------------------------------------------------------------------------
//

module merge_blk_slow_parallel_arr
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,
    NUM_SLOW_BLK = `NUM_SEG_PER_STG) 
   (//input
    input clk, rst_b, mode, unit_en,
    input [NUM_SLOW_BLK - 1 : 0] out_fifo_wr_ready_slow_adv,
    ////input [`NUM_STGs - 1 : 0] wr_addr_unit_input,
    input [NUM_SLOW_BLK - 1 : 0]  wr_en_unit_input,
    input [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] wr_addr_unit_input,
    input [NUM_SLOW_BLK - 1 : 0] [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [`DATA_WIDTH_INPUT - 1 : 0] data_in_unit, 
    input [NUM_SLOW_BLK - 1 : 0][`BITS_ROW_IDX - 1 : 0] maxidx_input, 
    input [NUM_SLOW_BLK - 1 : 0] fill_req_accepted_blk_slow,
    input [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_BIN_ADDR - 1 : 0] set_wr_ctr_input, set_rd_ctr_input,
    input [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_input,

    //output
    output [NUM_SLOW_BLK - 1 : 0] blk_en_adv, blk_en,   
    output [NUM_SLOW_BLK - 1 : 0] ini_blk_slow_done,
    output [NUM_SLOW_BLK - 1 : 0] send_fill_req_blk_slow,
    output [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] bin_to_fill_addr_blk_slow,
    output [NUM_SLOW_BLK - 1 : 0] [`NUM_INPUTs_PER_SEG_ARR - 1 : 0][`NUM_UNITs - 1 : 0] bin_empty_flags,
    output [NUM_SLOW_BLK - 1 : 0] [DATA_WIDTH - 1 : 0] data_out_blk_slow);

   genvar j1;
   generate
      for (j1 = 0; j1 < NUM_SLOW_BLK; j1 = j1 + 1) begin : slow_blocks_parr
	 merge_blk_slow blk_slow
	   (//input
	    .clk, .rst_b, .unit_en, .mode, .wr_en_input(wr_en_unit_input[j1]), 
	    .out_fifo_wr_ready_slow_adv(out_fifo_wr_ready_slow_adv[j1]),
	    .wr_addr_input(wr_addr_unit_input[j1]),
            .data_in_blk_slow(data_in_unit[j1]), .maxidx_input(maxidx_input[j1]), 
	    .fill_req_accepted(fill_req_accepted_blk_slow[j1]),
	    .set_wr_ctr_input(set_wr_ctr_input[j1]), .set_rd_ctr_input(set_rd_ctr_input[j1]), .set_track_ctr_input(set_track_ctr_input[j1]),
	    //output
	    .blk_en_adv(blk_en_adv[j1]), .blk_en(blk_en[j1]),
	    .ini_blk_slow_done(ini_blk_slow_done[j1]),
            .send_fill_req(send_fill_req_blk_slow[j1]),
            .bin_to_fill_addr_blk_slow(bin_to_fill_addr_blk_slow[j1]),
            .bin_empty_flags(bin_empty_flags[j1]),	    
	    .blk_out_data_tot(data_out_blk_slow[j1]));
      end
   endgenerate

endmodule // merge_blk_slow_parallel
//
//---------------------------------------------------------------------------
//  Block of the merge network using multiple segments 
//******** Note on synchronizing 'write address', 'write data' and 'write enable' *********
//Normally, 'write address', 'write data' and 'write enable' all are ready on the same clk cycle (t).
//However, for the 'write decoder', the 'write address' and 'write enable' has to be delayed one cycle because the event of wordline enable and writing actually happens in the next cycle (t+1). Nonetheless, the 'write enable' signal plugged into the memory blocks should be the non-delayed 'write enable' (t) signal. This is because this 'write enable' signal only triggers the Flop to latch the input data.   
//---------------------------------------------------------------------------
//

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
   output logic blk_en_adv, blk_en,
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

wire [`NUM_STGs - `END_OF_FAST_STG : 0] [DATA_WIDTH - 1 : 0] data_out_seg;   
					   
wire [`NUM_STGs - `END_OF_FAST_STG - 1 : 0] addr_seg_rd, addr_seg_wr;//only addr is reverse of stage order
wire [`NUM_STGs - `END_OF_FAST_STG - 1 : 0] adv_addr_seg_rd; 

//wire [(1<<(`NUM_STGs - `END_OF_FAST_STG))*2 - 2 : 0] wl_seg_rd, wl_seg_wr; //wordlines

wire [`BITS_ROW_IDX - 1 : 0] blk_out_row_idx;
wire [`DATA_PRECISION - 1 : 0] blk_out_value;
wire blk_out_valid;

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
//--------------------------------------------   
   
assign blk_out_data_tot = data_out_seg[0];
assign blk_out_row_idx = blk_out_data_tot[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX];
assign blk_out_value = blk_out_data_tot[DATA_WIDTH - `BITS_ROW_IDX -1 : DATA_WIDTH - `BITS_ROW_IDX - `DATA_PRECISION]; 
assign blk_out_valid = blk_out_data_tot[0]; 
   
wire [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] addr_seg_wr_temp, wr_addr_input_temp;
   
//assign addr_seg_wr_temp = (wr_en_input || (mode == `MODE_POPULATE_ZERO && unit_en)) ? wr_addr_input : addr_seg_rd;//---addr_seg_wr_temp is used both time while data input and zero propagation. This is because we have to sweep through the address. mode and unit_en are of same cycle. They can be used together in logic. 
assign addr_seg_wr_temp = (mode == `MODE_POPULATE_ZERO && unit_en) ? addr_seg_initialize_wr : addr_seg_rd;   
assign wr_addr_input_temp = (mode == `MODE_POPULATE_ZERO && unit_en) ? addr_seg_initialize_wr : wr_addr_input;
   
wire mandatory_bubble;
logic mode_reg;
register #(.WIDTH(1)) reg_mode(.q(mode_reg), .d(mode), .clk(clk), .enable(1'b1), .rst_b(rst_b));

wire blk_en_next; 
register #(.WIDTH(1)) reg_blk_en_next(.q(blk_en_next), .d(blk_en), .clk(clk), .enable(1'b1), .rst_b(rst_b));  
register #(.WIDTH(`NUM_STGs - `END_OF_FAST_STG)) reg_addr_seg_wr(.q(addr_seg_wr), .d(addr_seg_wr_temp), .clk(clk), .enable(1'b1), .rst_b(rst_b)); 

logic wr_pending, wr_pause, rd_en_buff_so_adv, rd_en_buff_so, wr_en_buff_so_adv, wr_en_buff_so, wr_en_input_temp;  
assign rd_en_buff_so_adv = (blk_en_adv & mode == `MODE_WORK) ? 1'b1 : 1'b0;
register #(.WIDTH(1)) reg_rd_en_buff_so(.q(rd_en_buff_so), .d(rd_en_buff_so_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));

assign wr_en_input_temp = (unit_en && mode == `MODE_POPULATE_ZERO && !ini_blk_slow_done) ? 1'b1 : wr_en_input;
   
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
///Rationale
/*
We want to sync write enable with blk_en_adv so that output fifo empty signal can be responded in the same cycle. So we want to pause any write if there were actually any wr_en_adv active in the cycle before blk_en_adv is deasserted. So we pause exactly at same state and resume from the same state when blk_en_adv is asserted again.  
 
 At the very beginning after blk_en_adv is asserted, only rd_en_adv is asserted. No wr_en_adv is asserted before the cycle blk_en_adv is deasserted. Therefore, we don't activate any wr pending signal. However, due to rd_en signal, write will happen in the consecutive cycles even though blk_en_adv is deasserted. We don't inhibit this write because this write was not actually harm even though fifo is empty. This is beacuse in the last blk_en_adv = 1 cycle there was no wr_en_adv active signal. So it is okay to write later and move one stage ahead in the pipeline.
 
 Moreover, the consecutive write after rd_en_adv is required initially as the correct adv_addr_seg_rd(7F after 3F) requires write to happen.
 
 It would be good to make sure blk_en_adv is not asserted before the consecutive write at initially.  
*/
   
//register #(.WIDTH(`NUM_STGs - `END_OF_FAST_STG), .RESET_VALUE(7'b1111111)) reg_adv_addr_seg_rd(.q(addr_seg_rd), .d(adv_addr_seg_rd), .clk(clk), .enable(blk_en_adv && mode == `MODE_WORK), .rst_b(rst_b));//actually we need 7'b1000000. Need to make sure rd_addr and adv_rd_addr is not the same for seg1. We need 3F as the initial value for adv_addr_seg_rdadv_addr_seg_rd

register #(.WIDTH(`NUM_STGs - `END_OF_FAST_STG), .RESET_VALUE('0)) reg_adv_addr_seg_rd(.q(addr_seg_rd), .d(adv_addr_seg_rd), .clk(clk), .enable(blk_en_adv && mode == `MODE_WORK), .rst_b(rst_b));   

/*   
//Use this only if you want shared decoder in ASIC 
decoder_blk_slow_rd decoder_rd(
   //input
   .decode_en_blk(blk_en_adv),
   .addr_seg(addr_seg_rd), //use this to read tag in advance      
   //output
   //.BLK_RE(BLK_RE_seg),				 
   .wl_seg(wl_seg_rd)); 
    
   wire wr_decode_en; 
   assign wr_decode_en = (mode_reg == `MODE_WORK && blk_en) ? 1'b1 : (mode == `MODE_POPULATE_ZERO && unit_en && !ini_blk_slow_done) ? 1'b1 : 1'b0;

decoder_blk_slow_wr decoder_wr(
   //input
   .decode_en_blk(wr_decode_en),
   .addr_seg(addr_seg_wr), 
   //output
   .wl_seg(wl_seg_wr));
*/
   
//Normally during bin refill blk_en should be 0. However, at the very first time when we are filling up the bins, we want to do the zero propagation (initialize the memory) too. So at the very beginning we will keep blk_en 1 (while the mode will be zero_propagation_mode) when at the same time we will be filling up the bins for the very first time. The write address sweep from first to last for bin filling is utilized in writiting zeros (and set the valit bit and the tag) in the segment memory.
   
//Note: To intialize the memories, we need to initialize (Zero Propagate) by making blk_en =1 amd mode=MODE_POPULATE_ZERO and sweep accoss the address space. But this will not initialize the memory at the input stage. To do that, we need to make wr_en_input=1 and propagate proper value. Note, for multiple units, we not necessarily initialize them with all 0 (because of radix sort).

//First stage/segment of the block 
//=============================================================================
    merge_segment #(.SEG0(1),    
          .NUM_BUFF_SO_WORDS_SEG(1),
	  .NUM_BRICK_SEG_VER(1), //brick is irrelevant here. We assign 1 just to use the same merge_segment module
          .DATA_WIDTH(DATA_WIDTH), .BITS_ADDR_SEG(1), .LIM_OR_REG(1)) seg_reg0(
	  //input										 
          .rst_b, .clk, .blk_en, .mode, .unit_en, .blk_en_adv, .ini_blk_slow_done, .mandatory_bubble,
          .wr_pending, .wr_pause, .rd_en_buff_so_adv, .rd_en_buff_so, .wr_en_buff_so_adv, .wr_en_buff_so,
          .rd_addr_seg(1'b0), //irrelevant for reg memory.Should put 0 as used to address the register
          .wr_addr_seg(1'b0), //irrelevant for reg memory.Should put 0 as used to address the register
	  .adv_rd_addr_seg(1'b0),	
          .adv_wr_addr_seg(1'b0),					    
	  //.rd_decoded_unchecked(wl_seg_rd[0]), 
          //.wr_decoded_unchecked(wl_seg_wr[0]),
          .data_in_seg(data_out_seg[1]),
	  //output   
          .adv_tag_addr_bit_for_next_stg(adv_addr_seg_rd[`BITS_INPUT_ADDR_SLOW_BLK - 1]),  			    
          .data_out_seg(data_out_seg[0]));
//=============================================================================

//Rest of the stages/segments of the block 
//=============================================================================
genvar i, j;
generate
   //for small segments (i.e. segments with reg based memory)
   for (j = 1; j < `START_OF_BIG_STG - `END_OF_FAST_STG; j = j + 1) begin  
      merge_segment #(
          .NUM_BUFF_SO_WORDS_SEG(1 << j),
	  .NUM_BRICK_SEG_VER(1),//brick is irrelevant here. We assign 1 just to use the same merge_segment module
          .DATA_WIDTH(DATA_WIDTH), .BITS_ADDR_SEG(j), .LIM_OR_REG(1)) seg_reg(
	  //input										 
          .rst_b, .clk, .blk_en, .mode, .unit_en, .blk_en_adv, .ini_blk_slow_done, .mandatory_bubble,
          .wr_pending, .wr_pause, .rd_en_buff_so_adv, .rd_en_buff_so, .wr_en_buff_so_adv, .wr_en_buff_so,
          .rd_addr_seg(addr_seg_rd[`BITS_INPUT_ADDR_SLOW_BLK - 1 : `BITS_INPUT_ADDR_SLOW_BLK - j]), 
          .wr_addr_seg(addr_seg_wr[`BITS_INPUT_ADDR_SLOW_BLK - 1 : `BITS_INPUT_ADDR_SLOW_BLK - j]),
          .adv_rd_addr_seg(adv_addr_seg_rd[`BITS_INPUT_ADDR_SLOW_BLK - 1 : `BITS_INPUT_ADDR_SLOW_BLK - j]),
	  .adv_wr_addr_seg(addr_seg_wr_temp[`BITS_INPUT_ADDR_SLOW_BLK - 1 : `BITS_INPUT_ADDR_SLOW_BLK - j]),
          //.rd_decoded_unchecked(wl_seg_rd[(1 << (j+1)) - 2 : (1 << j) - 1]), 
          //.wr_decoded_unchecked(wl_seg_wr[(1 << (j+1)) - 2 : (1 << j) - 1]),
          .data_in_seg(data_out_seg[j+1]),
	  //output	
          .adv_tag_addr_bit_for_next_stg(adv_addr_seg_rd[`BITS_INPUT_ADDR_SLOW_BLK - 1 - j]),    
          .data_out_seg(data_out_seg[j]));
   end 	

   //for big segments (i.e. segments with LiM based memory)
   for (i = `START_OF_BIG_STG - `END_OF_FAST_STG; i < `NUM_STGs - `END_OF_FAST_STG; i = i + 1) begin    
      merge_segment #(
          .NUM_BUFF_SO_WORDS_SEG(1 << i), 
          .NUM_BRICK_SEG_VER(1 << (i - `BITS_ADDR_LIM_BRICK)),		   
          .DATA_WIDTH(DATA_WIDTH), .BITS_ADDR_SEG(i), .LIM_OR_REG(0)) seg_lim(
	  //input										 
          .rst_b, .clk, .blk_en, .mode, .unit_en, .blk_en_adv, .ini_blk_slow_done, .mandatory_bubble,
	  .wr_pending, .wr_pause, .rd_en_buff_so_adv, .rd_en_buff_so, .wr_en_buff_so_adv, .wr_en_buff_so,
          .rd_addr_seg(addr_seg_rd[`BITS_INPUT_ADDR_SLOW_BLK - 1 : `BITS_INPUT_ADDR_SLOW_BLK - i]), 
          .wr_addr_seg(addr_seg_wr[`BITS_INPUT_ADDR_SLOW_BLK - 1 : `BITS_INPUT_ADDR_SLOW_BLK - i]),
          .adv_rd_addr_seg(adv_addr_seg_rd[`BITS_INPUT_ADDR_SLOW_BLK - 1 : `BITS_INPUT_ADDR_SLOW_BLK - i]),
	  .adv_wr_addr_seg(addr_seg_wr_temp[`BITS_INPUT_ADDR_SLOW_BLK - 1 : `BITS_INPUT_ADDR_SLOW_BLK - i]), 
          //.rd_decoded_unchecked(wl_seg_rd[(1 << (i+1)) - 2 : (1 << i) - 1]), 
          //.wr_decoded_unchecked(wl_seg_wr[(1 << (i+1)) - 2 : (1 << i) - 1]),
          .data_in_seg(data_out_seg[i+1]),
	  //output 
	  .adv_tag_addr_bit_for_next_stg(adv_addr_seg_rd[`BITS_INPUT_ADDR_SLOW_BLK - 1 - i]),     
          .data_out_seg(data_out_seg[i]));
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
    .rst_b, .clk, .unit_en, .mode, .rd_en_input_adv(rd_en_buff_so_adv), .rd_en_input(rd_en_buff_so), 
    .wr_en_input(wr_en_input_temp), .out_fifo_wr_ready_slow_adv, 
    .rd_addr_seg(addr_seg_rd),   
    .adv_rd_addr_seg(adv_addr_seg_rd), .wr_addr_input(wr_addr_input_temp), 
    .data_in_input(data_in_blk_slow), .maxidx_input,
    .fill_req_accepted,
    .set_wr_ctr_input, .set_rd_ctr_input, .set_track_ctr_input,   
    //output	  
    .blk_en_adv, .blk_en, .mandatory_bubble,			    
    .data_out_input(data_out_seg[`BITS_INPUT_ADDR_SLOW_BLK]),
    .send_fill_req,
    .bin_to_fill_addr_blk_slow,
    .bin_empty_flags);
//=============================================================================
			  
endmodule
//
//---------------------------------------------------------------------------
// Merge connects the clock divider with multiple merge units.   
//
//  
//---------------------------------------------------------------------------
//

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


   
   
//
//---------------------------------------------------------------------------
//  Segment with either lim or reg 
//  
//  
//---------------------------------------------------------------------------
//

module merge_segment_input #(
   parameter
     NUM_UNITs = `NUM_UNITs, 
     NUM_INPUT_WORDS_SEG = `NUM_INPUTs_PER_SEG_ARR * `INPUT_BIN_SIZE,
     NUM_BRICK_SEG_VER = NUM_INPUT_WORDS_SEG >> `BITS_ADDR_LIM_BRICK,
     NUM_BRICK_SEG_VER_WO_BIN = `NUM_INPUTs_PER_SEG_ARR >> `BITS_ADDR_LIM_BRICK,		   
     DATA_WIDTH = `DATA_WIDTH_INPUT,
     WORD_WIDTH = `WORD_WIDTH_INPUT,			     
     BITS_ADDR_SEG = `BITS_ADDR_SEG,
     BITS_ADDR_FILL_REQ_Q = `BITS_ADDR_FILL_REQ_Q) (
											 
   input rst_b, clk, unit_en, mode, rd_en_input_adv, rd_en_input, wr_en_input, out_fifo_wr_ready_slow_adv, 
   input [BITS_ADDR_SEG - 1 : 0] rd_addr_seg,
   input [BITS_ADDR_SEG - 1 : 0] adv_rd_addr_seg, wr_addr_input,  
   input [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [WORD_WIDTH - 1 : 0] data_in_input,
   input [`BITS_ROW_IDX - 1 : 0] maxidx_input, 
   input fill_req_accepted,
   input [`BITS_INPUT_BIN_ADDR - 1 : 0] set_wr_ctr_input, set_rd_ctr_input, 
   input [`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_input, 

   //output
   output logic blk_en_adv, blk_en, mandatory_bubble, 
   output [`DATA_WIDTH_BUFF_SO_SEG - 1 : 0] data_out_input,
   output send_fill_req,
   output [BITS_ADDR_SEG - 1 : 0] bin_to_fill_addr_blk_slow,
   output logic [`NUM_INPUTs_PER_SEG_ARR - 1 : 0][NUM_UNITs - 1 : 0] bin_empty_flags);

wire global_en;
assign global_en = (mode == `MODE_WORK) && unit_en; 
    
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
//assign data_in_row_idx = data_in_input[`DATA_WIDTH_INPUT - 1 : `DATA_WIDTH_INPUT - `BITS_ROW_IDX];
//assign data_in_value = data_in_input[`DATA_WIDTH_INPUT - `BITS_ROW_IDX -1 : 0];

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
   
logic adv_rd_wr_addr_match_flag, rd_wr_addr_match_flag;  
//assign rd_wr_addr_match_flag = wr_en_input_reg && (wr_addr_input_reg == rd_addr_seg) && (blk_en && mode_reg == `MODE_WORK) ? 1'b1 : 1'b0;
assign adv_rd_wr_addr_match_flag = wr_en_input && (wr_addr_input == adv_rd_addr_seg) ? 1'b1 : 1'b0;//dnt use rn_en as this flag is needed for blk_en_adv signal
assign rd_wr_addr_match_flag = wr_en_input_reg && rd_en_input && (wr_addr_input_reg == rd_addr_seg) ? 1'b1 : 1'b0;
//****************************************************************************************
   
//Bin empty flags   
//========================================================================================      
///logic [`NUM_INPUTs_PER_SEG_ARR - 1 : 0][NUM_UNITs - 1 : 0] bin_empty_flags;
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
/*   
always_ff @ (posedge clk) begin //make sure to integrate global_en now as input stage is also 0 initialized
   if(~rst_b) begin
      for (i = 0; i < `NUM_INPUTs_PER_SEG_ARR; i = i + 1) begin
	 fifo_track_ctr[i] <= '0;
	 bin_rd_addr_ctr[i] <= '0;
	 bin_wr_addr_ctr[i] <= '0;
      end
   end
   else if((rd_en_input_adv == wr_en_input) && (adv_rd_addr_seg == wr_addr_input)) begin
      fifo_track_ctr[adv_rd_addr_seg] <=  fifo_track_ctr[adv_rd_addr_seg];
      bin_rd_addr_ctr[adv_rd_addr_seg] <= rd_en_input_adv ? bin_rd_addr_ctrPlus1 : bin_rd_addr_ctr[adv_rd_addr_seg];
      bin_wr_addr_ctr[wr_addr_input] <= wr_en_input ? bin_wr_addr_ctrPlus1 : bin_wr_addr_ctr[wr_addr_input];
   end
   else if(rd_en_input_adv && ~wr_en_input && (adv_rd_addr_seg == wr_addr_input)) begin
      fifo_track_ctr[adv_rd_addr_seg] <= fifo_track_ctrMinus1;
      bin_rd_addr_ctr[adv_rd_addr_seg] <= bin_rd_addr_ctrPlus1;
      bin_wr_addr_ctr[wr_addr_input] <= bin_wr_addr_ctr[wr_addr_input];
   end
   else if(~rd_en_input_adv && wr_en_input && (adv_rd_addr_seg == wr_addr_input)) begin
      fifo_track_ctr[wr_addr_input] <= fifo_track_ctrPlus1;
      bin_rd_addr_ctr[adv_rd_addr_seg] <= bin_rd_addr_ctr[adv_rd_addr_seg];
      bin_wr_addr_ctr[wr_addr_input] <= bin_wr_addr_ctrPlus1;
   end  
   else begin
      fifo_track_ctr[adv_rd_addr_seg] <= rd_en_input_adv ? fifo_track_ctrMinus1 : fifo_track_ctr[adv_rd_addr_seg];
      fifo_track_ctr[wr_addr_input] <= wr_en_input ? fifo_track_ctrPlus1 : fifo_track_ctr[wr_addr_input];
      bin_rd_addr_ctr[adv_rd_addr_seg] <= rd_en_input_adv ? bin_rd_addr_ctrPlus1 : bin_rd_addr_ctr[adv_rd_addr_seg];
      bin_wr_addr_ctr[wr_addr_input] <= wr_en_input ? bin_wr_addr_ctrPlus1 : bin_wr_addr_ctr[wr_addr_input];
   end   
end 
*/
always_ff @ (posedge clk) begin //make sure to integrate global_en now as input stage is also 0 initialized
   if(~rst_b) begin
      for (i = 0; i < `NUM_INPUTs_PER_SEG_ARR; i = i + 1) begin
	 fifo_track_ctr[i] <= '0;
	 bin_rd_addr_ctr[i] <= '0;
	 bin_wr_addr_ctr[i] <= '0;
      end
   end/*
   else if(global_en && wr_en_input) begin      
      fifo_track_ctr[wr_addr_input] <= set_track_ctr_input;
      bin_rd_addr_ctr[wr_addr_input] <= set_rd_ctr_input;
      bin_wr_addr_ctr[wr_addr_input] <= set_wr_ctr_input;
   end
   else if(global_en && rd_en_input_adv && !bin_empty && ~wr_en_input) begin
      fifo_track_ctr[adv_rd_addr_seg] <= fifo_track_ctrMinus1;
      bin_rd_addr_ctr[adv_rd_addr_seg] <= bin_rd_addr_ctrPlus1;
   end*/
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
///assign fill_req_q_rd_en = global_en && fill_req_accepted;   
///assign send_fill_req = global_en && !fill_req_q_empty; //send_fill_req remains active until accepted
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

//---------------------------------------------------------------------
//this is due to separating the logic after memory read + put it in separate pipeline. So throughput will be 1 element/2 cycles
//logic mandatory_bubble; 
always_ff @ (posedge clk) begin
   if(~rst_b) begin
      mandatory_bubble <= 1'b0;
   end
   else if (blk_en_adv) begin
      mandatory_bubble <= 1'b1; //when this is 1, actual rd/wr happens in SRAM
   end
   else begin
      mandatory_bubble <= 1'b0;
   end
end      
//---------------------------------------------------------------------

////assign blk_en_adv = (mode == `MODE_WORK) && unit_en & out_fifo_wr_ready_slow_adv & !bin_empty;
///assign blk_en_adv = (mode == `MODE_WORK) && unit_en & out_fifo_wr_ready_slow_adv; //we don't need to need to check whether fill q is writable and log_fill_req is asserted. This is because the q is long enough to log one request for each list.

//assign blk_en_adv = (mode == `MODE_WORK) && unit_en && out_fifo_wr_ready_slow_adv && !adv_rd_wr_addr_match_flag;
assign blk_en_adv = (mode == `MODE_WORK) && unit_en && out_fifo_wr_ready_slow_adv && !adv_rd_wr_addr_match_flag && !mandatory_bubble;
//we incorporated rd_wr_addr_match_flag because when data is written, even if we want to read the last element of the bin (as the bin is empty and want to move on), the element read will be something unwanted due to write //we don't need to need to check whether fill q is writable and log_fill_req is asserted. This is because the q is long enough to log one request for each list.  
   
register #(.WIDTH(1)) reg_blk_en(.q(blk_en), .d(blk_en_adv), .clk(clk), .enable(1'b1), .rst_b(rst_b));

//========================================================================================   

//Decoding from the bin counters & the entire input for the segment
//========================================================================================
wire [BITS_ADDR_SEG + `BITS_INPUT_BIN_ADDR - 1 : 0] adv_rd_addr_seg_w_bin, wr_addr_input_w_bin;
wire [`BITS_INPUT_BIN_ADDR - 1 : 0] highest_rd_addr_ctr;
assign highest_rd_addr_ctr = '1;

wire [`BITS_ROW_IDX - 1 : 0] dout_maxidx, dout_maxidx_reg;
   
///assign adv_rd_addr_seg_w_bin = {current_rd_addr_ctr, adv_rd_addr_seg};
assign adv_rd_addr_seg_w_bin = bin_empty ? {highest_rd_addr_ctr, adv_rd_addr_seg} : {current_rd_addr_ctr, adv_rd_addr_seg};
assign wr_addr_input_w_bin = {current_wr_addr_ctr, wr_addr_input};
     
///assign data_out_input = {data_out_input_wo_tag_valid, 1'b1, 1'b1};    
///assign data_out_input = bin_empty_prev ? {data_out_input_wo_tag_valid[DATA_WIDTH - 1 : DATA_WIDTH - `BITS_ROW_IDX], `DATA_PRECISION'b0, 1'b0, 1'b0} : {data_out_input_wo_tag_valid, 1'b1, 1'b1}; 
///assign data_out_input = bin_empty_prev ? {dout_maxidx, `DATA_PRECISION'b0, 1'b0, 1'b0} : {data_out_input_wo_tag_valid, 1'b1, 1'b1}; 
assign data_out_input = bin_empty_prev ? {dout_maxidx_reg, `DATA_PRECISION'b0, 1'b0} : {data_out_input_wo_tag_valid, 1'b1}; 
   
wire [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [WORD_WIDTH - 1 : 0] data_in_input_temp;
assign data_in_input_temp = (mode == `MODE_POPULATE_ZERO && unit_en) ? '0 : data_in_input; //Also need to zero initialize input bins. This is because we read the the last bins rowidx even if bin is empty.
   
segment_memory_input_sram #(
    //.NUM_INPUT_WORDS_SEG(NUM_INPUT_WORDS_SEG), .NUM_BRICK_SEG_VER(NUM_BRICK_SEG_VER), .NUM_BRICK_SEG_VER_WO_BIN(NUM_BRICK_SEG_VER_WO_BIN), .BITS_ADDR_SEG(BITS_ADDR_SEG)) seg_mem_input_lim (//for lim
    .NUM_INPUT_WORDS_SEG(NUM_INPUT_WORDS_SEG), .NUM_BRICK_SEG_VER(NUM_BRICK_SEG_VER), .NUM_BRICK_SEG_VER_WO_BIN(NUM_BRICK_SEG_VER_WO_BIN), .BITS_ADDR_SEG(BITS_ADDR_SEG), .NUM_DUMMY_BITS(0)) seg_mem_input_bram ( //for bram  	
    //input
    .rst_b, .clk, .mandatory_bubble,
    .rd_en_adv(rd_en_input_adv), .wr_en_adv(wr_en_input),
    .adv_rd_wr_addr_match_flag, .rd_wr_addr_match_flag,
    .adv_rd_addr_seg_w_bin, .wr_addr_input_w_bin,			 
    .data_in_input(data_in_input_temp),
    //output											 
    .data_out_input_wo_tag_valid);
//========================================================================================   

//============================================================================
// Maximum index storage
   bram_m20k #(.BL_WIDTH(`BITS_ROW_IDX), .ADDR_WIDTH(BITS_ADDR_SEG), .WL_WIDTH(`NUM_INPUTs_PER_SEG_ARR)) maximum_index_input(.CLK(clk), .rd_en(rd_en_input_adv), .wr_en(wr_en_input), .rd_addr(adv_rd_addr_seg), .wr_addr(wr_addr_input), .WBL(maxidx_input), .ARBL(dout_maxidx));

   //we flop it because now the pipeline for logic is separate
   register #(.WIDTH(`BITS_ROW_IDX)) reg_dout_maxidx(.q(dout_maxidx_reg), .d(dout_maxidx), .clk, .enable(mandatory_bubble), .rst_b(rst_b));
   
//============================================================================        
     
   //just for debug
   wire seg_out_valid;
   wire [`BITS_ROW_IDX - 1 : 0] seg_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] seg_out_value; 
   ///assign seg_out_valid = data_out_input[`VALID_INDEX_DATA_BUFF_SO_SEG];///temp
   assign seg_out_valid = data_out_input[0];///temp
   assign seg_out_row_idx = data_out_input[`DATA_WIDTH_BUFF_SO_SEG - 1 : `DATA_WIDTH_BUFF_SO_SEG - `BITS_ROW_IDX];
   assign seg_out_value = data_out_input[`DATA_WIDTH_BUFF_SO_SEG - `BITS_ROW_IDX - 1 : `DATA_WIDTH_BUFF_SO_SEG - `BITS_ROW_IDX - `DATA_PRECISION];   
   		     
endmodule
//
//---------------------------------------------------------------------------
//  Segment with either lim or reg 
//  
//  
//---------------------------------------------------------------------------
//

module merge_segment #(
   parameter
     SEG0 = 0, //pass 1 for segment 0		       
     NUM_BUFF_SO_WORDS_SEG = `NUM_BUFF_SO_WORDS_SEG,
     NUM_BRICK_SEG_VER = `NUM_BRICK_SEG_VER,		   
     DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,	       
     BITS_ADDR_SEG = `BITS_ADDR_SEG,
     LIM_OR_REG = 0) ( //0 means SRAM based memory and 1 means reg based memory
											 
   input rst_b, clk, blk_en, mode, unit_en, blk_en_adv, ini_blk_slow_done, mandatory_bubble,
   input wr_pending, wr_pause, rd_en_buff_so_adv, rd_en_buff_so, wr_en_buff_so_adv, wr_en_buff_so,
   input [BITS_ADDR_SEG - 1 : 0] rd_addr_seg, wr_addr_seg,
   input [BITS_ADDR_SEG - 1 : 0] adv_rd_addr_seg, adv_wr_addr_seg,		          
   //input [NUM_BUFF_SO_WORDS_SEG - 1 : 0] rd_decoded_unchecked, wr_decoded_unchecked,
   input [DATA_WIDTH - 1 : 0] data_in_seg,
   				      
   output adv_tag_addr_bit_for_next_stg,			    
   output [DATA_WIDTH - 1 : 0] data_out_seg);

   //just for waveform viewing purpose and debug
   //=============================================================================
   wire seg_out_valid, seg_out_tag, seg_in_valid, seg_in_tag;
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
    
wire tag_bit_for_incoming_data;    
logic [DATA_WIDTH - 1 : 0] data_in_buff, data_in_so;
wire [DATA_WIDTH - 1 : 0] data_out_buff;
//wire [DATA_WIDTH - 1 : 0] data_in_seg_w_new_tag;
wire [DATA_WIDTH - 1 : 0] smaller_row, bigger_row;
   
wire valid_data_in_seg, valid_data_out_buff;
   
logic [NUM_BUFF_SO_WORDS_SEG - 1 : 0] tag_column_so; 
logic [NUM_BUFF_SO_WORDS_SEG - 1 : 0] decoded_reg_type_mem;  

logic rd_wr_addr_match_flag, mode_reg, adv_rd_wr_addr_match_flag;

register #(.WIDTH(1)) reg_mode(.q(mode_reg), .d(mode), .clk(clk), .enable(1'b1), .rst_b(rst_b)); 
					       
assign valid_data_in_seg = data_in_seg[0];
assign valid_data_out_buff = data_out_buff[0];
//assign rd_wr_addr_match_flag = (blk_en && (rd_addr_seg == wr_addr_seg) && (mode_reg == `MODE_WORK)) ? 1'b1 : 1'b0;
//assign rd_wr_addr_match_flag = wr_en_buff_so_reg && blk_en && (rd_addr_seg == wr_addr_seg) && (mode_reg == `MODE_WORK) ? 1'b1 : 1'b0; //only raise this flag when it is a legitimate match, that is both addr match algorithmwise. If blk_en = 0, in the next cycle both the addr will also match, but this match is NOT legitimate

assign adv_rd_wr_addr_match_flag = wr_en_buff_so_adv && (adv_wr_addr_seg == adv_rd_addr_seg) && (blk_en_adv && mode == `MODE_WORK) ? 1'b1 : 1'b0;   
assign rd_wr_addr_match_flag = wr_en_buff_so && (wr_addr_seg == rd_addr_seg) && (blk_en && mode_reg == `MODE_WORK) ? 1'b1 : 1'b0; //wr_en_buff_so (and wr_addr_seg) is one cycle delayed than rd_en_buff_so(and rd_addr_seg). Anywway, wr_addr_seg is the addr being written in current cycle. 
// only raise this flag when it is a legitimate match, that is both addr match algorithmwise. If blk_en = 0, in the next cycle both the addr will also match, but this match is NOT legitimate   
   
assign data_in_seg_w_new_tag = data_in_seg;   

//Tag bit control
//========================================================================================   
wire tag_bit_so_adv, tag_addr_bit_for_next_stg;  
wire [BITS_ADDR_SEG - 1 : 0] tag_wr_addr;
logic tag_bit_din_so;

assign tag_wr_addr = adv_wr_addr_seg;
   
always_ff @(posedge clk) begin    
   if(~rst_b) begin
      tag_column_so <= '0;
   end
   //write
   else if(wr_en_buff_so_adv) begin   
      tag_column_so[adv_wr_addr_seg] <= tag_bit_din_so; 
   end
end 
   
assign tag_bit_so_adv = tag_column_so[adv_rd_addr_seg];
  
//this is theoritical new tag for incoming data
assign tag_bit_for_incoming_data = (SEG0 == 1 || (rd_addr_seg == adv_rd_addr_seg)) ? tag_bit_so_adv : tag_addr_bit_for_next_stg;
   
//this contributes the address bit for the next stage      
assign adv_tag_addr_bit_for_next_stg = (SEG0 == 1 || (rd_addr_seg == adv_rd_addr_seg))? tag_bit_din_so : tag_bit_so_adv;
   
register #(.WIDTH(1)) reg_tag_addr_bit_for_next_stg(.q(tag_addr_bit_for_next_stg), .d(adv_tag_addr_bit_for_next_stg), .clk(clk), .enable(wr_en_buff_so_adv), .rst_b(rst_b));
//========================================================================================   

wire select;
compare_select_simple #(.DATA_WIDTH(`DATA_WIDTH_ADD_STG)) comparator( 
   //input
   .din0(data_out_buff), .din1(data_in_seg), //data_out_buff should get preference. So it is imporatnt to assign is in the first input port din0
   //output			       
   .select);
   
always_comb begin: compare
   if (mode == `MODE_WORK) begin //don't make in mode_reg. we want same cycle data as unit_en.
      if (select == 1'b0) begin
	 data_in_buff = data_in_seg;
	 data_in_so = data_out_buff;
	 tag_bit_din_so = !tag_bit_for_incoming_data;
      end
      else begin
 	 data_in_buff = data_out_buff;
	 data_in_so = data_in_seg;
	 tag_bit_din_so = tag_bit_for_incoming_data;  
      end 
   end 
   else begin 
      //data_in_buff = {{DATA_WIDTH - 2{1'b0}}, 2'b00};//make invalid and BUFF tags all 0 in zero prop mode
      //data_in_so = {{DATA_WIDTH - 2{1'b0}}, 2'b01};//make invalid and SO tags all 1 in zero prop mode
      data_in_buff = '0;//make invalid and BUFF tags all 0 in zero prop mode
      data_in_so = '0;//make invalid and SO tags all 1 in zero prop mode
      tag_bit_din_so = 1'b1;
   end 
end // block: compare   
   
generate 
   if (LIM_OR_REG == 0) begin : segment_memory  
      segment_memory_sram #(
          //.NUM_BUFF_SO_WORDS_SEG(NUM_BUFF_SO_WORDS_SEG), .NUM_BRICK_SEG_VER(NUM_BRICK_SEG_VER), .BITS_ADDR_SEG(BITS_ADDR_SEG)) seg_mem_lim ( //for lim
          .NUM_BUFF_SO_WORDS_SEG(NUM_BUFF_SO_WORDS_SEG), .NUM_BRICK_SEG_VER(NUM_BRICK_SEG_VER), .BITS_ADDR_SEG(BITS_ADDR_SEG), .NUM_DUMMY_BITS(0)) seg_mem_bram ( //for bram	
  
          //input
          .rst_b, .clk, .mandatory_bubble,
	  .rd_en_adv(rd_en_buff_so_adv), .wr_en_adv(wr_en_buff_so_adv),
	  .adv_rd_wr_addr_match_flag, .rd_wr_addr_match_flag,
	  .adv_rd_addr_seg, .adv_wr_addr_seg,
          .data_in_buff, .data_in_so,
          //output		 
          .dout_buff(data_out_buff), .dout_so(data_out_seg));
   end 

   else begin : segment_memory
      segment_memory_reg #(
          .NUM_BUFF_SO_WORDS_SEG(NUM_BUFF_SO_WORDS_SEG), .BITS_ADDR_SEG(BITS_ADDR_SEG)) seg_mem_reg (
          //input
          .rst_b, .clk, .mandatory_bubble,
	  .wr_en(wr_en_buff_so_adv),
	  .rd_addr_seg,	
	  .adv_wr_addr_seg,							      
          .data_in_buff, .data_in_so,							     
          //output				    
          .dout_buff(data_out_buff), .dout_so(data_out_seg));      
   end 
endgenerate
		     
		     
endmodule
//
//---------------------------------------------------------------------------
// Merge unit connects the fast and slow blocks (without the adders)   
//
//  
//---------------------------------------------------------------------------
//

module merge_unit 
  #(
    parameter
    DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,
    TI = `TAG_INDEX_DATA_BUFF_SO_SEG,
    VI = `VALID_INDEX_DATA_BUFF_SO_SEG,
    DIV_RATIO_HALF = `DIV_RATIO_HALF,
    SLOW_BLK_BUFF_SIZE = `SLOW_BLK_BUFF_SIZE,
    BITS_SLOW_BLK_BUFF_ADDR = `BITS_SLOW_BLK_BUFF_ADDR,
    NUM_SLOW_BLK = `NUM_SEG_PER_STG) 
   (//input
    input clk, clk_slow, rst_b, unit_en, mode, buff_stq_full,
    input [NUM_SLOW_BLK - 1 : 0]  wr_en_unit_input,
    input [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] wr_addr_unit_input,
    input [NUM_SLOW_BLK - 1 : 0] [`BLK_SLOW_PARR_WR_NUM - 1 : 0] [`DATA_WIDTH_INPUT - 1 : 0] data_in_unit, 
    input [NUM_SLOW_BLK - 1 : 0][`BITS_ROW_IDX - 1 : 0] maxidx_input, 
    input [NUM_SLOW_BLK - 1 : 0] fill_req_accepted_blk_slow,
    input [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_BIN_ADDR - 1 : 0] set_wr_ctr_input, set_rd_ctr_input, 
    input [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_BIN_ADDR : 0] set_track_ctr_input,

    //output
    output ini_unit_done,
    output [NUM_SLOW_BLK - 1 : 0] send_fill_req_blk_slow,
    output [NUM_SLOW_BLK - 1 : 0] [`BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] bin_to_fill_addr_blk_slow,
    output [NUM_SLOW_BLK - 1 : 0] [`NUM_INPUTs_PER_SEG_ARR - 1 : 0][`NUM_UNITs - 1 : 0] bin_empty_flags,
    output unit_out_valid,
    output [`BITS_ROW_IDX - 1 : 0] unit_out_row_idx, 
    output [`DATA_PRECISION - 1 : 0] unit_out_value);

   //Slow block signals
   wire [NUM_SLOW_BLK - 1 : 0] out_fifo_wr_ready_slow_adv, out_fifo_wr_ready_slow;
   wire [NUM_SLOW_BLK - 1 : 0] [DATA_WIDTH - 1 : 0] data_out_blk_slow;
   wire [NUM_SLOW_BLK - 1 : 0] blk_en_adv, blk_en;
   wire [NUM_SLOW_BLK - 1 : 0] ini_blk_slow_done;
   assign ini_unit_done = &ini_blk_slow_done;
         
   //Fast block signals
   wire blk_fast_rd_en_stg0, rd_ready_blk_fast_out_q;
   wire [NUM_SLOW_BLK - 1 : 0] en_intake_fifo_slow_blk;
   wire [`DATA_WIDTH_ADD_STG - 1 : 0] do_blk_fast_out_q;
 
   //FIFO signals
   wire [NUM_SLOW_BLK - 1 : 0] [`DATA_WIDTH_ADD_STG - 1 : 0] data_out_fifo;
   wire [NUM_SLOW_BLK - 1 : 0] fifo_empty_slow_blk_out;
   
   //Add stage signals
   wire [`DATA_WIDTH_ADD_STG - 1 : 0] data_out_merge_unit;
   wire accum_en, accum_out_q_rd_ready;
      
   //Connecting the modules   
   //=========================================================================================
   merge_blk_slow_parallel_arr blk_slow_parr //make it blk_slow_parr
     (//input
      .clk(clk_slow), .rst_b, .mode, .unit_en,
      .out_fifo_wr_ready_slow_adv,
      //.out_fifo_wr_ready_slow_adv(4'b1111), //just for test
      .wr_en_unit_input,
      .wr_addr_unit_input, .data_in_unit, .maxidx_input,
      .fill_req_accepted_blk_slow,
      .set_wr_ctr_input, .set_rd_ctr_input, .set_track_ctr_input,	
     
      //output
      .blk_en_adv, .blk_en,
      .ini_blk_slow_done,
      .send_fill_req_blk_slow, .bin_to_fill_addr_blk_slow, 
      .bin_empty_flags,	    
      .data_out_blk_slow);
   
   afifo_top_slow_fast blk_afifo_slow_fast  
     (//input
      .clk, .clk_slow, .rst_b, .unit_en, .mode,
      .next_stg_rd_en(blk_fast_rd_en_stg0), .blk_en_adv_slow(blk_en_adv),
      .data_out_blk_slow,  
      .en_intake_fifo_slow_blk, 
      
      //output	
      .fifo_empty(fifo_empty_slow_blk_out),
      .out_fifo_wr_ready_slow, .out_fifo_wr_ready_slow_adv,
      .data_out_fifo);
   
   merge_blk_fast_fifo_based blk_fast 
     (//input
      .clk, .rst_b, .mode, .unit_en, 
      .next_blk_rd_en(accum_en),
      //.next_blk_rd_en(rd_ready_blk_fast_out_q), //debug only
      .data_in_blk_fast(data_out_fifo),
      .prev_blk_fifo_empty(fifo_empty_slow_blk_out),
     
      //output
      .blk_fast_rd_en_stg0, .rd_ready_blk_fast_out_q,
      .en_intake_fifo_slow_blk,					  
      .do_blk_fast_out_q);

   wire rd_en_accum_blk;
   
   accum_blk accum_blk 
     (//input
      .clk, .rst_b, .unit_en, .mode, .data_ended(1'b0), 
      .prev_blk_rd_ready(rd_ready_blk_fast_out_q), 
      //.next_blk_rd_en(accum_out_q_rd_ready),//debug only
      .next_blk_rd_en(!buff_stq_full),
      .di(do_blk_fast_out_q),
      
      //output
      .en_blk(accum_en), .out_q_rd_ready(accum_out_q_rd_ready), 
      .do_accum_blk_out_q(data_out_merge_unit));   

   assign rd_en_accum_blk = accum_out_q_rd_ready && !buff_stq_full && data_out_merge_unit[0];
      
   //=========================================================================================
   
   wire blk_fast_out_valid;
   wire [`BITS_ROW_IDX - 1 : 0] blk_fast_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] blk_fast_out_value;      
   assign blk_fast_out_valid = do_blk_fast_out_q[0];
   assign blk_fast_out_row_idx = do_blk_fast_out_q[`DATA_WIDTH_ADD_STG - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX];
   assign blk_fast_out_value = do_blk_fast_out_q[`DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - `DATA_PRECISION];

    
   assign unit_out_valid = rd_en_accum_blk;//original
   //assign unit_out_valid = data_out_merge_unit[0];///temp
   assign unit_out_row_idx = data_out_merge_unit[`DATA_WIDTH_ADD_STG - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX];
   assign unit_out_value = data_out_merge_unit[`DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - 1 : `DATA_WIDTH_ADD_STG - `BITS_ROW_IDX - `DATA_PRECISION];

endmodule // merge_unit
//
//---------------------------------------------------------------------------
// intermediate buffer for big blocks of DRAM page+connects with memory interface   
// include the data compression and radix sorting in here. receive the data from dram, decompress it and
// put it in different bins using radix sort. use async fifo as the bin. Probably we should replace the input segment bins with this async fifo   
//---------------------------------------------------------------------------
//

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
//
//---------------------------------------------------------------------------
// This modules dcontrols the data coming from DRAM and does the radix sort + calculates the proper value for the bin counters
//
//  
//---------------------------------------------------------------------------
//

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

//
//---------------------------------------------------------------------------
// Merge unit connects the fast and slow blocks (without the adders)   
//
//  
//---------------------------------------------------------------------------
//

module radixsort_pb_interface 
  #(
    parameter
    NUM_UNITs = `NUM_UNITs,
    NUM_INPUTs_PER_SEG_ARR = `NUM_INPUTs_PER_SEG_ARR,
    BITS_INPUT_ADDR_SLOW_BLK = `BITS_INPUT_ADDR_SLOW_BLK) 
   (//input
    input clk_slow, rst_b, unit_en, mode, fill_req_accept_ready,
    input [NUM_UNITs - 1 : 0][NUM_INPUTs_PER_SEG_ARR - 1 : 0][NUM_UNITs - 1 : 0] bin_empty_flags,
    input [NUM_UNITs - 1 : 0] send_fill_req_blk_slow,
    input [NUM_UNITs - 1 : 0][BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] bin_to_fill_addr_blk_slow,
    
    //output
    output [NUM_UNITs - 1 : 0] fill_req_accepted_blk_slow, 
    output logic [BITS_INPUT_ADDR_SLOW_BLK - 1 : 0] bin_to_fill_addr,   
    output send_fill_req);

   wire global_en;
   assign global_en = (mode == `MODE_WORK) && unit_en; 

   //Checking other units' bin empty status
   //========================================================================================    
   wire [NUM_UNITs - 1 : 0] fill_req_manyhot, fill_req_onehot;
   logic [NUM_UNITs - 1 : 0][NUM_UNITs - 1 : 0] bin_empty_flags_temp;
   //logic [NUM_INPUTs_PER_SEG_ARR - 1 : 0][NUM_UNITs - 1 : 0][NUM_UNITs - 1 : 0] bin_empty_flags_temp;
   
   always_comb begin      
      for (integer i1 = 0; i1 < NUM_UNITs; i1 = i1 + 1) begin
	 for (integer i2 = 0; i2 < NUM_UNITs; i2 = i2 + 1) begin
	    bin_empty_flags_temp[i1][i2] = bin_empty_flags[i2][bin_to_fill_addr_blk_slow[i1]][i1];
	 end
      end
   end
      
   genvar j0;
   generate
      for (j0 = 0; j0 < NUM_UNITs; j0 = j0 + 1) begin : fill_all
	 /////assign fill_req_manyhot[j0] = &bin_empty_flags[NUM_UNITs - 1 : 0][bin_to_fill_addr_blk_slow[j0]][j0] && send_fill_req_blk_slow[j0];
	 assign fill_req_manyhot[j0] = &bin_empty_flags_temp[j0] && send_fill_req_blk_slow[j0];
	 //assign fill_req_accepted_blk_slow[j0] = send_fill_req_blk_slow[j0] && (!fill_req_manyhot[j0] || (fill_req_onehot[j0] && fill_req_accept_ready));
	 assign fill_req_accepted_blk_slow[j0] = send_fill_req_blk_slow[j0] && (!fill_req_manyhot[j0] || (fill_req_manyhot[j0] && (bin_to_fill_addr_blk_slow[j0] == bin_to_fill_addr)  && send_fill_req && fill_req_accept_ready));

//if for some unit, fill_req_manyhot bit is 0 but there is a fill req, then it will get a fill_req_accepted signal so that the unit can move on. The same req will be be served some other time later when all other units are empty for that list. But all other unit is empty (i.e. fill_rq_manyhot bit is 1), then the accepted will signal will not be sent until the fill request is logged by the page_buffer.sv module. If for any list fill req is sent and accepted, then any other unit asking for the same list should also receive a fill_req_accepted asserted signal.  
      end      
   endgenerate
   assign send_fill_req = |fill_req_manyhot;
   //========================================================================================

   // Arbiter with fairness
   //========================================================================================
   //Generating the priority with fairness
   //------------------------------------------------
   logic [NUM_UNITs - 1 : 0] priority_onehot; //the hot bits sets the highest priority
   wire [NUM_UNITs - 1 : 0] next_priority_onehot; //needed for one bit circular shifter

   generate
      if (NUM_UNITs == 1) begin : priority_base
	 assign next_priority_onehot = priority_onehot;
      end
      else begin : priority_base
	 assign next_priority_onehot = {priority_onehot[NUM_UNITs - 2 : 0], priority_onehot[NUM_UNITs - 1]};
      end
   endgenerate

   always_ff @ (posedge clk_slow) begin
      if(~rst_b) begin
      	 priority_onehot <= 1;
      end
      else if (global_en) begin
	 priority_onehot <= next_priority_onehot; //changing priority every cycle to ensure fairness
      end
   end 
   //------------------------------------------------
   
   arbiter #(.WIDTH(NUM_UNITs))  arbiter (.req(fill_req_manyhot),.grant(fill_req_onehot),.base(priority_onehot));
   //========================================================================================

/*   // Arbiter without fairness
   //========================================================================================
   bitscan #(.WIDTH(NUM_UNITs)) arbiter (.req(fill_req_manyhot),.sel(fill_req_onehot));;
   //========================================================================================
*/   

   //Sending a single fill request using wide_ANDOR_ mux. ref: https://www.doulos.com/knowhow/fpga/multiplexer/
   // break the comb path and put this in new pipeline stage if this is critical path
   //========================================================================================
   always_comb begin      
      bin_to_fill_addr = '0;
      for (integer i0 = 0; i0 < NUM_UNITs; i0 = i0 + 1) begin
	if (fill_req_onehot[i0] == 1'b1) begin
            bin_to_fill_addr = bin_to_fill_addr_blk_slow[i0];
	 end
      end
   end 
   
   //========================================================================================
  
  
endmodule 
//// register: A register which may be reset to an arbirary value
////
//// q      (output) - Current value of register
//// d      (input)  - Next value of register
//// clk    (input)  - Clock (positive edge-sensitive)
//// enable (input)  - Load new value?
//// reset  (input)  - System reset
////
module register(q, d, clk, enable, rst_b);
   parameter
     WIDTH = 1,
     RESET_VALUE = 0;
   
   output reg [WIDTH - 1 : 0] q;
   input [WIDTH - 1 : 0]  d;
   input clk, enable, rst_b;

   always_ff @(posedge clk) begin
     if (~rst_b)
       q <= RESET_VALUE;
     else if (enable)
       q <= d;
   end
endmodule // register

module register2D(q, d, clk, enable, rst_b);
   parameter
     WIDTH1 = 1,
     WIDTH2 = 1,
     RESET_VALUE = 0;
   
   output reg [WIDTH1 - 1 : 0] [WIDTH2 - 1 : 0] q;
   input [WIDTH1 - 1 : 0] [WIDTH2 - 1 : 0] d;
   input clk, enable, rst_b;

   always_ff @(posedge clk) begin
     if (~rst_b)
       for (integer i=0; i < WIDTH1; i = i+1) begin
	  q[i] <= RESET_VALUE;
       end
     else if (enable)
       q <= d;
   end
endmodule // register


module delay(q, d, clk, enable, rst_b);
   parameter
     WIDTH = 1,
     RESET_VALUE = 0,
     DEPTH = 1;
     
   output reg [WIDTH - 1 : 0] q; 
   input [WIDTH - 1 : 0]  d;
   input clk, enable, rst_b;

   wire [WIDTH - 1 : 0] connect_wire[DEPTH : 0] ;
   assign connect_wire[0] = d;
   assign q = connect_wire[DEPTH];
 
   genvar i;
   generate
      for (i = 1; i <= DEPTH; i = i + 1) begin : delay_reg_arr
	 register #(.WIDTH(WIDTH), .RESET_VALUE(RESET_VALUE)) DFF(.q(connect_wire[i]), .d(connect_wire[i-1]), .clk(clk), .enable(enable), .rst_b(rst_b));
      end   
   endgenerate 
endmodule // delay


//
//---------------------------------------------------------------------------
// LiM memory block for segment for both buffer and stage output
//  
//  
//---------------------------------------------------------------------------
//

module segment_memory_reg #(
   parameter
     NUM_BUFF_SO_WORDS_SEG = `NUM_BUFF_SO_WORDS_SEG,	   
     DATA_WIDTH = `DATA_WIDTH_BUFF_SO_SEG,
     BITS_ADDR_SEG = `BITS_ADDR_SEG) (

   input rst_b, clk, wr_en, mandatory_bubble,
   input [BITS_ADDR_SEG - 1 : 0] rd_addr_seg, 
   input [BITS_ADDR_SEG - 1 : 0] adv_wr_addr_seg,  
   input [DATA_WIDTH - 1 : 0] data_in_buff, data_in_so,
							  
   output logic [DATA_WIDTH - 1 : 0] dout_buff, dout_so);

//reg memory
//valiables with unpacked are not displayed in NCSim simulation, but works fine   
logic [NUM_BUFF_SO_WORDS_SEG - 1 : 0] [DATA_WIDTH - 1 : 0] buff_reg;   
logic [NUM_BUFF_SO_WORDS_SEG - 1 : 0] [DATA_WIDTH - 1 : 0] so_reg;

integer i; 
always_ff @(posedge clk) begin    
   if(~rst_b) begin
      for (i = 0; i < NUM_BUFF_SO_WORDS_SEG; i = i + 1) begin
	 buff_reg[i] <=  0; 
	 so_reg[i] <=  0;
      end
   end
   //write
   else if(wr_en && rst_b) begin
      buff_reg[adv_wr_addr_seg] <= data_in_buff;
      so_reg[adv_wr_addr_seg] <= data_in_so;
   end
end   

//this is for nonpipelined version. technically this will functionally work for pipelined version too   
//assign dout_buff = buff_reg[rd_addr_seg];
//assign dout_so = so_reg[rd_addr_seg];

//this is for pipelined version
register #(.WIDTH(DATA_WIDTH)) reg_dout_buff(.q(dout_buff), .d(buff_reg[rd_addr_seg]), .clk, .enable(mandatory_bubble), .rst_b(rst_b));
register #(.WIDTH(DATA_WIDTH)) reg_dout_so(.q(dout_so), .d(so_reg[rd_addr_seg]), .clk, .enable(mandatory_bubble), .rst_b(rst_b));   
   

//********** INPUT FLOPS **********  
/*
integer i;
always_ff @ (posedge clk) begin
   if(~rst_b) begin
      for (i = 0; i < NUM_BUFF_SO_WORDS_SEG; i = i + 1) begin
	 buff_reg[i] <=  0; 
	 so_reg[i] <=  0;
      end
   end
   else begin
      for (i = 0; i < NUM_BUFF_SO_WORDS_SEG; i = i + 1) begin
	 buff_reg[i] <= decoded_reg_type_mem[i] ? data_in_buff : buff_reg[i]; //even though writing, we use rd wl in WORK mode
	 so_reg[i] <= decoded_reg_type_mem[i] ? data_in_so : so_reg[i];// as we need wl ready before clk edge. This is because FLOP is generated by the tool. After the clock edge, whatever wordline is active immediately, data will be written to that. We activate the wordlines in the same cycle where data is written. For registers, it will not allow the time needed to activate the wordlines from address. So the data may get corrupted for registers. For LiM, this is not an issue as it acts as a black box and wordline activation delay and data write is taken care of internally. For read, this issue is not a problem for registers either. Because for registers, read process doesn't have to be flopped and corruption cannot happen. In the worst case, data will show up at the BLs late because of the wordline activation delay. 
      end
   end
end
*/
endmodule

//
//---------------------------------------------------------------------------
// Synchronous FIFO   
//
//  
//---------------------------------------------------------------------------
//

module sfifo
  #(parameter 
   DSIZE = `DATA_WIDTH_ADD_STG,
   ASIZE = `BITS_ADDER_OUT_Q,
   FIFO_DEPTH = 1 << ASIZE)
  (//input
   input clk, rst_b, rd_en, wr_en,
   input [DSIZE-1:0] data_in, 
   output [DSIZE-1:0] data_out,
   output empty, full);    

//-----------Internal variables-------------------
reg [ASIZE - 1 : 0] wr_pointer;
reg [ASIZE - 1 : 0] rd_pointer;
reg [ASIZE : 0] status_cnt;
////wire [DSIZE - 1 : 0] data_ram ;

//-----------Variable assignments---------------
////assign full = (status_cnt == (RAM_DEPTH-1));
assign full = (status_cnt == (FIFO_DEPTH));   
assign empty = (status_cnt == 0);

//-----------Code Start---------------------------
always_ff @(posedge clk) begin : WRITE_POINTER
  if (!rst_b) begin
    wr_pointer <= 0;
  end else if (wr_en && !full) begin
    wr_pointer <= wr_pointer + 1;
  end
end

always_ff @(posedge clk) begin : READ_POINTER
  if (!rst_b) begin
    rd_pointer <= 0;
  end else if (rd_en && !empty) begin
    rd_pointer <= rd_pointer + 1;
  end
end

/*
always_ff  @(posedge clk) begin : READ_DATA
  if (!rst_b) begin
    data_out <= 0;
  end else if (rd_cs && rd_en ) begin
    data_out <= data_ram;
  end
end
*/
 
always_ff @(posedge clk) begin : STATUS_COUNTER
  if (!rst_b) begin
    status_cnt <= 0;
  // Read but no write.
  end else if (rd_en && !wr_en && (status_cnt != 0)) begin
    status_cnt <= status_cnt - 1;
  // Write but no read.
  end else if (wr_en && !rd_en && (status_cnt != FIFO_DEPTH)) begin
    status_cnt <= status_cnt + 1;
  end
end 
   
fifomem_syn #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifomem
(.data_out, .data_in,
.waddr(wr_pointer), .raddr(rd_pointer), .wr_en, .full, .empty, .clk);      
endmodule

//=========================== Buffer ==================================
module fifomem_syn 
  #(parameter 
    DSIZE = `DATA_WIDTH_ADD_STG, // Memory data word width
    ASIZE = `BITS_ADDER_OUT_Q,
    FIFO_DEPTH = 1 << ASIZE) // Number of mem address bits
   (//input
    input [DSIZE - 1 : 0] data_in,
    input [ASIZE - 1 : 0] waddr, raddr,
    input wr_en, clk, full, empty,
    output [DSIZE - 1 : 0] data_out);
   
   // RTL Verilog memory model
   reg [DSIZE - 1 : 0] mem [0 : FIFO_DEPTH - 1];
   //assign data_out = mem[raddr];//ori
   assign data_out = !empty ? mem[raddr] : '0; //so that we don't need to initialize memory
   always_ff @(posedge clk) begin
     if (wr_en && !full) mem[waddr] <= data_in;
   end
endmodule
//=====================================================================
//
//---------------------------------------------------------------------------
// store queue connection for single unit   
//
//  
//---------------------------------------------------------------------------
//

module stq_buff_unit
  #(//parameter
    NUM_UNITs = `NUM_UNITs, 
    STQ_BUFF_DEPTH = `STQ_BUFF_RATIO_2DATA,
    BITS_STQ_BUFF_PER_UNIT = `BITS_STQ_BUFF_PER_UNIT,
    UNIT_INIT_BIT = `UNIT_INIT_BIT,
    DATA_WIDTH = UNIT_INIT_BIT + `DATA_PRECISION)
   (input clk, rst_b, global_en, rd_en, 
    input [UNIT_INIT_BIT - 1 : 0] svc_threshold_idx, svc_idx,
    input unit_out_valid,
    input [`BITS_ROW_IDX - 1 : 0] unit_out_row_idx,
    input [`DATA_PRECISION - 1 : 0] unit_out_value,
    
    output svc_ready, stq_buff_full,
    output [`DATA_PRECISION - 1 : 0] do_stq_buff);

   // Storage
   //==============================================================================
   wire rd_en_stq_buff, wr_en_stq_buff, stq_buff_empty, deliver;
   wire [DATA_WIDTH  - 1 : 0] di_stq_buff, do_stq_buff_ori;
   wire [UNIT_INIT_BIT - 1 : 0] di_idx, last_stored_idx;

   assign di_idx = unit_out_row_idx[`BITS_ROW_IDX - 1 : `BITS_ROW_IDX - UNIT_INIT_BIT];
   assign di_stq_buff = {di_idx, unit_out_value};
   assign wr_en_stq_buff = global_en && unit_out_valid && !stq_buff_full;
   assign rd_en_stq_buff = svc_ready && deliver ? rd_en : 1'b0;
   			
   sfifo #(.DSIZE(DATA_WIDTH), .ASIZE(BITS_STQ_BUFF_PER_UNIT)) stq_buff
     (//input
      .clk, .rst_b, .rd_en(rd_en_stq_buff), .wr_en(wr_en_stq_buff),
      .data_in(di_stq_buff),
      //output
      .data_out(do_stq_buff_ori),
      .full(stq_buff_full), .empty(stq_buff_empty)); 
   //==============================================================================

   wire [UNIT_INIT_BIT - 1 : 0] do_idx;
   wire [`DATA_PRECISION - 1 : 0] do_value;

   assign deliver = (do_idx == svc_idx);
   assign do_idx = do_stq_buff_ori[DATA_WIDTH - 1 : DATA_WIDTH - UNIT_INIT_BIT];
   assign do_stq_buff = deliver ? do_stq_buff_ori[`DATA_PRECISION - 1 : 0] : '0;

   register #(.WIDTH(UNIT_INIT_BIT)) reg_last_stored_idx(.q(last_stored_idx), .d(di_idx), .clk(clk), .enable(wr_en_stq_buff), .rst_b(rst_b));
   assign svc_ready = (last_stored_idx >= svc_threshold_idx) ? 1'b1 : 1'b0;
      
endmodule // stq_buff_unit
//
//---------------------------------------------------------------------------
// store queue connection for single unit   
//
//  
//---------------------------------------------------------------------------
//

module stq_interface
  #(//parameter
    DONE_IDX = 512,
    NUM_UNITs = `NUM_UNITs,
    UNIT_INIT_BIT = `UNIT_INIT_BIT,
    STQ_DATA_WIDTH = `STQ_DATA_WIDTH,
    SVC_TH_FIRST = `STQ_BUFF_MIN_RATIO_2DATA - 1)
   (//LDQ signals
    input clk, rst_b, unit_en, mode, stq_ready, 
    input [NUM_UNITs - 1 : 0] unit_out_valid,
    input [NUM_UNITs - 1 : 0] [`BITS_ROW_IDX - 1 : 0] unit_out_row_idx,
    input [NUM_UNITs - 1 : 0] [`DATA_PRECISION - 1 : 0] unit_out_value,
    
    output [NUM_UNITs - 1 : 0] stq_buff_full,
    output stq_valid, done,
    output [STQ_DATA_WIDTH - 1 : 0] stq_data);

   wire global_en;
   assign global_en = (mode == `MODE_WORK) && unit_en;
   
   //Connecting stq buffs
   //==============================================================================
   wire [NUM_UNITs - 1 : 0][`DATA_PRECISION - 1 : 0] do_stq_buff;
   wire [NUM_UNITs - 1 : 0] svc_ready;
   wire rd_en;
   wire [UNIT_INIT_BIT - 1 : 0] svc_threshold_idx, svc_idx, svc_threshold_idx_adv, svc_idx_adv;
   
   assign rd_en = stq_valid && stq_ready;
   assign stq_valid = global_en && (&svc_ready);
   
   genvar j0;
   generate
      for (j0 = 0; j0 < NUM_UNITs; j0 = j0 + 1) begin : stq_unit
	 
	 stq_buff_unit stq_buff_unit
	   (//input 
	    .clk, .rst_b, .global_en, .rd_en, 
	    .svc_threshold_idx, .svc_idx,
	    .unit_out_valid(unit_out_valid[j0]),
            .unit_out_row_idx(unit_out_row_idx[j0]),
	    .unit_out_value(unit_out_value[j0]),
	    //output
	    .svc_ready(svc_ready[j0]), .stq_buff_full(stq_buff_full[j0]),
	    .do_stq_buff(do_stq_buff[j0]));

	 assign stq_data[STQ_DATA_WIDTH - 1 - `DATA_PRECISION*j0 : STQ_DATA_WIDTH - `DATA_PRECISION*(j0+1)] = do_stq_buff[j0];
      end
   endgenerate
   //==============================================================================

   //Store queue data deliver controls 
   //==============================================================================
   wire inc_svc_th, inc_svc_idx;
   assign svc_threshold_idx_adv = svc_threshold_idx + `STQ_BUFF_MIN_RATIO_2DATA;
   assign svc_idx_adv = svc_idx + 1'b1;

   assign inc_svc_idx = rd_en;
   assign inc_svc_th = inc_svc_idx && (svc_idx == svc_threshold_idx);
   
   register #(.WIDTH(UNIT_INIT_BIT), .RESET_VALUE(SVC_TH_FIRST)) reg_svc_threshold_idx(.q(svc_threshold_idx), .d(svc_threshold_idx_adv), .clk(clk), .enable(inc_svc_th), .rst_b(rst_b));
   register #(.WIDTH(UNIT_INIT_BIT)) reg_svc_idx(.q(svc_idx), .d(svc_idx_adv), .clk(clk), .enable(inc_svc_idx), .rst_b(rst_b));
   //==============================================================================

   wire en_done;
   assign en_done = inc_svc_idx && (svc_idx == DONE_IDX);
   register #(.WIDTH(1)) reg_done(.q(done), .d(1'b1), .clk(clk), .enable(en_done), .rst_b(rst_b));
   
endmodule // stq_interface

module async_lsq 
#(parameter DDR_DATA_WIDTH =512,
            LDQ_DATA_WIDTH =512,
            STQ_DATA_WIDTH =256,
            ADDR_WIDTH =32,
            QPTR_WIDTH =4, // bit width
            NUM_LDQ    =4,
            NUM_STQ    =1, 
            TOTAL_LDQ_IDS = 512,
            TOTAL_STQ_IDS = 1,
            BASE_ADDR_WIDTH = 20)
(
  input                             ldq_clk,
  input                             stq_clk,
  input                             rstn,
  input                             ddr_clk,
  input                             ddr_rstn,
  input  [NUM_LDQ-1:0]              ldq_valid,
  output [NUM_LDQ-1:0]              ldq_ready,
  input  [NUM_LDQ*7-1+8:0]            ldq_id,
  input  [NUM_STQ*7-1:0]            stq_id,
  output [NUM_LDQ-1:0]              ldq_data_valid,
  output [LDQ_DATA_WIDTH*NUM_LDQ-1:0]   ldq_data,
  input  [NUM_LDQ-1:0]              ldq_data_ready,
  input                             spmv_done,
  
// for stq
  input [NUM_STQ-1:0]               stq_valid,
  output[NUM_STQ-1:0]               stq_ready,
  input [STQ_DATA_WIDTH*NUM_STQ-1:0]    stq_data,
// for base address
  input [BASE_ADDR_WIDTH * TOTAL_LDQ_IDS -1 :0]        rchannel_addr_base,
  input [BASE_ADDR_WIDTH * TOTAL_STQ_IDS -1 :0]        wchannel_addr_base,
//ddr part
  output [NUM_LDQ-1:0]              ldq_ddr_addr_valid,
  input  [NUM_LDQ-1:0]              ldq_ddr_addr_ready,
  output [NUM_LDQ*ADDR_WIDTH-1:0]   ldq_ddr_addr,
  input  [NUM_LDQ-1:0]              ldq_ddr_data_valid,
//output  NUM_LDQ                   ldq_ddr_data_ready, // data slot should be pre-allocated. hence always ready
  input  [NUM_LDQ*DDR_DATA_WIDTH-1:0]   ldq_ddr_data,


  output [NUM_STQ-1:0]              stq_ddr_valid,
  input  [NUM_STQ-1:0]              stq_ddr_ready,
  output [NUM_STQ*ADDR_WIDTH-1:0]   stq_ddr_addr,
  output [NUM_STQ*DDR_DATA_WIDTH-1:0]   stq_ddr_data
);

genvar ii, jj;

generate 
  for(ii =0; ii <NUM_LDQ; ii= ii+1)
  begin
      load_queue 
      #(.LDQ_DATA_WIDTH(LDQ_DATA_WIDTH), .DDR_DATA_WIDTH(DDR_DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH), .QPTR_WIDTH(QPTR_WIDTH), .IDS_NUM(TOTAL_LDQ_IDS/NUM_LDQ), .BASE_ADDR_WIDTH(BASE_ADDR_WIDTH))
      u_load_queue
      (
          .sys_clk       (ldq_clk           ),
          .sys_rstn      (rstn              ),

          .req_valid     (ldq_valid[ii]),
          .req_id        (ldq_id[9*(ii+1)-1:9*ii]),
          .req_ready     (ldq_ready[ii]),
          .addr_base     (rchannel_addr_base[BASE_ADDR_WIDTH*(TOTAL_LDQ_IDS/NUM_LDQ)*(ii+1)-1:BASE_ADDR_WIDTH * (TOTAL_LDQ_IDS/NUM_LDQ)*ii]),

          .data_valid    (ldq_data_valid[ii]    ),
          .data_ready    (ldq_data_ready[ii]    ),
          .data          (ldq_data[LDQ_DATA_WIDTH*(ii+1)-1:LDQ_DATA_WIDTH*ii]),
          

          .ddr_clk       (ddr_clk           ),
          .ddr_rstn      (ddr_rstn          ),

          .ddr_addr_valid(ldq_ddr_addr_valid[ii]),
          .ddr_addr_ready(ldq_ddr_addr_ready[ii]),
          .ddr_addr      (ldq_ddr_addr[ADDR_WIDTH*(ii+1)-1:ADDR_WIDTH*ii]),

          .ddr_data_valid(ldq_ddr_data_valid[ii]),
          .ddr_data      (ldq_ddr_data[DDR_DATA_WIDTH*(ii+1)-1:DDR_DATA_WIDTH*ii])
      );
    end
endgenerate

generate 
    for(jj =0; jj <NUM_STQ; jj= jj+1)
    begin
      store_queue  
      #(.DDR_DATA_WIDTH(DDR_DATA_WIDTH), .STQ_DATA_WIDTH(STQ_DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH), .QPTR_WIDTH(QPTR_WIDTH), .IDS_NUM(TOTAL_STQ_IDS/NUM_STQ), .BASE_ADDR_WIDTH(BASE_ADDR_WIDTH))
      u_store_queue
      (
        .sys_clk  (stq_clk),
        .sys_rstn (rstn  ),
        .req_valid(stq_valid[jj]     ),
        .req_ready(stq_ready[jj]     ),
        .req_id   (stq_id   [7*(jj+1) -1 : 7*jj]),
        .data     (stq_data[STQ_DATA_WIDTH*(jj+1)-1:STQ_DATA_WIDTH*jj]      ),
        .addr_base(wchannel_addr_base[BASE_ADDR_WIDTH*(TOTAL_STQ_IDS/NUM_STQ)*(jj+1)-1:BASE_ADDR_WIDTH * (TOTAL_STQ_IDS/NUM_STQ)*jj]),
        .spmv_done (spmv_done),

        .ddr_clk  (ddr_clk   ),
        .ddr_rstn (ddr_rstn  ),
        .ddr_valid(stq_ddr_valid[jj] ),
        .ddr_ready(stq_ddr_ready[jj] ),
        .ddr_addr (stq_ddr_addr[ADDR_WIDTH*(jj+1)-1:ADDR_WIDTH*jj]  ),
        .ddr_data (stq_ddr_data[DDR_DATA_WIDTH*(jj+1)-1:DDR_DATA_WIDTH*jj]  )
    );
    end
endgenerate

endmodule
module spmv_func
#(parameter DDR_DATA_WIDTH = 512, LDQ_DATA_WIDTH=512, STQ_DATA_WIDTH=256,ADDR_WIDTH=32, NUM_LDQ =4, NUM_STQ =1, TOTAL_LDQ_IDS=512, TOTAL_STQ_IDS=1, BASE_ADDR_WIDTH=20)
(
  input                                          clock,
  input                                          resetn,
  input                                          m_valid_in,
  output                                         m_ready_out,
  output                                         m_valid_out,
  input                                          m_ready_in,

  input  [31:0]                                  spmv_mode,
  input  [31:0]                                  spmv_enable,
  output [31:0]                                  spmv_status,
  input [63 :0]                                  rchannel_addr_base,
  input [63 :0]                                  rchannel0_addr_base,
  input [63 :0]                                  rchannel1_addr_base,
  input [63 :0]                                  rchannel2_addr_base,
  input [63 :0]                                  rchannel3_addr_base,
  input [63 :0]                                  rchannel4_addr_base,
  input [63 :0]                                  rchannel5_addr_base,
  input [63 :0]                                  rchannel6_addr_base,
  input [63 :0]                                  rchannel7_addr_base,
  input [63 :0]                                  rchannel8_addr_base,
  input [63 :0]                                  rchannel9_addr_base,
  input [63 :0]                                  rchannel10_addr_base,
  input [63 :0]                                  rchannel11_addr_base,
  input [63 :0]                                  rchannel12_addr_base,
  input [63 :0]                                  rchannel13_addr_base,
  input [63 :0]                                  rchannel14_addr_base,
  input [63 :0]                                  rchannel15_addr_base,
  input [63 :0]                                  rchannel16_addr_base,
  input [63 :0]                                  rchannel17_addr_base,
  input [63 :0]                                  rchannel18_addr_base,
  input [63 :0]                                  rchannel19_addr_base,
  input [63 :0]                                  rchannel20_addr_base,
  input [63 :0]                                  rchannel21_addr_base,
  input [63 :0]                                  rchannel22_addr_base,
  input [63 :0]                                  rchannel23_addr_base,
  input [63 :0]                                  rchannel24_addr_base,
  input [63 :0]                                  rchannel25_addr_base,
  input [63 :0]                                  rchannel26_addr_base,
  input [63 :0]                                  rchannel27_addr_base,
  input [63 :0]                                  rchannel28_addr_base,
  input [63 :0]                                  rchannel29_addr_base,
  input [63 :0]                                  rchannel30_addr_base,
  input [63 :0]                                  rchannel31_addr_base,
  input [63 :0]                                  rchannel32_addr_base,
  input [63 :0]                                  rchannel33_addr_base,
  input [63 :0]                                  rchannel34_addr_base,
  input [63 :0]                                  rchannel35_addr_base,
  input [63 :0]                                  rchannel36_addr_base,
  input [63 :0]                                  rchannel37_addr_base,
  input [63 :0]                                  rchannel38_addr_base,
  input [63 :0]                                  rchannel39_addr_base,
  input [63 :0]                                  rchannel40_addr_base,
  input [63 :0]                                  rchannel41_addr_base,
  input [63 :0]                                  rchannel42_addr_base,
  input [63 :0]                                  rchannel43_addr_base,
  input [63 :0]                                  rchannel44_addr_base,
  input [63 :0]                                  rchannel45_addr_base,
  input [63 :0]                                  rchannel46_addr_base,
  input [63 :0]                                  rchannel47_addr_base,
  input [63 :0]                                  rchannel48_addr_base,
  input [63 :0]                                  rchannel49_addr_base,
  input [63 :0]                                  rchannel50_addr_base,
  input [63 :0]                                  rchannel51_addr_base,
  input [63 :0]                                  rchannel52_addr_base,
  input [63 :0]                                  rchannel53_addr_base,
  input [63 :0]                                  rchannel54_addr_base,
  input [63 :0]                                  rchannel55_addr_base,
  input [63 :0]                                  rchannel56_addr_base,
  input [63 :0]                                  rchannel57_addr_base,
  input [63 :0]                                  rchannel58_addr_base,
  input [63 :0]                                  rchannel59_addr_base,
  input [63 :0]                                  rchannel60_addr_base,
  input [63 :0]                                  rchannel61_addr_base,
  input [63 :0]                                  rchannel62_addr_base,
  input [63 :0]                                  rchannel63_addr_base,
  input [63 :0]                                  rchannel64_addr_base,
  input [63 :0]                                  rchannel65_addr_base,
  input [63 :0]                                  rchannel66_addr_base,
  input [63 :0]                                  rchannel67_addr_base,
  input [63 :0]                                  rchannel68_addr_base,
  input [63 :0]                                  rchannel69_addr_base,
  input [63 :0]                                  rchannel70_addr_base,
  input [63 :0]                                  rchannel71_addr_base,
  input [63 :0]                                  rchannel72_addr_base,
  input [63 :0]                                  rchannel73_addr_base,
  input [63 :0]                                  rchannel74_addr_base,
  input [63 :0]                                  rchannel75_addr_base,
  input [63 :0]                                  rchannel76_addr_base,
  input [63 :0]                                  rchannel77_addr_base,
  input [63 :0]                                  rchannel78_addr_base,
  input [63 :0]                                  rchannel79_addr_base,
  input [63 :0]                                  rchannel80_addr_base,
  input [63 :0]                                  rchannel81_addr_base,
  input [63 :0]                                  rchannel82_addr_base,
  input [63 :0]                                  rchannel83_addr_base,
  input [63 :0]                                  rchannel84_addr_base,
  input [63 :0]                                  rchannel85_addr_base,
  input [63 :0]                                  rchannel86_addr_base,
  input [63 :0]                                  rchannel87_addr_base,
  input [63 :0]                                  rchannel88_addr_base,
  input [63 :0]                                  rchannel89_addr_base,
  input [63 :0]                                  rchannel90_addr_base,
  input [63 :0]                                  rchannel91_addr_base,
  input [63 :0]                                  rchannel92_addr_base,
  input [63 :0]                                  rchannel93_addr_base,
  input [63 :0]                                  rchannel94_addr_base,
  input [63 :0]                                  rchannel95_addr_base,
  input [63 :0]                                  rchannel96_addr_base,
  input [63 :0]                                  rchannel97_addr_base,
  input [63 :0]                                  rchannel98_addr_base,
  input [63 :0]                                  rchannel99_addr_base,
  input [63 :0]                                  rchannel100_addr_base,
  input [63 :0]                                  rchannel101_addr_base,
  input [63 :0]                                  rchannel102_addr_base,
  input [63 :0]                                  rchannel103_addr_base,
  input [63 :0]                                  rchannel104_addr_base,
  input [63 :0]                                  rchannel105_addr_base,
  input [63 :0]                                  rchannel106_addr_base,
  input [63 :0]                                  rchannel107_addr_base,
  input [63 :0]                                  rchannel108_addr_base,
  input [63 :0]                                  rchannel109_addr_base,
  input [63 :0]                                  rchannel110_addr_base,
  input [63 :0]                                  rchannel111_addr_base,
  input [63 :0]                                  rchannel112_addr_base,
  input [63 :0]                                  rchannel113_addr_base,
  input [63 :0]                                  rchannel114_addr_base,
  input [63 :0]                                  rchannel115_addr_base,
  input [63 :0]                                  rchannel116_addr_base,
  input [63 :0]                                  rchannel117_addr_base,
  input [63 :0]                                  rchannel118_addr_base,
  input [63 :0]                                  rchannel119_addr_base,
  input [63 :0]                                  rchannel120_addr_base,
  input [63 :0]                                  rchannel121_addr_base,
  input [63 :0]                                  rchannel122_addr_base,
  input [63 :0]                                  rchannel123_addr_base,
  input [63 :0]                                  rchannel124_addr_base,
  input [63 :0]                                  rchannel125_addr_base,
  input [63 :0]                                  rchannel126_addr_base,
  input [63 :0]                                  rchannel127_addr_base,
  input [63 :0]                                  rchannel128_addr_base,
  input [63 :0]                                  rchannel129_addr_base,
  input [63 :0]                                  rchannel130_addr_base,
  input [63 :0]                                  rchannel131_addr_base,
  input [63 :0]                                  rchannel132_addr_base,
  input [63 :0]                                  rchannel133_addr_base,
  input [63 :0]                                  rchannel134_addr_base,
  input [63 :0]                                  rchannel135_addr_base,
  input [63 :0]                                  rchannel136_addr_base,
  input [63 :0]                                  rchannel137_addr_base,
  input [63 :0]                                  rchannel138_addr_base,
  input [63 :0]                                  rchannel139_addr_base,
  input [63 :0]                                  rchannel140_addr_base,
  input [63 :0]                                  rchannel141_addr_base,
  input [63 :0]                                  rchannel142_addr_base,
  input [63 :0]                                  rchannel143_addr_base,
  input [63 :0]                                  rchannel144_addr_base,
  input [63 :0]                                  rchannel145_addr_base,
  input [63 :0]                                  rchannel146_addr_base,
  input [63 :0]                                  rchannel147_addr_base,
  input [63 :0]                                  rchannel148_addr_base,
  input [63 :0]                                  rchannel149_addr_base,
  input [63 :0]                                  rchannel150_addr_base,
  input [63 :0]                                  rchannel151_addr_base,
  input [63 :0]                                  rchannel152_addr_base,
  input [63 :0]                                  rchannel153_addr_base,
  input [63 :0]                                  rchannel154_addr_base,
  input [63 :0]                                  rchannel155_addr_base,
  input [63 :0]                                  rchannel156_addr_base,
  input [63 :0]                                  rchannel157_addr_base,
  input [63 :0]                                  rchannel158_addr_base,
  input [63 :0]                                  rchannel159_addr_base,
  input [63 :0]                                  rchannel160_addr_base,
  input [63 :0]                                  rchannel161_addr_base,
  input [63 :0]                                  rchannel162_addr_base,
  input [63 :0]                                  rchannel163_addr_base,
  input [63 :0]                                  rchannel164_addr_base,
  input [63 :0]                                  rchannel165_addr_base,
  input [63 :0]                                  rchannel166_addr_base,
  input [63 :0]                                  rchannel167_addr_base,
  input [63 :0]                                  rchannel168_addr_base,
  input [63 :0]                                  rchannel169_addr_base,
  input [63 :0]                                  rchannel170_addr_base,
  input [63 :0]                                  rchannel171_addr_base,
  input [63 :0]                                  rchannel172_addr_base,
  input [63 :0]                                  rchannel173_addr_base,
  input [63 :0]                                  rchannel174_addr_base,
  input [63 :0]                                  rchannel175_addr_base,
  input [63 :0]                                  rchannel176_addr_base,
  input [63 :0]                                  rchannel177_addr_base,
  input [63 :0]                                  rchannel178_addr_base,
  input [63 :0]                                  rchannel179_addr_base,
  input [63 :0]                                  rchannel180_addr_base,
  input [63 :0]                                  rchannel181_addr_base,
  input [63 :0]                                  rchannel182_addr_base,
  input [63 :0]                                  rchannel183_addr_base,
  input [63 :0]                                  rchannel184_addr_base,
  input [63 :0]                                  rchannel185_addr_base,
  input [63 :0]                                  rchannel186_addr_base,
  input [63 :0]                                  rchannel187_addr_base,
  input [63 :0]                                  rchannel188_addr_base,
  input [63 :0]                                  rchannel189_addr_base,
  input [63 :0]                                  rchannel190_addr_base,
  input [63 :0]                                  rchannel191_addr_base,
  input [63 :0]                                  rchannel192_addr_base,
  input [63 :0]                                  rchannel193_addr_base,
  input [63 :0]                                  rchannel194_addr_base,
  input [63 :0]                                  rchannel195_addr_base,
  input [63 :0]                                  rchannel196_addr_base,
  input [63 :0]                                  rchannel197_addr_base,
  input [63 :0]                                  rchannel198_addr_base,
  input [63 :0]                                  rchannel199_addr_base,
  input [63 :0]                                  rchannel200_addr_base,
  input [63 :0]                                  rchannel201_addr_base,
  input [63 :0]                                  rchannel202_addr_base,
  input [63 :0]                                  rchannel203_addr_base,
  input [63 :0]                                  rchannel204_addr_base,
  input [63 :0]                                  rchannel205_addr_base,
  input [63 :0]                                  rchannel206_addr_base,
  input [63 :0]                                  rchannel207_addr_base,
  input [63 :0]                                  rchannel208_addr_base,
  input [63 :0]                                  rchannel209_addr_base,
  input [63 :0]                                  rchannel210_addr_base,
  input [63 :0]                                  rchannel211_addr_base,
  input [63 :0]                                  rchannel212_addr_base,
  input [63 :0]                                  rchannel213_addr_base,
  input [63 :0]                                  rchannel214_addr_base,
  input [63 :0]                                  rchannel215_addr_base,
  input [63 :0]                                  rchannel216_addr_base,
  input [63 :0]                                  rchannel217_addr_base,
  input [63 :0]                                  rchannel218_addr_base,
  input [63 :0]                                  rchannel219_addr_base,
  input [63 :0]                                  rchannel220_addr_base,
  input [63 :0]                                  rchannel221_addr_base,
  input [63 :0]                                  rchannel222_addr_base,
  input [63 :0]                                  rchannel223_addr_base,
  input [63 :0]                                  rchannel224_addr_base,
  input [63 :0]                                  rchannel225_addr_base,
  input [63 :0]                                  rchannel226_addr_base,
  input [63 :0]                                  rchannel227_addr_base,
  input [63 :0]                                  rchannel228_addr_base,
  input [63 :0]                                  rchannel229_addr_base,
  input [63 :0]                                  rchannel230_addr_base,
  input [63 :0]                                  rchannel231_addr_base,
  input [63 :0]                                  rchannel232_addr_base,
  input [63 :0]                                  rchannel233_addr_base,
  input [63 :0]                                  rchannel234_addr_base,
  input [63 :0]                                  rchannel235_addr_base,
  input [63 :0]                                  rchannel236_addr_base,
  input [63 :0]                                  rchannel237_addr_base,
  input [63 :0]                                  rchannel238_addr_base,
  input [63 :0]                                  rchannel239_addr_base,
  input [63 :0]                                  rchannel240_addr_base,
  input [63 :0]                                  rchannel241_addr_base,
  input [63 :0]                                  rchannel242_addr_base,
  input [63 :0]                                  rchannel243_addr_base,
  input [63 :0]                                  rchannel244_addr_base,
  input [63 :0]                                  rchannel245_addr_base,
  input [63 :0]                                  rchannel246_addr_base,
  input [63 :0]                                  rchannel247_addr_base,
  input [63 :0]                                  rchannel248_addr_base,
  input [63 :0]                                  rchannel249_addr_base,
  input [63 :0]                                  rchannel250_addr_base,
  input [63 :0]                                  rchannel251_addr_base,
  input [63 :0]                                  rchannel252_addr_base,
  input [63 :0]                                  rchannel253_addr_base,
  input [63 :0]                                  rchannel254_addr_base,
  input [63 :0]                                  rchannel255_addr_base,
  input [63 :0]                                  wchannel_addr_base,


  output [ADDR_WIDTH-1:0]         m_rchannel0_address      ,
  output                          m_rchannel0_read         ,
  input                           m_rchannel0_waitrequest  ,
  input  [DDR_DATA_WIDTH-1:0]     m_rchannel0_readdata     ,
  output                          m_rchannel0_write        ,
  output [DDR_DATA_WIDTH-1:0]     m_rchannel0_writedata    ,
  input                           m_rchannel0_readdatavalid,
  output [DDR_DATA_WIDTH/8 -1:0]  m_rchannel0_byteenable   ,
  output [4:0]                    m_rchannel0_burstcount   ,
  output                          m_rchannel0_enable,
  input                           m_rchannel0_writeack,

  output [ADDR_WIDTH-1:0]         m_rchannel1_address      ,
  output                          m_rchannel1_read         ,
  input                           m_rchannel1_waitrequest  ,
  input  [DDR_DATA_WIDTH-1:0]     m_rchannel1_readdata     ,
  output                          m_rchannel1_write        ,
  output [DDR_DATA_WIDTH-1:0]     m_rchannel1_writedata    ,
  input                           m_rchannel1_readdatavalid,
  output [DDR_DATA_WIDTH/8 -1:0]  m_rchannel1_byteenable   ,
  output [4:0]                    m_rchannel1_burstcount   ,
  output                          m_rchannel1_enable,
  input                           m_rchannel1_writeack,

  output [ADDR_WIDTH-1:0]         m_rchannel2_address      ,
  output                          m_rchannel2_read         ,
  input                           m_rchannel2_waitrequest  ,
  input  [DDR_DATA_WIDTH-1:0]     m_rchannel2_readdata     ,
  output                          m_rchannel2_write        ,
  output [DDR_DATA_WIDTH-1:0]     m_rchannel2_writedata    ,
  input                           m_rchannel2_readdatavalid,
  output [DDR_DATA_WIDTH/8 -1:0]  m_rchannel2_byteenable   ,
  output [4:0]                    m_rchannel2_burstcount   ,
  output                          m_rchannel2_enable,
  input                           m_rchannel2_writeack,

  output [ADDR_WIDTH-1:0]         m_rchannel3_address      ,
  output                          m_rchannel3_read         ,
  input                           m_rchannel3_waitrequest  ,
  input  [DDR_DATA_WIDTH-1:0]     m_rchannel3_readdata     ,
  output                          m_rchannel3_write        ,
  output [DDR_DATA_WIDTH-1:0]     m_rchannel3_writedata    ,
  input                           m_rchannel3_readdatavalid,
  output [DDR_DATA_WIDTH/8 -1:0]  m_rchannel3_byteenable   ,
  output [4:0]                    m_rchannel3_burstcount   ,
  output                          m_rchannel3_enable,
  input                           m_rchannel3_writeack,

  output [ADDR_WIDTH-1:0]         m_wchannel0_address      ,
  output                          m_wchannel0_read         ,
  input                           m_wchannel0_waitrequest  ,
  input  [DDR_DATA_WIDTH-1:0]     m_wchannel0_readdata     ,
  output                          m_wchannel0_write        ,
  output [DDR_DATA_WIDTH-1:0]     m_wchannel0_writedata    ,
  input                           m_wchannel0_readdatavalid,
  output [DDR_DATA_WIDTH/8 -1:0]  m_wchannel0_byteenable   ,
  output [4:0]                    m_wchannel0_burstcount   ,
  output                          m_wchannel0_enable,
  input                           m_wchannel0_writeack
);
localparam LDQ_ID_WIDTH=$clog2(TOTAL_LDQ_IDS);
wire [NUM_LDQ-1:0]              ldq_valid;
wire [NUM_LDQ*LDQ_ID_WIDTH-1+8:0]          ldq_id;

wire [NUM_LDQ-1:0]              ldq_data_valid;
wire [NUM_LDQ*LDQ_DATA_WIDTH-1:0]   ldq_data;
wire [NUM_LDQ-1:0]              ldq_data_ready;

wire [NUM_STQ-1:0]              stq_valid;
wire [NUM_STQ*STQ_DATA_WIDTH-1:0]   stq_data;
wire [NUM_STQ-1:0]              stq_ready;

wire [NUM_LDQ-1:0]                  ldq_ddr_addr_valid;
wire [NUM_LDQ-1:0]                  ldq_ddr_addr_ready;
wire [NUM_LDQ-1:0]                  ldq_ready;
wire [NUM_LDQ*ADDR_WIDTH-1:0]       ldq_ddr_addr;
wire [NUM_LDQ-1:0]                  ldq_ddr_data_valid;
wire [NUM_LDQ*DDR_DATA_WIDTH-1:0]   ldq_ddr_data;

wire [NUM_STQ-1:0]                  stq_ddr_valid;
wire [NUM_STQ-1:0]                  stq_ddr_ready;
wire [NUM_STQ*ADDR_WIDTH-1:0]       stq_ddr_addr;
wire [NUM_STQ*DDR_DATA_WIDTH-1:0]   stq_ddr_data;
reg [1:0] cnt;

always @ (posedge clock)
if(!resetn)
  cnt <= 'h0;
else 
  cnt <= cnt + 1;
wire clk_slow;

assign clk_slow = cnt[0];

assign m_rchannel0_address = ldq_ddr_addr[ADDR_WIDTH  -1:0];
assign m_rchannel1_address = ldq_ddr_addr[ADDR_WIDTH*2-1:ADDR_WIDTH];
assign m_rchannel2_address = ldq_ddr_addr[ADDR_WIDTH*3-1:ADDR_WIDTH*2];
assign m_rchannel3_address = ldq_ddr_addr[ADDR_WIDTH*4-1:ADDR_WIDTH*3];

assign m_rchannel0_read    = ldq_ddr_addr_valid[0];
assign m_rchannel1_read    = ldq_ddr_addr_valid[1];
assign m_rchannel2_read    = ldq_ddr_addr_valid[2];
assign m_rchannel3_read    = ldq_ddr_addr_valid[3];

assign ldq_ddr_addr_ready[0] = m_rchannel0_waitrequest ;
assign ldq_ddr_addr_ready[1] = m_rchannel1_waitrequest ;
assign ldq_ddr_addr_ready[2] = m_rchannel2_waitrequest ;
assign ldq_ddr_addr_ready[3] = m_rchannel3_waitrequest ;

assign ldq_ddr_data[DDR_DATA_WIDTH  -1: 0             ]   = m_rchannel0_readdata;
assign ldq_ddr_data[DDR_DATA_WIDTH*2-1: DDR_DATA_WIDTH]   = m_rchannel1_readdata;
assign ldq_ddr_data[DDR_DATA_WIDTH*3-1: DDR_DATA_WIDTH*2] = m_rchannel2_readdata;
assign ldq_ddr_data[DDR_DATA_WIDTH*4-1: DDR_DATA_WIDTH*3] = m_rchannel3_readdata;

assign ldq_ddr_data_valid[0] = m_rchannel0_readdatavalid;
assign ldq_ddr_data_valid[1] = m_rchannel1_readdatavalid;
assign ldq_ddr_data_valid[2] = m_rchannel2_readdatavalid;
assign ldq_ddr_data_valid[3] = m_rchannel3_readdatavalid;

assign m_rchannel0_read      = ldq_ddr_addr_valid[0];
assign m_rchannel1_read      = ldq_ddr_addr_valid[1];
assign m_rchannel2_read      = ldq_ddr_addr_valid[2];
assign m_rchannel3_read      = ldq_ddr_addr_valid[3];

assign m_rchannel0_enable    = 1'b1;
assign m_rchannel1_enable    = 1'b1;
assign m_rchannel2_enable    = 1'b1;
assign m_rchannel3_enable    = 1'b1;

assign m_rchannel0_write    = 1'b0;
assign m_rchannel1_write    = 1'b0;
assign m_rchannel2_write    = 1'b0;
assign m_rchannel3_write    = 1'b0;

assign m_rchannel0_writedata = 'h0;
assign m_rchannel1_writedata = 'h0;
assign m_rchannel2_writedata = 'h0;
assign m_rchannel3_writedata = 'h0;

assign m_rchannel0_burstcount = 'h1;
assign m_rchannel1_burstcount = 'h1;
assign m_rchannel2_burstcount = 'h1;
assign m_rchannel3_burstcount = 'h1;

assign m_rchannel0_byteenable = 'h0;
assign m_rchannel1_byteenable = 'h0;
assign m_rchannel2_byteenable = 'h0;
assign m_rchannel3_byteenable = 'h0;

assign m_wchannel0_address = stq_ddr_addr[ADDR_WIDTH  -1:0];

assign m_wchannel0_read    = 1'b0;
assign m_wchannel0_enable    = 1'b1;

assign stq_ddr_ready = m_wchannel0_waitrequest ;

assign m_wchannel0_write    = stq_ddr_valid;

assign m_wchannel0_writedata = stq_ddr_data;

assign m_wchannel0_burstcount = 'h1;

assign m_wchannel0_byteenable = {(DDR_DATA_WIDTH/8){1'b1}};

wire [20*256-1:0] rchannel_addr_base_all;

assign rchannel_addr_base_all = {
  rchannel_addr_base + rchannel0_addr_base[19:0],
  rchannel_addr_base + rchannel1_addr_base[19:0],
  rchannel_addr_base + rchannel2_addr_base[19:0],
  rchannel_addr_base + rchannel3_addr_base[19:0],
  rchannel_addr_base + rchannel4_addr_base[19:0],
  rchannel_addr_base + rchannel5_addr_base[19:0],
  rchannel_addr_base + rchannel6_addr_base[19:0],
  rchannel_addr_base + rchannel7_addr_base[19:0],
  rchannel_addr_base + rchannel8_addr_base[19:0],
  rchannel_addr_base + rchannel9_addr_base[19:0],
  rchannel_addr_base + rchannel10_addr_base[19:0],
  rchannel_addr_base + rchannel11_addr_base[19:0],
  rchannel_addr_base + rchannel12_addr_base[19:0],
  rchannel_addr_base + rchannel13_addr_base[19:0],
  rchannel_addr_base + rchannel14_addr_base[19:0],
  rchannel_addr_base + rchannel15_addr_base[19:0],
  rchannel_addr_base + rchannel16_addr_base[19:0],
  rchannel_addr_base + rchannel17_addr_base[19:0],
  rchannel_addr_base + rchannel18_addr_base[19:0],
  rchannel_addr_base + rchannel19_addr_base[19:0],
  rchannel_addr_base + rchannel20_addr_base[19:0],
  rchannel_addr_base + rchannel21_addr_base[19:0],
  rchannel_addr_base + rchannel22_addr_base[19:0],
  rchannel_addr_base + rchannel23_addr_base[19:0],
  rchannel_addr_base + rchannel24_addr_base[19:0],
  rchannel_addr_base + rchannel25_addr_base[19:0],
  rchannel_addr_base + rchannel26_addr_base[19:0],
  rchannel_addr_base + rchannel27_addr_base[19:0],
  rchannel_addr_base + rchannel28_addr_base[19:0],
  rchannel_addr_base + rchannel29_addr_base[19:0],
  rchannel_addr_base + rchannel30_addr_base[19:0],
  rchannel_addr_base + rchannel31_addr_base[19:0],
  rchannel_addr_base + rchannel32_addr_base[19:0],
  rchannel_addr_base + rchannel33_addr_base[19:0],
  rchannel_addr_base + rchannel34_addr_base[19:0],
  rchannel_addr_base + rchannel35_addr_base[19:0],
  rchannel_addr_base + rchannel36_addr_base[19:0],
  rchannel_addr_base + rchannel37_addr_base[19:0],
  rchannel_addr_base + rchannel38_addr_base[19:0],
  rchannel_addr_base + rchannel39_addr_base[19:0],
  rchannel_addr_base + rchannel40_addr_base[19:0],
  rchannel_addr_base + rchannel41_addr_base[19:0],
  rchannel_addr_base + rchannel42_addr_base[19:0],
  rchannel_addr_base + rchannel43_addr_base[19:0],
  rchannel_addr_base + rchannel44_addr_base[19:0],
  rchannel_addr_base + rchannel45_addr_base[19:0],
  rchannel_addr_base + rchannel46_addr_base[19:0],
  rchannel_addr_base + rchannel47_addr_base[19:0],
  rchannel_addr_base + rchannel48_addr_base[19:0],
  rchannel_addr_base + rchannel49_addr_base[19:0],
  rchannel_addr_base + rchannel50_addr_base[19:0],
  rchannel_addr_base + rchannel51_addr_base[19:0],
  rchannel_addr_base + rchannel52_addr_base[19:0],
  rchannel_addr_base + rchannel53_addr_base[19:0],
  rchannel_addr_base + rchannel54_addr_base[19:0],
  rchannel_addr_base + rchannel55_addr_base[19:0],
  rchannel_addr_base + rchannel56_addr_base[19:0],
  rchannel_addr_base + rchannel57_addr_base[19:0],
  rchannel_addr_base + rchannel58_addr_base[19:0],
  rchannel_addr_base + rchannel59_addr_base[19:0],
  rchannel_addr_base + rchannel60_addr_base[19:0],
  rchannel_addr_base + rchannel61_addr_base[19:0],
  rchannel_addr_base + rchannel62_addr_base[19:0],
  rchannel_addr_base + rchannel63_addr_base[19:0],
  rchannel_addr_base + rchannel64_addr_base[19:0],
  rchannel_addr_base + rchannel65_addr_base[19:0],
  rchannel_addr_base + rchannel66_addr_base[19:0],
  rchannel_addr_base + rchannel67_addr_base[19:0],
  rchannel_addr_base + rchannel68_addr_base[19:0],
  rchannel_addr_base + rchannel69_addr_base[19:0],
  rchannel_addr_base + rchannel70_addr_base[19:0],
  rchannel_addr_base + rchannel71_addr_base[19:0],
  rchannel_addr_base + rchannel72_addr_base[19:0],
  rchannel_addr_base + rchannel73_addr_base[19:0],
  rchannel_addr_base + rchannel74_addr_base[19:0],
  rchannel_addr_base + rchannel75_addr_base[19:0],
  rchannel_addr_base + rchannel76_addr_base[19:0],
  rchannel_addr_base + rchannel77_addr_base[19:0],
  rchannel_addr_base + rchannel78_addr_base[19:0],
  rchannel_addr_base + rchannel79_addr_base[19:0],
  rchannel_addr_base + rchannel80_addr_base[19:0],
  rchannel_addr_base + rchannel81_addr_base[19:0],
  rchannel_addr_base + rchannel82_addr_base[19:0],
  rchannel_addr_base + rchannel83_addr_base[19:0],
  rchannel_addr_base + rchannel84_addr_base[19:0],
  rchannel_addr_base + rchannel85_addr_base[19:0],
  rchannel_addr_base + rchannel86_addr_base[19:0],
  rchannel_addr_base + rchannel87_addr_base[19:0],
  rchannel_addr_base + rchannel88_addr_base[19:0],
  rchannel_addr_base + rchannel89_addr_base[19:0],
  rchannel_addr_base + rchannel90_addr_base[19:0],
  rchannel_addr_base + rchannel91_addr_base[19:0],
  rchannel_addr_base + rchannel92_addr_base[19:0],
  rchannel_addr_base + rchannel93_addr_base[19:0],
  rchannel_addr_base + rchannel94_addr_base[19:0],
  rchannel_addr_base + rchannel95_addr_base[19:0],
  rchannel_addr_base + rchannel96_addr_base[19:0],
  rchannel_addr_base + rchannel97_addr_base[19:0],
  rchannel_addr_base + rchannel98_addr_base[19:0],
  rchannel_addr_base + rchannel99_addr_base[19:0],
  rchannel_addr_base + rchannel100_addr_base[19:0],
  rchannel_addr_base + rchannel101_addr_base[19:0],
  rchannel_addr_base + rchannel102_addr_base[19:0],
  rchannel_addr_base + rchannel103_addr_base[19:0],
  rchannel_addr_base + rchannel104_addr_base[19:0],
  rchannel_addr_base + rchannel105_addr_base[19:0],
  rchannel_addr_base + rchannel106_addr_base[19:0],
  rchannel_addr_base + rchannel107_addr_base[19:0],
  rchannel_addr_base + rchannel108_addr_base[19:0],
  rchannel_addr_base + rchannel109_addr_base[19:0],
  rchannel_addr_base + rchannel110_addr_base[19:0],
  rchannel_addr_base + rchannel111_addr_base[19:0],
  rchannel_addr_base + rchannel112_addr_base[19:0],
  rchannel_addr_base + rchannel113_addr_base[19:0],
  rchannel_addr_base + rchannel114_addr_base[19:0],
  rchannel_addr_base + rchannel115_addr_base[19:0],
  rchannel_addr_base + rchannel116_addr_base[19:0],
  rchannel_addr_base + rchannel117_addr_base[19:0],
  rchannel_addr_base + rchannel118_addr_base[19:0],
  rchannel_addr_base + rchannel119_addr_base[19:0],
  rchannel_addr_base + rchannel120_addr_base[19:0],
  rchannel_addr_base + rchannel121_addr_base[19:0],
  rchannel_addr_base + rchannel122_addr_base[19:0],
  rchannel_addr_base + rchannel123_addr_base[19:0],
  rchannel_addr_base + rchannel124_addr_base[19:0],
  rchannel_addr_base + rchannel125_addr_base[19:0],
  rchannel_addr_base + rchannel126_addr_base[19:0],
  rchannel_addr_base + rchannel127_addr_base[19:0],
  rchannel_addr_base + rchannel128_addr_base[19:0],
  rchannel_addr_base + rchannel129_addr_base[19:0],
  rchannel_addr_base + rchannel130_addr_base[19:0],
  rchannel_addr_base + rchannel131_addr_base[19:0],
  rchannel_addr_base + rchannel132_addr_base[19:0],
  rchannel_addr_base + rchannel133_addr_base[19:0],
  rchannel_addr_base + rchannel134_addr_base[19:0],
  rchannel_addr_base + rchannel135_addr_base[19:0],
  rchannel_addr_base + rchannel136_addr_base[19:0],
  rchannel_addr_base + rchannel137_addr_base[19:0],
  rchannel_addr_base + rchannel138_addr_base[19:0],
  rchannel_addr_base + rchannel139_addr_base[19:0],
  rchannel_addr_base + rchannel140_addr_base[19:0],
  rchannel_addr_base + rchannel141_addr_base[19:0],
  rchannel_addr_base + rchannel142_addr_base[19:0],
  rchannel_addr_base + rchannel143_addr_base[19:0],
  rchannel_addr_base + rchannel144_addr_base[19:0],
  rchannel_addr_base + rchannel145_addr_base[19:0],
  rchannel_addr_base + rchannel146_addr_base[19:0],
  rchannel_addr_base + rchannel147_addr_base[19:0],
  rchannel_addr_base + rchannel148_addr_base[19:0],
  rchannel_addr_base + rchannel149_addr_base[19:0],
  rchannel_addr_base + rchannel150_addr_base[19:0],
  rchannel_addr_base + rchannel151_addr_base[19:0],
  rchannel_addr_base + rchannel152_addr_base[19:0],
  rchannel_addr_base + rchannel153_addr_base[19:0],
  rchannel_addr_base + rchannel154_addr_base[19:0],
  rchannel_addr_base + rchannel155_addr_base[19:0],
  rchannel_addr_base + rchannel156_addr_base[19:0],
  rchannel_addr_base + rchannel157_addr_base[19:0],
  rchannel_addr_base + rchannel158_addr_base[19:0],
  rchannel_addr_base + rchannel159_addr_base[19:0],
  rchannel_addr_base + rchannel160_addr_base[19:0],
  rchannel_addr_base + rchannel161_addr_base[19:0],
  rchannel_addr_base + rchannel162_addr_base[19:0],
  rchannel_addr_base + rchannel163_addr_base[19:0],
  rchannel_addr_base + rchannel164_addr_base[19:0],
  rchannel_addr_base + rchannel165_addr_base[19:0],
  rchannel_addr_base + rchannel166_addr_base[19:0],
  rchannel_addr_base + rchannel167_addr_base[19:0],
  rchannel_addr_base + rchannel168_addr_base[19:0],
  rchannel_addr_base + rchannel169_addr_base[19:0],
  rchannel_addr_base + rchannel170_addr_base[19:0],
  rchannel_addr_base + rchannel171_addr_base[19:0],
  rchannel_addr_base + rchannel172_addr_base[19:0],
  rchannel_addr_base + rchannel173_addr_base[19:0],
  rchannel_addr_base + rchannel174_addr_base[19:0],
  rchannel_addr_base + rchannel175_addr_base[19:0],
  rchannel_addr_base + rchannel176_addr_base[19:0],
  rchannel_addr_base + rchannel177_addr_base[19:0],
  rchannel_addr_base + rchannel178_addr_base[19:0],
  rchannel_addr_base + rchannel179_addr_base[19:0],
  rchannel_addr_base + rchannel180_addr_base[19:0],
  rchannel_addr_base + rchannel181_addr_base[19:0],
  rchannel_addr_base + rchannel182_addr_base[19:0],
  rchannel_addr_base + rchannel183_addr_base[19:0],
  rchannel_addr_base + rchannel184_addr_base[19:0],
  rchannel_addr_base + rchannel185_addr_base[19:0],
  rchannel_addr_base + rchannel186_addr_base[19:0],
  rchannel_addr_base + rchannel187_addr_base[19:0],
  rchannel_addr_base + rchannel188_addr_base[19:0],
  rchannel_addr_base + rchannel189_addr_base[19:0],
  rchannel_addr_base + rchannel190_addr_base[19:0],
  rchannel_addr_base + rchannel191_addr_base[19:0],
  rchannel_addr_base + rchannel192_addr_base[19:0],
  rchannel_addr_base + rchannel193_addr_base[19:0],
  rchannel_addr_base + rchannel194_addr_base[19:0],
  rchannel_addr_base + rchannel195_addr_base[19:0],
  rchannel_addr_base + rchannel196_addr_base[19:0],
  rchannel_addr_base + rchannel197_addr_base[19:0],
  rchannel_addr_base + rchannel198_addr_base[19:0],
  rchannel_addr_base + rchannel199_addr_base[19:0],
  rchannel_addr_base + rchannel200_addr_base[19:0],
  rchannel_addr_base + rchannel201_addr_base[19:0],
  rchannel_addr_base + rchannel202_addr_base[19:0],
  rchannel_addr_base + rchannel203_addr_base[19:0],
  rchannel_addr_base + rchannel204_addr_base[19:0],
  rchannel_addr_base + rchannel205_addr_base[19:0],
  rchannel_addr_base + rchannel206_addr_base[19:0],
  rchannel_addr_base + rchannel207_addr_base[19:0],
  rchannel_addr_base + rchannel208_addr_base[19:0],
  rchannel_addr_base + rchannel209_addr_base[19:0],
  rchannel_addr_base + rchannel210_addr_base[19:0],
  rchannel_addr_base + rchannel211_addr_base[19:0],
  rchannel_addr_base + rchannel212_addr_base[19:0],
  rchannel_addr_base + rchannel213_addr_base[19:0],
  rchannel_addr_base + rchannel214_addr_base[19:0],
  rchannel_addr_base + rchannel215_addr_base[19:0],
  rchannel_addr_base + rchannel216_addr_base[19:0],
  rchannel_addr_base + rchannel217_addr_base[19:0],
  rchannel_addr_base + rchannel218_addr_base[19:0],
  rchannel_addr_base + rchannel219_addr_base[19:0],
  rchannel_addr_base + rchannel220_addr_base[19:0],
  rchannel_addr_base + rchannel221_addr_base[19:0],
  rchannel_addr_base + rchannel222_addr_base[19:0],
  rchannel_addr_base + rchannel223_addr_base[19:0],
  rchannel_addr_base + rchannel224_addr_base[19:0],
  rchannel_addr_base + rchannel225_addr_base[19:0],
  rchannel_addr_base + rchannel226_addr_base[19:0],
  rchannel_addr_base + rchannel227_addr_base[19:0],
  rchannel_addr_base + rchannel228_addr_base[19:0],
  rchannel_addr_base + rchannel229_addr_base[19:0],
  rchannel_addr_base + rchannel230_addr_base[19:0],
  rchannel_addr_base + rchannel231_addr_base[19:0],
  rchannel_addr_base + rchannel232_addr_base[19:0],
  rchannel_addr_base + rchannel233_addr_base[19:0],
  rchannel_addr_base + rchannel234_addr_base[19:0],
  rchannel_addr_base + rchannel235_addr_base[19:0],
  rchannel_addr_base + rchannel236_addr_base[19:0],
  rchannel_addr_base + rchannel237_addr_base[19:0],
  rchannel_addr_base + rchannel238_addr_base[19:0],
  rchannel_addr_base + rchannel239_addr_base[19:0],
  rchannel_addr_base + rchannel240_addr_base[19:0],
  rchannel_addr_base + rchannel241_addr_base[19:0],
  rchannel_addr_base + rchannel242_addr_base[19:0],
  rchannel_addr_base + rchannel243_addr_base[19:0],
  rchannel_addr_base + rchannel244_addr_base[19:0],
  rchannel_addr_base + rchannel245_addr_base[19:0],
  rchannel_addr_base + rchannel246_addr_base[19:0],
  rchannel_addr_base + rchannel247_addr_base[19:0],
  rchannel_addr_base + rchannel248_addr_base[19:0],
  rchannel_addr_base + rchannel249_addr_base[19:0],
  rchannel_addr_base + rchannel250_addr_base[19:0],
  rchannel_addr_base + rchannel251_addr_base[19:0],
  rchannel_addr_base + rchannel252_addr_base[19:0],
  rchannel_addr_base + rchannel253_addr_base[19:0],
  rchannel_addr_base + rchannel254_addr_base[19:0],
  rchannel_addr_base + rchannel255_addr_base[19:0]
                            };

/////////////////

reg [2:0] cur_spmv_state;
reg [2:0] nxt_spmv_state;

parameter SPMV_IDEL               = 3'b000;
parameter SPMV_MODE0_ENABLE       = 3'b001;
parameter SPMV_MODE_SWITCH_BEGIN  = 3'b010;
parameter SPMV_MODE_SWITCH_END    = 3'b011;
parameter SPMV_MODE1_ENABLE       = 3'b100;
parameter SPMV_DONE               = 3'b101;

wire init;
wire done;
reg spmv_mode_func;
reg spmv_enable_func;
wire spmv_mode_p;
reg spmv_mode_reg;


always @ (posedge clock)
if(!resetn)
  nxt_spmv_state <='h0;
else
  nxt_spmv_state <= cur_spmv_state;

always @ (*) begin
  cur_spmv_state = nxt_spmv_state;
  case(nxt_spmv_state) 
    SPMV_IDEL: if(spmv_mode_p) cur_spmv_state   = SPMV_MODE0_ENABLE;
    SPMV_MODE0_ENABLE : if(init) cur_spmv_state = SPMV_MODE_SWITCH_BEGIN;
    SPMV_MODE_SWITCH_BEGIN: cur_spmv_state = SPMV_MODE_SWITCH_END;
    SPMV_MODE_SWITCH_END: cur_spmv_state = SPMV_MODE1_ENABLE;
    SPMV_MODE1_ENABLE:  if(done) cur_spmv_state = SPMV_DONE;
    SPMV_DONE        :    cur_spmv_state = SPMV_IDEL;
  endcase
end

always @ (posedge clock)
if(!resetn) begin
  spmv_mode_reg <= 1'b0;
end
else begin
  spmv_mode_reg <= spmv_mode[0];
end

assign spmv_mode_p = spmv_mode[0] & ~spmv_mode_reg;

always @ (*) begin
spmv_mode_func = 1'b0;
spmv_enable_func = 1'b0;
case (cur_spmv_state)
    SPMV_IDEL:              begin spmv_mode_func = 1'b0; spmv_enable_func = 1'b0; end
    SPMV_MODE0_ENABLE :     begin spmv_mode_func = 1'b0; spmv_enable_func = 1'b1; end
    SPMV_MODE_SWITCH_BEGIN: begin spmv_mode_func = 1'b0; spmv_enable_func = 1'b0; end
    SPMV_MODE_SWITCH_END:   begin spmv_mode_func = 1'b1; spmv_enable_func = 1'b0; end
    SPMV_MODE1_ENABLE:      begin spmv_mode_func = 1'b1; spmv_enable_func = 1'b1; end
    SPMV_DONE        :      begin spmv_mode_func = 1'b0; spmv_enable_func = 1'b0; end
endcase
end


merge_core dut_spmv
(
  .rst_b          (resetn),
  .clk_slow       (clk_slow),
  .clk_fast       (clock),
  .clk_ldq        (clock),

  .mode           (spmv_mode_func),
  .enable         (spmv_enable_func),
  .init           (init            ),
  .done           (done            ),
  .ldq_addr_valid      (ldq_valid  ),
  .ldq_addr_ready      (ldq_ready  ),
  .ldq_addr            (ldq_id     ),

  .ldq_data       (ldq_data        ),
  .ldq_data_valid (ldq_data_valid  ),
  .ldq_data_ready (ldq_data_ready  ),

  .stq_valid      (stq_valid       ),
  .stq_ready      (stq_ready       ),
  .stq_data       (stq_data        )
//  .stq_id         (stq_id     )
);

async_lsq #(.DDR_DATA_WIDTH(DDR_DATA_WIDTH), .STQ_DATA_WIDTH(STQ_DATA_WIDTH), .LDQ_DATA_WIDTH(LDQ_DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),.QPTR_WIDTH(10), .NUM_LDQ(NUM_LDQ), .NUM_STQ(NUM_STQ))
spmv_async_lsq (
  .ldq_clk            (clock),
  .stq_clk            (clock),
  .rstn               (resetn),
  .ddr_clk            (clock),
  .ddr_rstn           (resetn),

  .ldq_valid          (ldq_valid),
  .ldq_ready          (ldq_ready),
  .ldq_id             (ldq_id),
  .stq_id             ('h0),
  .ldq_data_valid     (ldq_data_valid),
  .ldq_data_ready     (ldq_data_ready),
  .ldq_data           (ldq_data      ),
  
  .stq_valid          (stq_valid     ),
  .stq_ready          (stq_ready     ),
  .stq_data           (stq_data      ),

  .rchannel_addr_base (rchannel_addr_base_all),
  .wchannel_addr_base (wchannel_addr_base[19:0]),

  //ddr part
  .ldq_ddr_addr_valid (ldq_ddr_addr_valid),
  .ldq_ddr_addr_ready (ldq_ddr_addr_ready),
  .ldq_ddr_addr       (ldq_ddr_addr      ),
  .ldq_ddr_data_valid (ldq_ddr_data_valid),
  .ldq_ddr_data       (ldq_ddr_data      ),

  .stq_ddr_valid      (stq_ddr_valid     ),
  .stq_ddr_ready      (stq_ddr_ready     ),
  .stq_ddr_addr       (stq_ddr_addr      ),
  .stq_ddr_data       (stq_ddr_data      )
);


endmodule
module load_queue
#(parameter DDR_DATA_WIDTH = 512, 
            LDQ_DATA_WIDTH = 512, 
            ADDR_WIDTH = 32,
            QPTR_WIDTH = 4,
            IDS_NUM    = 128,
            BASE_ADDR_WIDTH = 20)
(
// spmv interface
input                               sys_clk,
input                               sys_rstn,

input                               req_valid,
input [$clog2(IDS_NUM)-1+2:0]         req_id,
output                              req_ready,
input [BASE_ADDR_WIDTH*IDS_NUM-1:0] addr_base,

output reg                  data_valid,
input                       data_ready,
output [LDQ_DATA_WIDTH-1:0]     data,

//ddr interface
input                       ddr_clk,
input                       ddr_rstn,

output reg                  ddr_addr_valid,
input                       ddr_addr_ready,
output [ADDR_WIDTH-1:0] ddr_addr,
//output reg [ADDR_WIDTH-1:0] ddr_addr,
input                       ddr_data_valid,
input [DDR_DATA_WIDTH-1:0]      ddr_data
);

localparam ID_WIDTH =$clog2(IDS_NUM);
localparam Q_DEPTH  =(1<<QPTR_WIDTH);

reg                     req_channel_empty;
wire                    req_channel_rd;
wire                    req_channel_wr;

wire                    data_channel_empty;
wire                    data_channel_rd;
wire                    data_channel_full;
wire                    data_channel_wr;
reg  [27*IDS_NUM-1:0]  ddr_trans_cnt; 
reg  [ID_WIDTH-1:0]     cur_id;
wire [BASE_ADDR_WIDTH-1:0] cur_addr_base;
wire                       req_channel_full;
wire [8:0]                 sync_fifo_emptyness;
reg  [31:0]                pre_occupy;
wire req_channel_rd_tmp;
wire [6:0]  cur_id_tmp;
wire        req_channel_empty_tmp;
assign cur_addr_base =  addr_base[cur_id * BASE_ADDR_WIDTH  +: BASE_ADDR_WIDTH];

always @ (posedge ddr_clk)
if(!ddr_rstn)
  ddr_trans_cnt <= 'h0;
else if(ddr_addr_valid & ddr_addr_ready)
  ddr_trans_cnt[cur_id*27 +:27] <= ddr_trans_cnt[cur_id*27 +:27]+1;

// count to 0x1f, which is 32 transactions -> 32 * 64B = 2KB
assign req_channel_rd = ~req_channel_empty & 
                        (((ddr_trans_cnt[cur_id * 27 +:5]== 5'h0) & ~ddr_addr_valid) | ((ddr_trans_cnt[cur_id*27+:5] == 5'h1f) & (ddr_addr_valid & ddr_addr_ready)))
                        & (sync_fifo_emptyness > (pre_occupy+32));

assign req_ready      = ~req_channel_full;
assign req_channel_wr =  req_valid & req_ready;

always @ (posedge ddr_clk)
if(~ddr_rstn) begin
  pre_occupy <= 'h0;
end
else begin
  case ({req_channel_rd, ddr_data_valid})
    2'b00: pre_occupy <= pre_occupy;
    2'b01: pre_occupy <= pre_occupy -1;
    2'b10: pre_occupy <= pre_occupy+32;
    2'b11: pre_occupy <= pre_occupy+31;
  endcase
end

always @ (posedge ddr_clk)
if(!ddr_rstn)
  ddr_addr_valid <= 1'b0;
//else if(~req_channel_empty )
else if(req_channel_rd_tmp)
  ddr_addr_valid <= 1'b1;
else if (ddr_addr_valid & ddr_addr_ready & (ddr_trans_cnt[cur_id*27+:5] == 5'h1f))
  ddr_addr_valid <= 1'b0;


dual_clock_fifo #(.DATA_WIDTH(ID_WIDTH),.ADDR_WIDTH(4)) load_req_channel
(
  .wr_rst_i     (~sys_rstn),
  .wr_clk_i     (sys_clk),
  .wr_en_i      (req_channel_wr),
  .wr_data_i    (req_id),            // data is not important here. only internal counters in the fifo matters.

  .rd_rst_i     (~ddr_rstn),
  .rd_clk_i     (ddr_clk),
  .rd_en_i      (req_channel_rd_tmp),
  .rd_data_o    (cur_id_tmp),

  .empty_o      (req_channel_empty_tmp),

  .full_o       (req_channel_full)
);

// fifo fast forward logic
reg req_channel_rd_tmp_d;
always @ (posedge ddr_clk)
if(!ddr_rstn)
  req_channel_rd_tmp_d <= 1'b0;
else
  req_channel_rd_tmp_d <= req_channel_rd_tmp;

assign req_channel_rd_tmp =  req_channel_rd;
//assign req_channel_rd_tmp = (req_channel_empty & ~req_channel_empty_tmp) | req_channel_rd;

//always @ (posedge ddr_clk)
//if(!ddr_rstn)
//  cur_id<= 'h0;
//else if(req_channel_rd_tmp_d)
//  cur_id<= cur_id_tmp;

always@ (posedge ddr_clk)
if(!ddr_rstn)
  cur_id <= 'h0;
else if(req_channel_rd_tmp)
  cur_id <= cur_id_tmp;


//always @ (posedge ddr_clk)
//if(!ddr_rstn)
//  req_channel_empty<= 1'b1;
//else if(req_channel_rd_tmp_d)
//  req_channel_empty<= 1'b0;
//else if(req_channel_rd ) // meanwhile req_channel_rd_tmp_d == 1'b0;
//  req_channel_empty<= 1'b1;

always  @(*)
  req_channel_empty = req_channel_empty_tmp;


// end of fifo fast forward

//always @ (posedge ddr_clk)
//if(!ddr_rstn)
//  ddr_addr <= 'h0;
//else 
//  ddr_addr <= {cur_addr_base, 12'h0} + (ddr_trans_cnt << 5);



assign  ddr_addr  = {cur_addr_base, 12'h0} + (ddr_trans_cnt[cur_id*27 +:27] << 6);



// data channel
reg data_valid_tmp;
//assign data_channel_rd = data_valid_tmp;
assign data_channel_rd = ~data_channel_empty & data_ready;

//always @ (posedge sys_clk)
//if(!sys_rstn)
//    data_valid <= 1'b0;
//else
//    data_valid <= data_channel_rd;

//always @ (posedge sys_clk)
always @ (*)
    data_valid <= data_channel_rd;


//always @ (posedge sys_clk)
//if(!sys_rstn) begin
//  data_valid_tmp <= 1'b0;
//  data_valid <= 1'b0;
//end
//else  begin
//  data_valid_tmp <= ~data_channel_empty;
//  data_valid <= data_valid_tmp;
//end

assign data_channel_wr = ddr_data_valid;
wire data_sync_fifo_empty;
wire [DDR_DATA_WIDTH-1:0]      ddr_data_fifo;

dual_clock_fifo #(.DATA_WIDTH(DDR_DATA_WIDTH),.ADDR_WIDTH(4)) load_data_channel_async // just for clock synchronize spmv always ready
(
  .wr_rst_i     (~ddr_rstn          ),
  .wr_clk_i     (ddr_clk            ),
  .wr_en_i      (~data_sync_fifo_empty & ~data_channel_full),
  .wr_data_i    (ddr_data_fifo      ),

  .rd_rst_i     (~sys_rstn          ),
  .rd_clk_i     (sys_clk            ),
  .rd_en_i      (data_channel_rd    ),
  .rd_data_o    (data               ),

  .empty_o      (data_channel_empty ),
  .full_o       (data_channel_full  )
);


fifo_fwft #(.DATA_WIDTH(DDR_DATA_WIDTH), .DEPTH_WIDTH(8))
load_data_channel_sync
(
    .clk  (ddr_clk),
    .rst  (~ddr_rstn),
    .din  (ddr_data),
    .wr_en(data_channel_wr),
    .full (),
    .dout (ddr_data_fifo),
    .rd_en(~data_sync_fifo_empty & ~data_channel_full),
    .empty(data_sync_fifo_empty),
    .fullness(),
    .emptyness(sync_fifo_emptyness)
);

endmodule
// don't support multi channel (yet).
module store_queue
#(parameter STQ_DATA_WIDTH   = 256,
            DDR_DATA_WIDTH      = 512,
            ADDR_WIDTH      = 32,
            QPTR_WIDTH      = 5,
            IDS_NUM         = 1,
            BASE_ADDR_WIDTH = 20) // default to store 2KB data(512b*2^5)
(
// spmv interface
input                                 sys_clk,
input                                 sys_rstn,
input                                 req_valid,
output                                req_ready,
input [7:0]                           req_id,
input [STQ_DATA_WIDTH-1:0]             data,
input [BASE_ADDR_WIDTH*IDS_NUM -1:0]  addr_base,
input                                 spmv_done,

// ddr interface
input                                 ddr_clk,
input                                 ddr_rstn,
output reg                            ddr_valid,
input                                 ddr_ready,
output reg [ADDR_WIDTH-1:0]           ddr_addr,
output     [DDR_DATA_WIDTH-1:0]       ddr_data
);

localparam Q_DEPTH=(1<<QPTR_WIDTH);
wire                  sync_buf_e;
wire                  sync_buf_f;
wire [DDR_DATA_WIDTH-1:0] sync_buf_dout;
wire                  sync_buf_rd;
wire                  sync_buf_wr;

reg [STQ_DATA_WIDTH-1:0] data_lo;
reg [STQ_DATA_WIDTH-1:0] data_hi;
reg                       odd_even;

wire [DDR_DATA_WIDTH-1:0]     data_all;

always @ (posedge sys_clk)
if(!sys_rstn)
  odd_even<= 'h0;
else if(req_valid &req_ready)
  odd_even<= ~odd_even;


always @ (posedge sys_clk)
if(!sys_rstn)
  data_lo <= 'h0;
else if(req_valid &req_ready& ~odd_even)
  data_lo <= data;

always @ (posedge sys_clk)
if(!sys_rstn)
  data_hi <= 'h0;
else if(req_valid &req_ready& odd_even)
  data_hi <= data;

assign data_all = {data, data_lo};
//assign data_all = {data_hi, data_lo};


wire async_buf_e;
wire async_buf_f;

reg [QPTR_WIDTH:0] sync_buf_fullness;
reg [QPTR_WIDTH-1:0] sync_buf_rd_cnt_lsb;

wire req_channel_rd;
wire req_channel_full;

reg  [26:0]              ddr_trans_cnt; 
// sync fifo logic
reg sync_buf_rd_en;
assign ready = ~sync_buf_f;
//assign sync_buf_wr = req_valid & req_ready;
assign sync_buf_wr = req_valid & req_ready & odd_even;
fifo_fwft #(.DATA_WIDTH(DDR_DATA_WIDTH), .DEPTH_WIDTH(8))
u_sync_fastforward_fifo(
  .clk      (sys_clk),
  .rst      (~sys_rstn),
  .din      (data_all),
  .wr_en    (sync_buf_wr),
  .full     (sync_buf_f),
  .dout     (sync_buf_dout),
  .rd_en    (sync_buf_rd),
  .empty    (sync_buf_e)
);

always @ (posedge sys_clk)
if(~sys_rstn)
  sync_buf_fullness <= 'h0;
else begin
  casez({sync_buf_wr, sync_buf_rd})
  2'b01:   sync_buf_fullness <= sync_buf_fullness - 1;
  2'b10:   sync_buf_fullness <= sync_buf_fullness + 1;
  default: sync_buf_fullness <= sync_buf_fullness;
  endcase
end

always @ (posedge sys_clk)
if(~sys_rstn)
  sync_buf_rd_cnt_lsb<= 'h0;
else if (sync_buf_rd)
  sync_buf_rd_cnt_lsb<= sync_buf_rd_cnt_lsb + 1;

//always @ (posedge sys_clk)
//if(!sys_rstn)
//  sync_buf_rd_en <= 1'b0;
//else if((sync_buf_fullness == 'h20)|spmv_done) // 32 * 64B = 2KB
//  sync_buf_rd_en <= 1'b1;
//else if((sync_buf_rd_cnt_lsb == 'h1f) & sync_buf_rd)
//  sync_buf_rd_en <= 1'b0;

assign sync_buf_rd =  ~sync_buf_e;
//assign sync_buf_rd = sync_buf_rd_en & ~sync_buf_e;
assign req_ready = ~sync_buf_f;


// async buf logic
dual_clock_fifo #(.DATA_WIDTH(DDR_DATA_WIDTH),.ADDR_WIDTH(2)) u_async_fifo  // just for clock convertion
(
  .wr_rst_i     (~sys_rstn),
  .wr_clk_i     (sys_clk),
  .wr_en_i      (sync_buf_rd),
  .wr_data_i    (sync_buf_dout),

  .rd_rst_i     (~ddr_rstn),
  .rd_clk_i     (ddr_clk),
  .rd_en_i      (req_channel_rd),
  .rd_data_o    (ddr_data),

  .empty_o      (req_channel_empty),
  .full_o       (req_channel_full)
);

always @ (posedge ddr_clk)
if(!ddr_rstn)
  ddr_trans_cnt <= 'h0;
else if(ddr_valid & ddr_ready)
  ddr_trans_cnt <= ddr_trans_cnt + 1;

always @ (posedge ddr_clk)
if(~ddr_rstn)
  ddr_valid <= 1'b0;
else if(~req_channel_empty)
  ddr_valid <= 1'b1;
else if(ddr_valid & ddr_ready & req_channel_empty)
  ddr_valid <= 1'b0;

//always @ (posedge ddr_clk)
//if(!ddr_rstn)
//  ddr_addr <= 'h0;
//else 
//  ddr_addr <= {addr_base, 12'h0} + (ddr_trans_cnt << 5);
  
always @ (*)
  ddr_addr = {addr_base, 12'h0} + (ddr_trans_cnt << 5);


//assign req_channel_rd = ~req_channel_empty & ~(ddr_valid & ~ddr_ready);
assign req_channel_rd = ~req_channel_empty & (ddr_valid & ddr_ready);


endmodule
/*
 * Copyright (c) 2012, Stefan Kristiansson <stefan.kristiansson@saunalahti.fi>
 * All rights reserved.
 *
 * Based on vga_fifo_dc.v in Richard Herveille's VGA/LCD core
 * Copyright (C) 2001 Richard Herveille <richard@asics.ws>
 *
 * Redistribution and use in source and non-source forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in non-source form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 * THIS WORK IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * WORK, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

module dual_clock_fifo #(
        parameter ADDR_WIDTH = 3,
        parameter DATA_WIDTH = 32
)
(
  input wire                   wr_rst_i,
  input wire                   wr_clk_i,
  input wire                   wr_en_i,
  input wire [DATA_WIDTH-1:0]  wr_data_i,
  
  input wire                   rd_rst_i,
  input wire                   rd_clk_i,
  input wire                   rd_en_i,
  output reg [DATA_WIDTH-1:0]  rd_data_o,
  
  output reg                   full_o,
  output reg                   empty_o
);

reg [ADDR_WIDTH-1:0]    wr_addr;
reg [ADDR_WIDTH-1:0]    wr_addr_gray;
reg [ADDR_WIDTH-1:0]    wr_addr_gray_rd;
reg [ADDR_WIDTH-1:0]    wr_addr_gray_rd_r;
reg [ADDR_WIDTH-1:0]    rd_addr;
reg [ADDR_WIDTH-1:0]    rd_addr_gray;
reg [ADDR_WIDTH-1:0]    rd_addr_gray_wr;
reg [ADDR_WIDTH-1:0]    rd_addr_gray_wr_r;

function [ADDR_WIDTH-1:0] bin2gray;
input [ADDR_WIDTH-1:0] in;
begin
        bin2gray = {in[ADDR_WIDTH-1],
                     in[ADDR_WIDTH-2:0] ^ in[ADDR_WIDTH-1:1]};
end
endfunction

//function [ADDR_WIDTH-1:0] gray2bin;
//input [ADDR_WIDTH-1:0] in;
//begin
//integer i;
//      for(i=0; i<ADDR_WIDTH; i= i+1) begin
//        gray2bin[i] = ^in[ADDR_WIDTH-1:i];
//      end
//end
//endfunction

always @(posedge wr_clk_i) begin
        if (wr_rst_i) begin
                wr_addr <= 0;
                wr_addr_gray <= 0;
        end else if (wr_en_i) begin
                wr_addr <= wr_addr + 1'b1;
                wr_addr_gray <= bin2gray(wr_addr + 1'b1);
        end
end

// synchronize read address to write clock domain
always @(posedge wr_clk_i) begin
        rd_addr_gray_wr   <= rd_addr_gray;
        rd_addr_gray_wr_r <= rd_addr_gray_wr;
end

always @(posedge wr_clk_i)
        if (wr_rst_i)
                full_o <= 0;
        else if (wr_en_i)
                full_o <= bin2gray(wr_addr + 2) == rd_addr_gray_wr_r;
        else
                full_o <= full_o & (bin2gray(wr_addr + 1'b1) == rd_addr_gray_wr_r);

always @(posedge rd_clk_i) begin
        if (rd_rst_i) begin
                rd_addr <= 0;
                rd_addr_gray <= 0;
        end else if (rd_en_i) begin
                rd_addr <= rd_addr + 1'b1;
                rd_addr_gray <= bin2gray(rd_addr + 1'b1);
        end
end

// synchronize write address to read clock domain
always @(posedge rd_clk_i) 
if(rd_rst_i) begin
        wr_addr_gray_rd   <= {ADDR_WIDTH{1'b0}};
        wr_addr_gray_rd_r <= {ADDR_WIDTH{1'b0}};
end
else begin
        wr_addr_gray_rd <= wr_addr_gray;
        wr_addr_gray_rd_r <= wr_addr_gray_rd;
end

always @(posedge rd_clk_i)
        if (rd_rst_i)
                empty_o <= 1'b1;
        else if (rd_en_i)
                empty_o <= bin2gray(rd_addr + 1) == wr_addr_gray_rd_r;
        else
                empty_o <= empty_o & (bin2gray(rd_addr) == wr_addr_gray_rd_r);

// generate dual clocked memory
reg [DATA_WIDTH-1:0] mem[(1<<ADDR_WIDTH)-1:0];

//always @(posedge rd_clk_i)
//        if (rd_en_i)
always @(*)
   rd_data_o = mem[rd_addr];

always @(posedge wr_clk_i)
        if (wr_en_i)
                mem[wr_addr] <= wr_data_i;

// fullness
//always @ (posedge wr_clk_i)
//  if(wr_rst_i)
//    wr_fullness[ADDR_WIDTH-1:0] <= 'h0;
//  else if(full_o)
//    wr_fullness[ADDR_WIDTH-1:0] <= 'h0;
//  else if(wr_addr >= gray2bin(rd_addr_gray_wr_r))
//    wr_fullness[ADDR_WIDTH-1:0] <= wr_addr - gray2bin(rd_addr_gray_wr_r);
//  else if(wr_addr < gray2bin(rd_addr_gray_wr_r))
//    wr_fullness[ADDR_WIDTH-1:0] <= gray2bin(rd_addr_gray_wr_r) - wr_addr;
//    
//always @ (posedge wr_clk_i)
//  if(wr_rst_i)
//    wr_fullness[ADDR_WIDTH] <= 'h0;
//  else 
//    wr_fullness[ADDR_WIDTH] <= full_o;

endmodule
module fifo_fwft
  #(parameter DATA_WIDTH = 0,
    parameter DEPTH_WIDTH = 0)
   (
    input                   clk,
    input                   rst,
    input [DATA_WIDTH-1:0]  din,
    input                   wr_en,
    output                  full,
    output [DATA_WIDTH-1:0] dout,
    input                   rd_en,
    output                  empty,
    output reg [DEPTH_WIDTH:0] fullness,
    output reg [DEPTH_WIDTH:0] emptyness
);

always @ (posedge clk)
if(rst) begin
  fullness <= 'h0;
end
else begin
  case ({wr_en,rd_en})
    2'b00, 2'b11: fullness<= fullness;
    2'b10:        fullness <= fullness+1;
    2'b01:        fullness <= fullness-1;
  endcase
end

always @ (posedge clk)
if(rst) begin
  emptyness<= {1'b1, {DEPTH_WIDTH{1'b0}}};
end
else begin
  case ({wr_en,rd_en})
    2'b00, 2'b11: emptyness<= emptyness;
    2'b10:        emptyness<= emptyness-1;
    2'b01:        emptyness<= emptyness+1;
  endcase
end


   wire [DATA_WIDTH-1:0]    fifo_dout;
   wire                     fifo_empty;
   wire                     fifo_rd_en;

   // orig_fifo is just a normal (non-FWFT) synchronous or asynchronous FIFO
   fifo
     #(.DEPTH_WIDTH (DEPTH_WIDTH),
       .DATA_WIDTH  (DATA_WIDTH))
   fifo0
     (
      .clk       (clk),
      .rst       (rst),
      .rd_en_i   (fifo_rd_en),
      .rd_data_o (fifo_dout),
      .empty_o   (fifo_empty),
      .wr_en_i   (wr_en),
      .wr_data_i (din),
      .full_o    (full));

   fifo_fwft_adapter
     #(.DATA_WIDTH (DATA_WIDTH))
   fwft_adapter
     (.clk          (clk),
      .rst          (rst),
      .rd_en_i      (rd_en),
      .fifo_empty_i (fifo_empty),
      .fifo_rd_en_o (fifo_rd_en),
      .fifo_dout_i  (fifo_dout),
      .dout_o       (dout),
      .empty_o      (empty));

endmodule
module fifo_fwft_adapter
  #(parameter DATA_WIDTH = 0)
   (input 	       clk,
    input 			rst,
    input 			rd_en_i,
    input 			fifo_empty_i,
    output 			fifo_rd_en_o,
    input [DATA_WIDTH-1:0] 	fifo_dout_i,
    output reg [DATA_WIDTH-1:0] dout_o,
    output 			empty_o);
   
   reg 				fifo_valid, middle_valid, dout_valid;
   reg [DATA_WIDTH-1:0] 	middle_dout;
   
   wire 			will_update_middle, will_update_dout;

   assign will_update_middle = fifo_valid && (middle_valid == will_update_dout);
   assign will_update_dout = (middle_valid || fifo_valid) && (rd_en_i || !dout_valid);
   assign fifo_rd_en_o = (!fifo_empty_i) && !(middle_valid && dout_valid && fifo_valid);
   assign empty_o = !dout_valid;

   always @(posedge clk)
      if (rst)
         begin
            fifo_valid <= 0;
            middle_valid <= 0;
            dout_valid <= 0;
            dout_o <= 0;
            middle_dout <= 0;
         end
      else
         begin
            if (will_update_middle)
               middle_dout <= fifo_dout_i;
            
            if (will_update_dout)
               dout_o <= middle_valid ? middle_dout : fifo_dout_i;
            
            if (fifo_rd_en_o)
               fifo_valid <= 1;
            else if (will_update_middle || will_update_dout)
               fifo_valid <= 0;
            
            if (will_update_middle)
               middle_valid <= 1;
            else if (will_update_dout)
               middle_valid <= 0;
            
            if (will_update_dout)
               dout_valid <= 1;
            else if (rd_en_i)
               dout_valid <= 0;
         end 
   
endmodule
/******************************************************************************
 This Source Code Form is subject to the terms of the
 Open Hardware Description License, v. 1.0. If a copy
 of the OHDL was not distributed with this file, You
 can obtain one at http://juliusbaxter.net/ohdl/ohdl.txt

 Description: Store buffer
 Currently a simple single clock FIFO, but with the ambition to
 have combining and reordering capabilities in the future.

 Copyright (C) 2013 Stefan Kristiansson <stefan.kristiansson@saunalahti.fi>

 ******************************************************************************/

module fifo
  #(
    parameter DEPTH_WIDTH = 0,
    parameter DATA_WIDTH = 0
    )
   (
    input 		    clk,
    input 		    rst,

    input [DATA_WIDTH-1:0]  wr_data_i,
    input 		    wr_en_i,

    output [DATA_WIDTH-1:0] rd_data_o,
    input 		    rd_en_i,

    output 		    full_o,
    output 		    empty_o
    );

   localparam DW = (DATA_WIDTH  < 1) ? 1 : DATA_WIDTH;
   localparam AW = (DEPTH_WIDTH < 1) ? 1 : DEPTH_WIDTH;

   //synthesis translate_off
   initial begin
      if(DEPTH_WIDTH < 1) $display("%m : Warning: DEPTH_WIDTH must be > 0. Setting minimum value (1)");
      if(DATA_WIDTH < 1) $display("%m : Warning: DATA_WIDTH must be > 0. Setting minimum value (1)");
   end
   //synthesis translate_on

   reg [AW:0] write_pointer;
   reg [AW:0] read_pointer;

   wire 	       empty_int = (write_pointer[AW] ==
				    read_pointer[AW]);
   wire 	       full_or_empty = (write_pointer[AW-1:0] ==
					read_pointer[AW-1:0]);
   
   assign full_o  = full_or_empty & !empty_int;
   assign empty_o = full_or_empty & empty_int;
   
   always @(posedge clk) begin
      if (wr_en_i)
	write_pointer <= write_pointer + 1'd1;

      if (rd_en_i)
	read_pointer <= read_pointer + 1'd1;

      if (rst) begin
	 read_pointer  <= 0;
	 write_pointer <= 0;
      end
   end
   simple_dpram_sclk
     #(
       .ADDR_WIDTH(AW),
       .DATA_WIDTH(DW),
       .ENABLE_BYPASS(1)
       )
   fifo_ram
     (
      .clk			(clk),
      .dout			(rd_data_o),
      .raddr			(read_pointer[AW-1:0]),
      .re			(rd_en_i),
      .waddr			(write_pointer[AW-1:0]),
      .we			(wr_en_i),
      .din			(wr_data_i)
      );

endmodule
/******************************************************************************
 This Source Code Form is subject to the terms of the
 Open Hardware Description License, v. 1.0. If a copy
 of the OHDL was not distributed with this file, You
 can obtain one at http://juliusbaxter.net/ohdl/ohdl.txt

 Description:
 Simple single clocked dual port ram (separate read and write ports),
 with optional bypass logic.

 Copyright (C) 2012 Stefan Kristiansson <stefan.kristiansson@saunalahti.fi>

 ******************************************************************************/

module simple_dpram_sclk
  #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ENABLE_BYPASS = 1
    )
   (
    input                   clk,
    input [ADDR_WIDTH-1:0]  raddr,
    input                   re,
    input [ADDR_WIDTH-1:0]  waddr,
    input                   we,
    input [DATA_WIDTH-1:0]  din,
    output [DATA_WIDTH-1:0] dout
    );

   reg [DATA_WIDTH-1:0]     mem[(1<<ADDR_WIDTH)-1:0];
   reg [DATA_WIDTH-1:0]     rdata;

generate
if (ENABLE_BYPASS) begin : bypass_gen
   reg [DATA_WIDTH-1:0]     din_r;
   reg                      bypass;

   assign dout = bypass ? din_r : rdata;

   always @(posedge clk)
     if (re)
       din_r <= din;

   always @(posedge clk)
     if ((waddr == raddr) && we && re)
       bypass <= 1;
     else if (re)
       bypass <= 0;
end else begin
   assign dout = rdata;
end
endgenerate

   always @(posedge clk) begin
      if (we)
        mem[waddr] <= din;
      if (re)
        rdata <= mem[raddr];
   end

endmodule
