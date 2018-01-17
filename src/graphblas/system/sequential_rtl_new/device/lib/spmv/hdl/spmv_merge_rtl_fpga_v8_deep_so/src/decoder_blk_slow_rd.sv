//
//---------------------------------------------------------------------------
//  Entire decoder for the merge block
//  
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module decoder_blk_slow_rd (

   input decode_en_blk,
   input [`NUM_STGs - `END_OF_FAST_STG - 1 : 0] addr_seg,
   //output for all segments
   //output [(1<<(`NUM_STGs - `START_OF_BIG_STG))*2 - 2 : 0] BLK_RE,
   output [(1<<(`NUM_STGs - `END_OF_FAST_STG))*2 - 2 : 0] wl_seg);

//decoded wl for stage 2 of Merge block
assign wl_seg[0] = decode_en_blk;

//decoded wl for stage 3
assign wl_seg[1] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 1] && wl_seg[0];
assign wl_seg[2] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 1] && wl_seg[0];

//decoded wl for stage 4
assign wl_seg[3] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 2] && wl_seg[1];
assign wl_seg[4] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 2] && wl_seg[1];
assign wl_seg[5] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 2] && wl_seg[2];
assign wl_seg[6] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 2] && wl_seg[2];

//decoded wl for stage 5
assign wl_seg[7] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && wl_seg[3];
assign wl_seg[8] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && wl_seg[3];
assign wl_seg[9] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && wl_seg[4];
assign wl_seg[10] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && wl_seg[4];
assign wl_seg[11] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && wl_seg[5];
assign wl_seg[12] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && wl_seg[5];
assign wl_seg[13] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && wl_seg[6];
assign wl_seg[14] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 3] && wl_seg[6];

//decoded wl for stage 6
assign wl_seg[15] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[7];
assign wl_seg[16] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[7];
assign wl_seg[17] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[8];
assign wl_seg[18] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[8];
assign wl_seg[19] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[9];
assign wl_seg[20] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[9];
assign wl_seg[21] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[10];
assign wl_seg[22] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[10];
assign wl_seg[23] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[11];
assign wl_seg[24] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[11];
assign wl_seg[25] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[12];
assign wl_seg[26] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[12];
assign wl_seg[27] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[13];
assign wl_seg[28] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[13];
assign wl_seg[29] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[14];
assign wl_seg[30] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 4] && wl_seg[14];

//decoded wl for stage 7
assign wl_seg[31] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[15];
assign wl_seg[32] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[15];
assign wl_seg[33] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[16];
assign wl_seg[34] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[16];
assign wl_seg[35] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[17];
assign wl_seg[36] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[17];
assign wl_seg[37] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[18];
assign wl_seg[38] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[18];
assign wl_seg[39] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[19];
assign wl_seg[40] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[19];
assign wl_seg[41] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[20];
assign wl_seg[42] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[20];
assign wl_seg[43] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[21];
assign wl_seg[44] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[21];
assign wl_seg[45] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[22];
assign wl_seg[46] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[22];
assign wl_seg[47] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[23];
assign wl_seg[48] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[23];
assign wl_seg[49] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[24];
assign wl_seg[50] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[24];
assign wl_seg[51] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[25];
assign wl_seg[52] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[25];
assign wl_seg[53] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[26];
assign wl_seg[54] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[26];
assign wl_seg[55] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[27];
assign wl_seg[56] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[27];
assign wl_seg[57] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[28];
assign wl_seg[58] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[28];
assign wl_seg[59] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[29];
assign wl_seg[60] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[29];
assign wl_seg[61] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[30];
assign wl_seg[62] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 5] && wl_seg[30];

//decoded wl for stage 8
assign wl_seg[63] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[31];
assign wl_seg[64] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[31];
assign wl_seg[65] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[32];
assign wl_seg[66] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[32];
assign wl_seg[67] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[33];
assign wl_seg[68] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[33];
assign wl_seg[69] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[34];
assign wl_seg[70] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[34];
assign wl_seg[71] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[35];
assign wl_seg[72] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[35];
assign wl_seg[73] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[36];
assign wl_seg[74] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[36];
assign wl_seg[75] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[37];
assign wl_seg[76] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[37];
assign wl_seg[77] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[38];
assign wl_seg[78] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[38];
assign wl_seg[79] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[39];
assign wl_seg[80] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[39];
assign wl_seg[81] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[40];
assign wl_seg[82] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[40];
assign wl_seg[83] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[41];
assign wl_seg[84] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[41];
assign wl_seg[85] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[42];
assign wl_seg[86] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[42];
assign wl_seg[87] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[43];
assign wl_seg[88] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[43];
assign wl_seg[89] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[44];
assign wl_seg[90] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[44];
assign wl_seg[91] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[45];
assign wl_seg[92] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[45];
assign wl_seg[93] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[46];
assign wl_seg[94] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[46];
assign wl_seg[95] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[47];
assign wl_seg[96] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[47];
assign wl_seg[97] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[48];
assign wl_seg[98] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[48];
assign wl_seg[99] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[49];
assign wl_seg[100] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[49];
assign wl_seg[101] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[50];
assign wl_seg[102] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[50];
assign wl_seg[103] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[51];
assign wl_seg[104] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[51];
assign wl_seg[105] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[52];
assign wl_seg[106] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[52];
assign wl_seg[107] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[53];
assign wl_seg[108] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[53];
assign wl_seg[109] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[54];
assign wl_seg[110] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[54];
assign wl_seg[111] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[55];
assign wl_seg[112] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[55];
assign wl_seg[113] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[56];
assign wl_seg[114] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[56];
assign wl_seg[115] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[57];
assign wl_seg[116] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[57];
assign wl_seg[117] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[58];
assign wl_seg[118] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[58];
assign wl_seg[119] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[59];
assign wl_seg[120] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[59];
assign wl_seg[121] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[60];
assign wl_seg[122] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[60];
assign wl_seg[123] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[61];
assign wl_seg[124] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[61];
assign wl_seg[125] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[62];
assign wl_seg[126] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 6] && wl_seg[62];

//decoded wl for stage 9
assign wl_seg[127] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[63];
assign wl_seg[128] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[63];
assign wl_seg[129] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[64];
assign wl_seg[130] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[64];
assign wl_seg[131] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[65];
assign wl_seg[132] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[65];
assign wl_seg[133] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[66];
assign wl_seg[134] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[66];
assign wl_seg[135] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[67];
assign wl_seg[136] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[67];
assign wl_seg[137] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[68];
assign wl_seg[138] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[68];
assign wl_seg[139] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[69];
assign wl_seg[140] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[69];
assign wl_seg[141] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[70];
assign wl_seg[142] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[70];
assign wl_seg[143] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[71];
assign wl_seg[144] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[71];
assign wl_seg[145] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[72];
assign wl_seg[146] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[72];
assign wl_seg[147] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[73];
assign wl_seg[148] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[73];
assign wl_seg[149] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[74];
assign wl_seg[150] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[74];
assign wl_seg[151] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[75];
assign wl_seg[152] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[75];
assign wl_seg[153] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[76];
assign wl_seg[154] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[76];
assign wl_seg[155] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[77];
assign wl_seg[156] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[77];
assign wl_seg[157] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[78];
assign wl_seg[158] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[78];
assign wl_seg[159] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[79];
assign wl_seg[160] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[79];
assign wl_seg[161] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[80];
assign wl_seg[162] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[80];
assign wl_seg[163] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[81];
assign wl_seg[164] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[81];
assign wl_seg[165] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[82];
assign wl_seg[166] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[82];
assign wl_seg[167] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[83];
assign wl_seg[168] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[83];
assign wl_seg[169] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[84];
assign wl_seg[170] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[84];
assign wl_seg[171] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[85];
assign wl_seg[172] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[85];
assign wl_seg[173] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[86];
assign wl_seg[174] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[86];
assign wl_seg[175] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[87];
assign wl_seg[176] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[87];
assign wl_seg[177] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[88];
assign wl_seg[178] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[88];
assign wl_seg[179] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[89];
assign wl_seg[180] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[89];
assign wl_seg[181] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[90];
assign wl_seg[182] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[90];
assign wl_seg[183] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[91];
assign wl_seg[184] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[91];
assign wl_seg[185] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[92];
assign wl_seg[186] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[92];
assign wl_seg[187] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[93];
assign wl_seg[188] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[93];
assign wl_seg[189] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[94];
assign wl_seg[190] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[94];
assign wl_seg[191] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[95];
assign wl_seg[192] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[95];
assign wl_seg[193] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[96];
assign wl_seg[194] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[96];
assign wl_seg[195] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[97];
assign wl_seg[196] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[97];
assign wl_seg[197] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[98];
assign wl_seg[198] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[98];
assign wl_seg[199] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[99];
assign wl_seg[200] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[99];
assign wl_seg[201] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[100];
assign wl_seg[202] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[100];
assign wl_seg[203] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[101];
assign wl_seg[204] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[101];
assign wl_seg[205] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[102];
assign wl_seg[206] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[102];
assign wl_seg[207] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[103];
assign wl_seg[208] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[103];
assign wl_seg[209] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[104];
assign wl_seg[210] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[104];
assign wl_seg[211] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[105];
assign wl_seg[212] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[105];
assign wl_seg[213] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[106];
assign wl_seg[214] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[106];
assign wl_seg[215] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[107];
assign wl_seg[216] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[107];
assign wl_seg[217] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[108];
assign wl_seg[218] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[108];
assign wl_seg[219] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[109];
assign wl_seg[220] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[109];
assign wl_seg[221] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[110];
assign wl_seg[222] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[110];
assign wl_seg[223] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[111];
assign wl_seg[224] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[111];
assign wl_seg[225] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[112];
assign wl_seg[226] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[112];
assign wl_seg[227] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[113];
assign wl_seg[228] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[113];
assign wl_seg[229] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[114];
assign wl_seg[230] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[114];
assign wl_seg[231] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[115];
assign wl_seg[232] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[115];
assign wl_seg[233] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[116];
assign wl_seg[234] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[116];
assign wl_seg[235] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[117];
assign wl_seg[236] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[117];
assign wl_seg[237] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[118];
assign wl_seg[238] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[118];
assign wl_seg[239] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[119];
assign wl_seg[240] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[119];
assign wl_seg[241] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[120];
assign wl_seg[242] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[120];
assign wl_seg[243] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[121];
assign wl_seg[244] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[121];
assign wl_seg[245] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[122];
assign wl_seg[246] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[122];
assign wl_seg[247] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[123];
assign wl_seg[248] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[123];
assign wl_seg[249] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[124];
assign wl_seg[250] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[124];
assign wl_seg[251] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[125];
assign wl_seg[252] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[125];
assign wl_seg[253] = ~addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[126];
assign wl_seg[254] = addr_seg[(`NUM_STGs - `END_OF_FAST_STG) - 7] && wl_seg[126];

endmodule