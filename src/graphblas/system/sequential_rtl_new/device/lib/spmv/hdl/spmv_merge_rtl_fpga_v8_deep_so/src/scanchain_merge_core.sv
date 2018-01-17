//
//---------------------------------------------------------------------------
//    
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module scanchain_merge_core
  #(//parameter
    NUM_MAIN_CORE_CTL = 3, //i.e. core_en, mode, wr_en_core_input 
    SC_INPUT_LENGTH = NUM_MAIN_CORE_CTL + `NUM_STGs + `DATA_WIDTH_INPUT + `BITS_UNIT_SELECTION + `BITS_OUTPUT_ADDR_PER_UNIT,
    SC_OUTPUT_LENGTH = `BITS_OUTPUT_ADDR_PER_UNIT + 1 + `BITS_ROW_IDX + `DATA_PRECISION,
    SC_TOTAL_LENGTH = SC_INPUT_LENGTH + SC_OUTPUT_LENGTH)
   (//input
    input scan_clk, main_clk, rst_b_scanchain, rst_b_clk_div_only, en_run, clk_select,
    input [1 : 0] scan_state_ctl_signal,
    input scan_in,
    //output
    output scan_out,
    //module out
    output core_clk, rst_b_clk_div, rst_b, core_en, mode, wr_en_core_input, 
    output [`NUM_STGs - 1 : 0] wr_addr_core_input,    
    output [`DATA_WIDTH_INPUT - 1 : 0] data_in_core,
    output [`BITS_UNIT_SELECTION + `BITS_OUTPUT_ADDR_PER_UNIT - 1 : 0] rd_addr_core_output,
    //modeule in
    input [`BITS_OUTPUT_ADDR_PER_UNIT - 1 : 0] wr_addr_core_output,
    input core_out_valid,
    input [`BITS_ROW_IDX - 1 : 0] core_out_row_idx,			  
    input [`DATA_PRECISION - 1 : 0] core_out_value);

   //Bypass the scanchain reset to core as well
   assign rst_b = rst_b_scanchain;
   assign rst_b_clk_div = rst_b_clk_div_only;
   assign core_clk = clk_select ? main_clk : scan_clk;
      
   //Scanchain registers
   reg [SC_TOTAL_LENGTH - 1 : 0] scan_chain; //these are on the output side of the scanchain
   reg [SC_TOTAL_LENGTH - 1 : 0] scan_chain_next; //these are on the input side of the scanchain    

   //Core input signal assignments
   //wire en_run;//Don't do like this, issue maya arise. Get en_run as input.
   //assign en_run = (scan_state_ctl_signal[1] & ~scan_state_ctl_signal[0]); //run if you're in STATE2
   
   assign core_en = scan_chain[0] & en_run;
   assign mode = scan_chain[1];
   assign wr_en_core_input = scan_chain[2] & en_run;
   assign wr_addr_core_input = scan_chain[`NUM_STGs + NUM_MAIN_CORE_CTL - 1 : NUM_MAIN_CORE_CTL];
   assign data_in_core = scan_chain[`DATA_WIDTH_INPUT + `NUM_STGs + NUM_MAIN_CORE_CTL - 1 : `NUM_STGs + NUM_MAIN_CORE_CTL];
   assign rd_addr_core_output = scan_chain[`BITS_UNIT_SELECTION + `BITS_OUTPUT_ADDR_PER_UNIT + `DATA_WIDTH_INPUT + `NUM_STGs + NUM_MAIN_CORE_CTL - 1 : `DATA_WIDTH_INPUT + `NUM_STGs + NUM_MAIN_CORE_CTL];

   //Core output signal assignment 
   assign scan_out = scan_chain[SC_TOTAL_LENGTH - 1]; 
   
   // Scan-chain is controlled by STATES (scan_ctl_signal decides at which state you are)
   always_comb begin
      case(scan_state_ctl_signal)
	//State0 -- idle
	2'b00: scan_chain_next = scan_chain;
    
	//State1 -- scan in (SHIFT IN THE DATA / SHIFT OUT THE DATA); 
	2'b01: scan_chain_next = {scan_chain[SC_TOTAL_LENGTH - 2 : 0], scan_in};
    
	//State2 -- module operation (CORE IS WORKING)
	2'b10: scan_chain_next = scan_chain;
    
	//State3 -- CAPTURE the core outputs (once done, go back to state1 to shift out);  
	2'b11: scan_chain_next = {wr_addr_core_output, core_out_valid, core_out_row_idx, core_out_value, scan_chain[SC_INPUT_LENGTH - 1 : 0]} ; //not touching scan_chain[inputs] to be able to observe the inputs at output

	//default: scan_chain_next = scan_chain ;
   endcase
end

   //Scanchain FFs
   always @ (posedge scan_clk or negedge rst_b_scanchain) begin
      if (rst_b_scanchain == 0)
	scan_chain <= 0 ;
      else
	scan_chain <= scan_chain_next;
   end 
   
endmodule // scanchain_merge_core
