`timescale 1ns/1ns

module clock_divider_tb;
  
  // Signals
  reg clk_in;
  reg reset;
  wire clk_out;

  // Instantiate ClockDivider module
  clock_divider #(.DIVISOR(50_000_000/44_100))
    dut (
      .clk_in(clk_in),
		.reset(reset),
      .clk_out(clk_out)
    );
  
  always #10 clk_in=~clk_in; //now you create your cyclic clock

  // Stimulus
  initial begin
	 $dumpfile("clock_divider.vcd");
	 $dumpvars(0,clock_divider_tb); 
  
	 reset = 1;
	 clk_in = 0;
	 
	 #1000;
	 reset = 0;
	 #10000000;
	 $finish;
  end
  
endmodule
