//
//---------------------------------------------------------------------------
// Accumulator stage last   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

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
