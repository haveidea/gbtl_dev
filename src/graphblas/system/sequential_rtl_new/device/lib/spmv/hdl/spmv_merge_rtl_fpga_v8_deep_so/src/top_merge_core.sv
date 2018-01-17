//  
// Top level module to glue scanchain and the core 
//---------------------------------------------------------------------------
//

`include "definitions.vh"

module top_merge_core
   (//input
    input  offchip_scan_clk, offchip_main_clk, //for initial write, zero propagate and output offchip_scan_clk should be connected to core 
    input rst_b_scanchain, rst_b_clk_div_only, en_run, clk_select,
    input [1 : 0] scan_state_ctl_signal,	 
    input scan_in,
    //output
    output scan_out);
   
   //core inputs
   wire core_clk, rst_b_clk_div, rst_b, core_en, mode, wr_en_core_input;
   wire [`NUM_STGs - 1 : 0] wr_addr_core_input;
   wire [`DATA_WIDTH_INPUT - 1 : 0] data_in_core;
   wire [`BITS_UNIT_SELECTION + `BITS_OUTPUT_ADDR_PER_UNIT - 1 : 0] rd_addr_core_output;
   //core outputs
   wire [`BITS_OUTPUT_ADDR_PER_UNIT - 1 : 0] wr_addr_core_output;
   wire core_out_valid;
   wire [`BITS_ROW_IDX - 1 : 0] core_out_row_idx;
   wire [`DATA_PRECISION - 1 : 0] core_out_value;
   
   scanchain_merge_core scanchain
     (//input
      .scan_clk(offchip_scan_clk), .main_clk(offchip_main_clk), 
      .rst_b_scanchain, .rst_b_clk_div_only, .en_run, .clk_select,
      .scan_state_ctl_signal,
      .scan_in,
      //output
      .scan_out,
      //module out
      .core_clk, .rst_b_clk_div, .rst_b, .core_en, .mode, .wr_en_core_input, 
      .wr_addr_core_input,    
      .data_in_core,
      .rd_addr_core_output,
      //modeule in
      .wr_addr_core_output,
      .core_out_valid, .core_out_row_idx, .core_out_value);
   
   merge_core core 
     (//input
      .clk(core_clk), .rst_b_clk_div, .rst_b, .core_en, .mode, .wr_en_core_input,
      .wr_addr_core_input,
      .data_in_core,
      .rd_addr_core_output,
      //output
      .wr_addr_core_output,	       
      .core_out_valid, .core_out_row_idx, .core_out_value);

endmodule // top
