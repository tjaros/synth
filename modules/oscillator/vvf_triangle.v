module wvf_triangle #(
    parameter COUNTER_WIDTH = 24,
    parameter OUTPUT_WIDTH = 12
) (
    input [COUNTER_WIDTH-1:0] counter,
    output wire [OUTPUT_WIDTH-1:0] dout
);
    assign dout = (counter[COUNTER_WIDTH-1 -: OUTPUT_WIDTH] < 2**(OUTPUT_WIDTH-1)) ? counter[COUNTER_WIDTH-1 -: OUTPUT_WIDTH] : 2**(OUTPUT_WIDTH) - counter[COUNTER_WIDTH-1 -: OUTPUT_WIDTH];
       
endmodule