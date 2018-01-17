//
//---------------------------------------------------------------------------
// bitonic sort network. look into documentation for terminologies - bitonic-sort-hw-development.pptx
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

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

   
