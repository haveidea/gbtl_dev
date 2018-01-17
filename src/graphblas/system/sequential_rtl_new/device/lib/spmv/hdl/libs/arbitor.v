module arbitor 
#(parameter ARB_WIDTH=4)
(
  input clk,
  input rstn,
  
  input                     next, // piority will change on the next cycle of next.
  input      [ARB_WIDTH-1:0] valid,
  output     [ARB_WIDTH-1:0] grant
);

    function integer clogb2 (input integer bit_depth);    
    begin    
      for(clogb2=0; bit_depth>0; clogb2=clogb2+1)    
        bit_depth = bit_depth >> 1;    
      end    
    endfunction    

  
localparam CLOG2_ARB_WIDTH = clogb2(ARB_WIDTH);
    function [CLOG2_ARB_WIDTH-1:0] ff1;
        input [ARB_WIDTH-1:0] in;
        integer i;
        begin
            ff1 = 0;
            for (i = ARB_WIDTH-1; i >= 0; i=i-1) begin
                if (in[i])
                    ff1 = i;
            end
        end
    endfunction

reg [CLOG2_ARB_WIDTH-1 : 0] cur_prior;

wire [ARB_WIDTH-1:0] grant_shift;
wire [ARB_WIDTH-1:0] grant_temp;
wire [2*ARB_WIDTH-1:0] valid_wrap;
wire [2*ARB_WIDTH-1:0] grant_shift_wrap;
wire [ARB_WIDTH-1:0] valid_shift;
assign valid_wrap = {valid, valid};

assign valid_shift = valid_wrap[cur_prior +: ARB_WIDTH];


always @ (posedge clk)
if(!rstn)
    cur_prior <= {CLOG2_ARB_WIDTH{1'b0}};
else if(next)begin
    if(cur_prior != (ARB_WIDTH-1))
      cur_prior <= cur_prior +1;
    else
      cur_prior <= {CLOG2_ARB_WIDTH{1'b0}};
end

assign grant_shift = (valid_shift == 0) ? 0 : (1 << ff1(valid_shift));

assign grant_shift_wrap = {grant_shift, grant_shift};

assign grant_temp = grant_shift_wrap[ARB_WIDTH -cur_prior +:ARB_WIDTH];

genvar ii;
generate 
  for(ii = 0; ii< ARB_WIDTH; ii = ii+1) begin : GENERATE_GRANT
  	assign grant[ii] = grant_temp[ii];
  end
endgenerate


endmodule
