module oscillator #(
    parameter COUNTER_WIDTH = 24,
    parameter OUTPUT_WIDTH = 12,
    parameter FREQ_BITS = 12
) (
    // Clocks
    input main_clk,
    input sample_clk,

    // Reset
    input reset,

    // Selector
    // 0 - square
    // 1 - saw
    // 2 - triangle
    input [1:0] sel,

    // Freq
    input [FREQ_BITS-1:0] freq,


    // Outputs
    output wire [OUTPUT_WIDTH-1:0] dout
);
    // Regs
    reg [COUNTER_WIDTH-1:0] counter;
    reg [OUTPUT_WIDTH-1:0]  dout_tmp;

    // Wires
    wire [OUTPUT_WIDTH-1:0] dout_triangle;
    wire [OUTPUT_WIDTH-1:0] dout_toothsaw;
    wire [OUTPUT_WIDTH-1:0] dout_square;


    // Instantiations
    wvf_triangle #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) m1 (
        .counter(counter),
        .dout(dout_triangle)
    );

    wvf_toothsaw #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) m2 (
        .counter(counter),
        .dout(dout_toothsaw)
    );

    wvf_square #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) m3 (
        .counter(counter),
        .dout(dout_square)
    );

    // Logic

    always @(posedge main_clk) begin
        if (reset) begin
            counter <= 0;
        end else begin
            counter <= counter + freq;
        end
    end

    
    always @(posedge sample_clk) begin
        case (sel)
            2'b00:   dout_tmp = dout_square;
            2'b01:   dout_tmp = dout_toothsaw;
            2'b11:   dout_tmp = dout_triangle;
            default: dout_tmp = 0;
        endcase
    end

    assign dout = dout_tmp;
    
endmodule
