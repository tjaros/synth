module synth
(
	input CLOCK_50,
	input [9:0] SW,
	input [3:0] KEY,
	
	// Audio stuff
	// I2C Audio/Video config interface
	output FPGA_I2C_SCLK,
	inout FPGA_I2C_SDAT,
	// Audio CODEC
	output AUD_XCK,
	input AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,
	input AUD_ADCDAT,
	output AUD_DACDAT
);

  ///////////////////////////////////////////////////////
  //
  // Oscillator module items
  //
  ///////////////////////////////////////////////////////
  parameter COUNTER_WIDTH = 24;
  parameter OUTPUT_WIDTH = 24;
  parameter FCW_WIDTH = 24;

  // Inputs
  wire main_clk;
  wire sample_clk;
  wire reset;
  reg [1:0] sel;
  reg [FCW_WIDTH-1:0] fcw;

  // Debounce
  reg [3:0] KEY_PREV;
  reg [9:0] SW_PREV;


  // Outputs
  wire [OUTPUT_WIDTH-1:0] oscillator_dout;
  wire [OUTPUT_WIDTH-1:0] filter_dout;
  
  ///////////////////////////////////////////////////
  //
  // Clock dividers
  //
  ///////////////////////////////////////////////////
  
  clock_divider #(.DIVISOR(50_000_000/192_000))
    dut1 (
      .clk_in(CLOCK_50),
		.reset(reset),
      .clk_out(main_clk)
    );
  clock_divider #(.DIVISOR(50_000_000/48_000))
    dut3 (
      .clk_in(CLOCK_50),
		.reset(reset),
      .clk_out(sample_clk)
    );

  // Instantiate the oscillator module
  oscillator #(
    .COUNTER_WIDTH(COUNTER_WIDTH),
    .OUTPUT_WIDTH(OUTPUT_WIDTH),
	 .FCW_WIDTH(FCW_WIDTH)
  ) dut2 (
    .main_clk(main_clk),
    .sample_clk(sample_clk),
    .reset(reset),
    .sel(sel),
    .fcw(fcw),
    .dout(oscillator_dout)
  );
  

    // Instantiate the biquad_filter module
    biquad_filter #(
        .INOUT_WIDTH(24),
        .INOUT_DECIMAL_WIDTH(0),
        .COEF_WIDTH(24),
        .COEF_DECIMAL_WIDTH(22),
        .INTERNAL_WIDTH(48),
        .INTERNAL_DECIMAL_WIDTH(22),
        .b0(24'h028387),
        .b1(24'h05070e),
        .b2(24'h028387),
        .a1(24'ha88d94),
        .a2(24'h218088)
    ) filter_inst (
        .clk(main_clk),
        .reset(reset),
        .din(oscillator_dout),
        .dout(filter_dout)
    );
  
  ///////////////////////////////////////////////////////
  //
  // Audio module items
  //
  ///////////////////////////////////////////////////////
  
  //Audio data
  //reg [23:0] dac_left, dac_right;
  reg [23:0] dac_mono;
  wire [23:0] adc_left, adc_right;
  wire advance;
  audio_driver ad (
      .CLOCK_50(CLOCK_50),   // 50MHz clock
      .reset(reset),         // Our reset
		.dac_left(dac_mono),   // Used only one to do mono
		.dac_right(dac_mono),          
		.adc_left(adc_left),   // Not used
		.adc_right(adc_right), // Not used
		.advance(advance), 
		.FPGA_I2C_SCLK(FPGA_I2C_SCLK), 
		.FPGA_I2C_SDAT(FPGA_I2C_SDAT), 
		.AUD_XCK(AUD_XCK), 
		.AUD_DACLRCK(AUD_DACLRCK), 
		.AUD_ADCLRCK(AUD_ADCLRCK), 
		.AUD_BCLK(AUD_BCLK), 
		.AUD_ADCDAT(AUD_ADCDAT), 
		.AUD_DACDAT(AUD_DACDAT)
	);
	
	always @(posedge main_clk) begin
	   if (reset) begin
		   dac_mono <= 0;
			 sel <= 2'd3;
          fcw <= 0;
	   end else begin
         KEY_PREV <= KEY;
       
		   if (advance) begin
			    dac_mono <= oscillator_dout;
			 end
       
       // Waveform select
			 if (KEY[0]==1'b0 && KEY_PREV[0]==1'b1) begin
				 sel <= sel + 2'd1;
			 end

       // Frequency select
       if (KEY[1]==1'b0 && KEY_PREV[1]==1'b1) begin
         fcw <= fcw + 2**(COUNTER_WIDTH-6);
       end 
		end 
	end 
  
  assign reset = SW[0];
endmodule
