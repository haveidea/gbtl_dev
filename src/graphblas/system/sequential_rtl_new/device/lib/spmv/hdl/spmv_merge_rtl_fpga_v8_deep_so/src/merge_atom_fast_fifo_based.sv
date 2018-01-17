//
//---------------------------------------------------------------------------
//  Minimum building block of the fast merge network  
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

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
