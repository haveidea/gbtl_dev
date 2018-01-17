//
//---------------------------------------------------------------------------
// Merge unit connects the fast and slow blocks (without the adders)   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

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
