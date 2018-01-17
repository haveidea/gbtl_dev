module avl_comb
#(parameter SLAVE_NUM = 4,ADDR_WIDTH = 32, DATA_WIDTH = 512)
(
 input clk,
 input reset,
  
 input      [ADDR_WIDTH *SLAVE_NUM -1:0]     s_address      ,
 input      [SLAVE_NUM-1:0]                  s_read         ,
 output     [SLAVE_NUM-1:0]                  s_waitrequest  ,
 output reg [DATA_WIDTH * SLAVE_NUM -1:0]    s_readdata     , // done
 input      [SLAVE_NUM-1:0]                  s_write        ,
 input      [DATA_WIDTH * SLAVE_NUM-1:0]     s_writedata    ,
 output reg [SLAVE_NUM-1:0]                  s_readdatavalid, // done
 input      [DATA_WIDTH * SLAVE_NUM/8 - 1:0] s_be           ,
 input      [7 * SLAVE_NUM -1:0]             s_burstcount   ,

 output reg [ADDR_WIDTH-1:0]        m_address      ,
 output reg                         m_read         ,
 input                              m_waitrequest  ,
 input  [DATA_WIDTH-1:0]            m_readdata     , // done
 output reg                         m_write        ,
 output reg [DATA_WIDTH-1:0]        m_writedata    ,
 input                              m_readdatavalid, // done
 output reg [DATA_WIDTH/8 - 1:0]    m_be           ,
 output reg [6:0]                   m_burstcount   
);

genvar ii;
genvar jj;

reg request_latched ;
reg m_busy;
wire [SLAVE_NUM-1:0] sx_sel;

reg [SLAVE_NUM-1:0] sx_ongoing;

reg [SLAVE_NUM-1:0] sx_ongoing_d;

wire transit_cycle;
wire dummy_sel;
wire trans_done;

reg [9:0] nxt_pending_bursts;
reg [9:0] cur_pending_bursts;

always @ (posedge clk)
if(reset) begin
  sx_ongoing_d<={SLAVE_NUM{1'b0}};
end
else begin
  sx_ongoing_d<=sx_ongoing;
end

assign transit_cycle = &(~sx_ongoing);


generate 
  for (ii = 0; ii < SLAVE_NUM ; ii = ii + 1) begin
      always @ (posedge clk)
      if(reset)
        sx_ongoing[ii] <=  1'b0;
      else if((~m_busy & sx_sel[ii]) | (trans_done & sx_sel[ii]  & ~(|(sx_ongoing & {{(SLAVE_NUM - ii -1){1'b1}},1'b0,{ii{1'b1}}} ))))
        sx_ongoing[ii] <= 1'b1;
      else if(trans_done & ~sx_sel[ii])
        sx_ongoing[ii] <=  1'b0;
  end
endgenerate

generate 
  for (ii = 0; ii < SLAVE_NUM ; ii = ii + 1) begin
    always @ (posedge clk)
    if(reset) begin
      s_readdata[ii * DATA_WIDTH + DATA_WIDTH -1: ii*DATA_WIDTH] <= {DATA_WIDTH{1'b0}};
      s_readdatavalid[ii] <= 1'b0;
    end
    else begin
      s_readdata[ii * DATA_WIDTH + DATA_WIDTH -1: ii*DATA_WIDTH] <= m_readdata & {DATA_WIDTH{sx_ongoing[ii]}};
      s_readdatavalid[ii] <= (sx_ongoing[ii]) ? m_readdatavalid: 1'b0;
    end
  end
endgenerate
wire [SLAVE_NUM-1:0] sx_request;

generate 
  for (ii = 0; ii < SLAVE_NUM ; ii = ii + 1) begin
      assign sx_request[ii] = s_read[ii] | s_write[ii];
  end

endgenerate

wire m_keep = |(sx_request & sx_ongoing & sx_sel); 

always @ (posedge clk)
if(reset) 
  m_busy <= 1'b0;
else if(~m_busy & (|(sx_request & sx_ongoing & ~s_waitrequest) ))
  m_busy <= 1'b1;
else if(m_busy  & trans_done & m_keep)
  m_busy <= 1'b1;
else if(m_busy  & trans_done )
  m_busy <= 1'b0;

wire [SLAVE_NUM-1:0] sx_burstcount_permute[6:0];
generate 
  for (ii = 0; ii <7; ii = ii + 1) begin
    for (jj = 0; jj < SLAVE_NUM; jj = jj +1)  begin
        assign sx_burstcount_permute[ii][jj] = s_burstcount[jj*7 + ii];
    end
  end
endgenerate

generate 
  for (ii = 0; ii <7; ii = ii + 1) begin
  always @ (posedge clk)
  if(reset) begin
    m_burstcount[ii]   <= 'h0;
  end
  else begin
    m_burstcount[ii]   <= |((sx_ongoing & sx_sel & s_waitrequest)&sx_burstcount_permute[ii]);
  end
  end
endgenerate

wire [SLAVE_NUM-1:0] sx_be_permute[DATA_WIDTH/8-1:0];
generate begin
  for (ii = 0; ii <DATA_WIDTH/8; ii = ii + 1) begin
    for (jj = 0; jj < SLAVE_NUM; jj = jj +1)  begin
       assign sx_be_permute[ii][jj] = s_be[jj*DATA_WIDTH/8+ ii];
    end
  end
end
endgenerate

generate 
  for (ii = 0; ii <DATA_WIDTH/8; ii = ii + 1)begin
  always @ (posedge clk)
  if(reset) begin
    m_be[ii]   <= 'h0;
  end
  else begin
    m_be[ii]   <= |((sx_ongoing & sx_sel & s_waitrequest)&sx_be_permute[ii]);
  end
end
endgenerate

wire [SLAVE_NUM-1:0] sx_writedata_permute[DATA_WIDTH-1:0];
generate begin
  for (ii = 0; ii <DATA_WIDTH; ii = ii + 1) begin
    for (jj = 0; jj < SLAVE_NUM; jj = jj +1)  begin
      assign  sx_writedata_permute[ii][jj] = s_writedata[jj*DATA_WIDTH+ ii];
    end
  end
end
endgenerate

generate 
  for (ii = 0; ii <DATA_WIDTH; ii = ii + 1)begin
  always @ (posedge clk)
  if(reset) begin
    m_writedata[ii]   <= 'h0;
  end
  else begin
    m_writedata[ii]   <= |((sx_ongoing & sx_sel & s_waitrequest)&sx_writedata_permute[ii]);
  end
end
endgenerate

wire [SLAVE_NUM-1:0] sx_address_permute[ADDR_WIDTH -1:0];
generate begin
  for (ii = 0; ii <ADDR_WIDTH; ii = ii + 1) begin
    for (jj = 0; jj < SLAVE_NUM; jj = jj +1)  begin
      assign  sx_address_permute[ii][jj] = s_address[jj*ADDR_WIDTH + ii];
    end
  end
end
endgenerate

generate 
  for (ii = 0; ii <ADDR_WIDTH; ii = ii + 1)begin
      always @ (posedge clk)
      if(reset) begin
        m_address[ii]   <= 1'b0;
      end
      else begin
        m_address[ii]   <= |((sx_ongoing & sx_sel & s_waitrequest)&sx_address_permute[ii]);
      end
  end
endgenerate

always @ (posedge clk)
if(reset) 
  m_write<= 1'b0;
else if(|(s_write & sx_sel & ~s_waitrequest))
  m_write<= 1'b1;
else if(~m_waitrequest)
  m_write<= 1'b0;

always @ (posedge clk)
if(reset) 
  m_read      <= 1'b0;
else if(|(s_read & sx_sel & ~s_waitrequest))
    m_read <= 1'b1;
else if(~m_waitrequest)
    m_read <= 1'b0;

generate begin
  for (ii = 0; ii < SLAVE_NUM ; ii = ii + 1) begin
      assign s_waitrequest[ii] =  (m_busy & ~trans_done) | ~sx_ongoing[ii] | ~sx_sel[ii] | transit_cycle;
  end
end
endgenerate

wire next = ~m_busy | trans_done;

arbitor #(.ARB_WIDTH(SLAVE_NUM)) u_arb(
  .clk(clk),
  .rstn(~reset),
  .next(next),
  .valid(sx_request),
  .grant(sx_sel)
);


wire [7*SLAVE_NUM + 6:0] sx_burstcount_l;
wire [SLAVE_NUM -1:0] sx_burstcount_l_permute[6:0];

generate begin
  for (ii = 0; ii < SLAVE_NUM ; ii = ii + 1) begin
    assign sx_burstcount_l[ii*7+6:ii*7] = s_burstcount[ii*7+6: ii*7] & {7{sx_request & ~s_waitrequest}};
  end
end
endgenerate

wire [6:0] s_burstcount_l;

generate begin
  for (ii = 0; ii < 7; ii = ii + 1) begin
    for (jj = 0 ;jj < SLAVE_NUM ; jj = jj + 1) begin
      assign sx_burstcount_l_permute[ii][jj] = sx_burstcount_l[jj*7+ii];
    end
  end
end
endgenerate

assign s_burstcount_l[0] = |sx_burstcount_l_permute[0];
assign s_burstcount_l[1] = |sx_burstcount_l_permute[1];
assign s_burstcount_l[2] = |sx_burstcount_l_permute[2];
assign s_burstcount_l[3] = |sx_burstcount_l_permute[3];
assign s_burstcount_l[4] = |sx_burstcount_l_permute[4];
assign s_burstcount_l[5] = |sx_burstcount_l_permute[5];
assign s_burstcount_l[6] = |sx_burstcount_l_permute[6];


always @ (posedge clk)
if(reset)
  cur_pending_bursts<= 'h0;
else
  cur_pending_bursts<= nxt_pending_bursts;

wire s_request_issue = |(sx_request & ~s_waitrequest);

always @ (m_read or m_write or m_waitrequest or cur_pending_bursts or m_burstcount or m_readdatavalid)
begin
  nxt_pending_bursts = cur_pending_bursts;
casez ({m_read, m_write, m_waitrequest, m_readdatavalid})
  4'b0000: nxt_pending_bursts = cur_pending_bursts;
  4'b0001: nxt_pending_bursts = cur_pending_bursts-1;
  4'b0010: nxt_pending_bursts = cur_pending_bursts;
  4'b0011: nxt_pending_bursts = cur_pending_bursts-1;

  4'b0100: nxt_pending_bursts = cur_pending_bursts + m_burstcount - 1;
  4'b0101: nxt_pending_bursts = cur_pending_bursts + m_burstcount - 2;
  4'b0110: nxt_pending_bursts = cur_pending_bursts;
  4'b0111: nxt_pending_bursts = cur_pending_bursts - 1;

  4'b1000: nxt_pending_bursts = cur_pending_bursts + m_burstcount;
  4'b1001: nxt_pending_bursts = cur_pending_bursts + m_burstcount -1 ;
  4'b1010: nxt_pending_bursts = cur_pending_bursts;
  4'b1011: nxt_pending_bursts = cur_pending_bursts - 1;
  default: nxt_pending_bursts = cur_pending_bursts;
endcase
end

//assign nxt_pending_bursts = ((m_read|m_write) & ~m_waitrequest)? cur_pending_bursts + m_burstcount - (~m_waitrequest & m_write)  - m_readdatavalid : cur_pending_bursts -  (~m_waitrequest & m_write)  - m_readdatavalid;


reg m_waitrequest_d;
reg m_write_d;

always @ (posedge clk)
if(reset)
begin
  m_write_d <= 1'b0;
  m_waitrequest_d <= 1'b0;
end
else begin
  m_write_d <= m_write;
  m_waitrequest_d <= m_waitrequest;
end

reg m_readdatavalid_d;

assign trans_done = (nxt_pending_bursts == 'h0) & ((~m_waitrequest& m_write) | m_readdatavalid) ;

endmodule
