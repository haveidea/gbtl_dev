//
//---------------------------------------------------------------------------
// Pipelined adder   
//
//  
//---------------------------------------------------------------------------
//
`include "definitions.vh"

module single_adder_pipe3 
  #(
    parameter
    NUM_STG_ADDER_PIPE = `NUM_STG_ADDER_PIPE)
   (
    input [1:0] aclr, //   aclr.aclr
    input [31:0] ax, //     ax.ax
    input [31:0] ay, //     ay.ay
    input clk, //    clk.clk
    input ena, //    ena.ena
    output [31:0] result); 
      
   logic [`RND_WIDTH - 1 : 0] rnd_nearest; 
   assign rnd_nearest = `RND_NEAREST;

   logic [`DATA_PRECISION - 1 : 0] data_in0_next, data_in1_next;
   logic [NUM_STG_ADDER_PIPE : 0] [`DATA_PRECISION - 1 : 0] z_inst_pipe;

   logic [NUM_STG_ADDER_PIPE : 0] [`STATUS_WIDTH - 1 : 0] status_pipe;
   logic [`STATUS_WIDTH - 1 : 0] status;
   
   DW_fp_add #(.sig_width(`SIG_WIDTH), .exp_width(`EXP_WIDTH), .ieee_compliance(`IEEE_COMPLIANCE))
   adder(
      .a(data_in0_next),
      .b(data_in1_next),
      .rnd(rnd_nearest),
      .z(z_inst_pipe[0]),
      .status(status_pipe[0]));

   integer i1;  
   always_ff @ (posedge clk) begin
      if(aclr == 2'b11) begin
	 data_in0_next <= '0;
	 data_in1_next <= '0;
	 for (i1 = 1; i1 < NUM_STG_ADDER_PIPE + 1; i1 = i1 + 1) begin
	    z_inst_pipe[i1] <= '0;
	    status_pipe[i1] <= '0;
	 end
      end
      else if (ena) begin
	 data_in0_next <= ax;
	 data_in1_next <= ay;
	 
	 for (i1 = 0; i1 < NUM_STG_ADDER_PIPE; i1 = i1 + 1) begin
	    z_inst_pipe[i1+1] <= z_inst_pipe[i1];
	    status_pipe[i1+1] <= status_pipe[i1];
	 end
      end
   end

   assign status = status_pipe[NUM_STG_ADDER_PIPE];
   assign result = z_inst_pipe[NUM_STG_ADDER_PIPE];

endmodule // single_adder_pipe3
