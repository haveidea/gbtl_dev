module perf_mon(
input  ddr3_clk,
input ddr3_reset,

output  reg  [31:0]              mmap_test_rcnt,
output  reg  [31:0]              mmap_test_wcnt,
output  reg  [31:0]              mmap_test_cycle_cnt_l,
output  reg  [31:0]              mmap_test_cycle_cnt_h,
input        clr_test_wcnt,
input        clr_test_rcnt,
input        cycle_cnt_en,
input        m0_readdatavalid,
input        m0_write,
input        m0_waitrequest
);

always @ (posedge ddr3_clk)
if(ddr3_reset) begin
    mmap_test_cycle_cnt_l <= 'h0;
    mmap_test_cycle_cnt_h <= 'h0;
end
else if( clr_test_wcnt | clr_test_rcnt) begin
    mmap_test_cycle_cnt_l <= 'h0;
    mmap_test_cycle_cnt_h <= 'h0;
end
else if(cycle_cnt_en)
begin
    mmap_test_cycle_cnt_l <= mmap_test_cycle_cnt_l+1;
    if(mmap_test_cycle_cnt_l == {32{1'b1}})
      mmap_test_cycle_cnt_h <= mmap_test_cycle_cnt_h + 1;
end

// performance counter control
// performance counter for hammer only
always @ (posedge ddr3_clk)
if(ddr3_reset)
  mmap_test_rcnt <= 'h0;
else if(clr_test_rcnt)
  mmap_test_rcnt <= 'h0;
else if  (m0_readdatavalid)
  mmap_test_rcnt <= mmap_test_rcnt+1;

always @ (posedge ddr3_clk)
if(ddr3_reset) 
  mmap_test_wcnt <= 'h0;
else if(clr_test_wcnt)
  mmap_test_wcnt <= 'h0;
else if  (m0_write & ~m0_waitrequest)
  mmap_test_wcnt <= mmap_test_wcnt+1;

endmodule
