//
//---------------------------------------------------------------------------
//  Entire decoder for the merge block
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module decoder_blk_slow_BRAM_RE (

   input decode_en_blk,
   input [`NUM_STGs - `END_OF_FAST_STG - 1 : 0] addr_seg,
   //output for all segments
   output [(1<<(`NUM_STGs - `START_OF_BIG_STG))*2 - 2 : 0] BRAM_RE);

//Generating the BRAM_RE decoded signals for the segments with lim//

//BRAM_RE for stage 7 of an segment
assign BRAM_RE[0] = decode_en_blk;

//BRAM_RE for stage 8
assign BRAM_RE[1] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 1] && BRAM_RE[0];
assign BRAM_RE[2] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 1] && BRAM_RE[0];

//BRAM_RE for stage 9
assign BRAM_RE[3] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 2] && BRAM_RE[1];
assign BRAM_RE[4] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 2] && BRAM_RE[1];
assign BRAM_RE[5] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 2] && BRAM_RE[2];
assign BRAM_RE[6] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 2] && BRAM_RE[2];

//BRAM_RE for stage 10
assign BRAM_RE[7] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && BRAM_RE[3];
assign BRAM_RE[8] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && BRAM_RE[3];
assign BRAM_RE[9] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && BRAM_RE[4];
assign BRAM_RE[10] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && BRAM_RE[4];
assign BRAM_RE[11] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && BRAM_RE[5];
assign BRAM_RE[12] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && BRAM_RE[5];
assign BRAM_RE[13] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && BRAM_RE[6];
assign BRAM_RE[14] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && BRAM_RE[6];

//BRAM_RE for stage 11
assign BRAM_RE[15] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[7];
assign BRAM_RE[16] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[7];
assign BRAM_RE[17] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[8];
assign BRAM_RE[18] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[8];
assign BRAM_RE[19] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[9];
assign BRAM_RE[20] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[9];
assign BRAM_RE[21] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[10];
assign BRAM_RE[22] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[10];
assign BRAM_RE[23] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[11];
assign BRAM_RE[24] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[11];
assign BRAM_RE[25] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[12];
assign BRAM_RE[26] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[12];
assign BRAM_RE[27] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[13];
assign BRAM_RE[28] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[13];
assign BRAM_RE[29] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[14];
assign BRAM_RE[30] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && BRAM_RE[14];

endmodule