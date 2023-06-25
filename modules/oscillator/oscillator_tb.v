`timescale 1us/1ns


module oscillator_tb;

  // Parameters
  parameter COUNTER_WIDTH = 24;
  parameter OUTPUT_WIDTH = 12;
  parameter FREQ_BITS = 12;

  // Inputs
  reg main_clk;
  reg sample_clk;
  reg reset;
  reg [1:0] sel;
  reg [FREQ_BITS-1:0] freq;

  // Outputs
  wire [OUTPUT_WIDTH-1:0] dout;

  // Instantiate the oscillator module
  oscillator #(
    .COUNTER_WIDTH(COUNTER_WIDTH),
    .OUTPUT_WIDTH(OUTPUT_WIDTH),
    .FREQ_BITS(FREQ_BITS)
  ) dut (
    .main_clk(main_clk),
    .sample_clk(sample_clk),
    .reset(reset),
    .sel(sel),
    .freq(freq),
    .dout(dout)
  );

  // Clock generation
  always #0.0625 main_clk = ~main_clk; // 50MhZ
  always #22.6757 sample_clk = ~sample_clk; // 44.1Khz

  // Stimulus
  initial begin
    $dumpfile("oscillator_tb.vcd");
	$dumpvars(0,oscillator_tb); 

    reset = 1;  // Apply reset
    main_clk = 0;
    sample_clk = 0;
    sel = 0;
    freq = 44100;  // Set the desired frequency

    #1000 reset = 0; // Release reset

    // Change waveform selection every 100 time units
    #10000 sel = 1;
    #10000 sel = 2;
    #10000 sel = 3;

    // Stop simulation after 100 time units
    #10000 $finish;
  end

endmodule
