module clock_divider #
  (
    parameter integer DIVISOR = 50_000_000/44_100	 // Divisor = Input Clock frequency in Hz / desired frequency in Hz
  )
  (
    input wire clk_in,
	 input wire reset,
    output reg clk_out
  );

reg [31:0] counter;

always @(posedge clk_in) begin
   if (reset) begin
	   counter <= 0;
		clk_out <= 0;
	end else begin 
		counter <= counter + 32'b1;
		if (counter >= (DIVISOR - 1))
			counter <= 32'b0;
		clk_out <= (counter < (DIVISOR/2))?1'b1:1'b0;
	end
end

endmodule
