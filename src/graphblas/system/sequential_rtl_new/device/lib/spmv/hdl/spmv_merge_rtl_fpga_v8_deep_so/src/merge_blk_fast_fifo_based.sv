//
//---------------------------------------------------------------------------
// Fast merge block with fast stages 
// This is an array of merge stages that works on fast clk speed
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

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
