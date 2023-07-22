`timescale 1us/1ns


module oscillator_tb;

  // Parameters
  parameter COUNTER_WIDTH = 28;
  parameter OUTPUT_WIDTH = 24;
  parameter FCW_BITS = 24;

  // Inputs
  reg main_clk;
  reg sample_clk;
  reg reset;
  reg [1:0] sel;
  reg [FCW_BITS-1:0] fcw;

  // Outputs
  wire [OUTPUT_WIDTH-1:0] dout;

  // Instantiate the oscillator module
  oscillator #(
    .COUNTER_WIDTH(COUNTER_WIDTH),
    .OUTPUT_WIDTH(OUTPUT_WIDTH),
    .FCW_BITS(FCW_BITS)
  ) dut (
    .main_clk(main_clk),
    .sample_clk(sample_clk),
    .reset(reset),
    .sel(sel),
    .fcw(fcw),
    .dout(dout)
  );

  // Clock generation
  always #5.20833 main_clk = ~main_clk;      // 192Khz
  always #20.8333 sample_clk = ~sample_clk;  // 44.1Khz

  // Stimulus
  initial begin
    $dumpfile("oscillator_tb.vcd");
	  $dumpvars(0,oscillator_tb); 

    reset = 1;  // Apply reset
    main_clk = 0;
    sample_clk = 0;
    sel = 0;
    fcw = 24'd460856;  // Set the desired fcw - E4

    #1000 reset = 0; // Release reset

    // Change waveform selection every 100 time units
    #100000 sel = 1;
    #100000 sel = 2;
    #100000 sel = 3;

    // Stop simulation after 100 time units
    #100000 $finish;
  end

endmodule
