module biquad_filter_tb;
  reg clk;
  reg reset;
  reg  [15:0] din;
  wire [15:0] dout;

  // Instantiate the biquad_filter module
  biquad_filter #(
    .INOUT_WIDTH(16),
    .INOUT_DECIMAL_WIDTH(14),
    .COEF_WIDTH(24),
    .COEF_DECIMAL_WIDTH(22),
    .INTERNAL_WIDTH(24),
    .INTERNAL_DECIMAL_WIDTH(22),
    .b0(24'h400000),  //   1    0x400000
    .b1(24'hc00000),  //  -1    0xc00000
    .b2(24'h000000),  // 0
    .a1(24'h000000),  // 0
    .a2(24'h000000)   // 0
  ) dut (
    .clk(clk),
    .reset(reset),
    .din(din),
    .dout(dout)
  );

  // Clock generation
  always begin
    #5 clk = ~clk;
  end

  // Initialize signals
  initial begin
    $dumpfile("biquad_filter_tb.vcd");
	  $dumpvars(0,biquad_filter_tb); 

    clk = 0;
    reset = 0;
    din = 0;

    // Apply reset
    #10 reset = 1;

    // Wait for a few clock cycles
    #20 reset = 0;

    // Apply input values and observe outputs
    din = 16'hc000;

    // Stop simulation
    #200000 $finish;
  end

endmodule
