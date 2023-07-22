module biquad_filter #(
    parameter INOUT_WIDTH = 12,
    parameter INOUT_DECIMAL_WIDTH = 11,
    parameter COEF_WIDTH = 24,
    parameter COEF_DECIMAL_WIDTH = 23,
    parameter INTERNAL_WIDTH = 24,
    parameter INTERNAL_DECIMAL_WIDTH = 23,
    // Coefficients
    parameter signed b0 = 0,
    parameter signed b1 = 0,
    parameter signed b2 = 0,
    parameter signed a1 = 0,
    parameter signed a2 = 0
) (
    input clk,
    input reset, 

    input  [INOUT_WIDTH-1:0] din,
    output [INOUT_WIDTH-1:0] dout
);

    localparam INOUT_INTEGER_WIDTH = INOUT_WIDTH - INOUT_DECIMAL_WIDTH;
    localparam COEF_INTEGER_WIDTH = COEF_WIDTH - COEF_DECIMAL_WIDTH;
    localparam INTERNAL_INTEGER_WIDTH = INTERNAL_WIDTH - INTERNAL_DECIMAL_WIDTH;

    wire signed [INTERNAL_WIDTH-1:0] x_n_int;
    wire signed [INTERNAL_WIDTH-1:0] b0_int;
    wire signed [INTERNAL_WIDTH-1:0] b1_int;
    wire signed [INTERNAL_WIDTH-1:0] b2_int;
    wire signed [INTERNAL_WIDTH-1:0] a1_int;
    wire signed [INTERNAL_WIDTH-1:0] a2_int;
    wire signed [INTERNAL_WIDTH-1:0] y_n_int;

    // Previous values regs
    reg signed [INTERNAL_WIDTH-1:0] x_n1;
    reg signed [INTERNAL_WIDTH-1:0] x_n2;
    reg signed [INTERNAL_WIDTH-1:0] y_n1;
    reg signed [INTERNAL_WIDTH-1:0] y_n2;

    // Product values regs
    reg signed [INTERNAL_WIDTH+INTERNAL_WIDTH-1:0] product_b0; // x_{n}*b0
    reg signed [INTERNAL_WIDTH+INTERNAL_WIDTH-1:0] product_b1; // x_{n-1}*b1  
    reg signed [INTERNAL_WIDTH+INTERNAL_WIDTH-1:0] product_b2; // x_{n-2}*b2
    reg signed [INTERNAL_WIDTH+INTERNAL_WIDTH-1:0] product_a1; // y_{n-1}*a1
    reg signed [INTERNAL_WIDTH+INTERNAL_WIDTH-1:0] product_a2; // y_{n-2}*a2
    wire signed [INTERNAL_WIDTH+INTERNAL_WIDTH-1:0] y_n_add;   // sum(product_*)

    // Resize
    assign x_n_int = { {(INTERNAL_INTEGER_WIDTH-INOUT_INTEGER_WIDTH){din[INOUT_WIDTH-1]}}, din, {(INTERNAL_DECIMAL_WIDTH-INOUT_DECIMAL_WIDTH){1'b0}} };
    assign b0_int  = { {(INTERNAL_INTEGER_WIDTH-COEF_INTEGER_WIDTH){b0[COEF_WIDTH-1]}}, b0, {(INTERNAL_DECIMAL_WIDTH-COEF_DECIMAL_WIDTH){1'b0}} };
    assign b1_int  = { {(INTERNAL_INTEGER_WIDTH-COEF_INTEGER_WIDTH){b1[COEF_WIDTH-1]}}, b1, {(INTERNAL_DECIMAL_WIDTH-COEF_DECIMAL_WIDTH){1'b0}} };
    assign b2_int  = { {(INTERNAL_INTEGER_WIDTH-COEF_INTEGER_WIDTH){b2[COEF_WIDTH-1]}}, b2, {(INTERNAL_DECIMAL_WIDTH-COEF_DECIMAL_WIDTH){1'b0}} };
    assign a1_int  = { {(INTERNAL_INTEGER_WIDTH-COEF_INTEGER_WIDTH){a1[COEF_WIDTH-1]}}, a1, {(INTERNAL_DECIMAL_WIDTH-COEF_DECIMAL_WIDTH){1'b0}} };
    assign a2_int  = { {(INTERNAL_INTEGER_WIDTH-COEF_INTEGER_WIDTH){a2[COEF_WIDTH-1]}}, a2, {(INTERNAL_DECIMAL_WIDTH-COEF_DECIMAL_WIDTH){1'b0}} };

    // Saving previous values
    always @(posedge clk) begin
        if (reset) begin
            x_n1 <= 0;
            x_n2 <= 0;
            y_n1 <= 0;
            y_n2 <= 0;
        end else begin
            x_n2 <= x_n1;
            x_n1 <= x_n_int;
            y_n2 <= y_n1;
            y_n1 <= y_n_int;
        end
    end

    //Computing multiplications
    always @(posedge clk) begin
        if (reset) begin
            product_b0 <= 0;
            product_b1 <= 0;
            product_b2 <= 0;
            product_a1 <= 0;
            product_a2 <= 0;
        end else begin
            product_b0 <= b0 * x_n_int;
            product_b1 <= b1 * x_n1;
            product_b2 <= b2 * x_n2;
            product_a1 <= a1 * y_n1;
            product_a2 <= a2 * y_n2;
        end
    end
    // Add the biquad formula, though it still has 2*INTERNAL_SIZE bits because of multiplication
    assign y_n_add = product_b0 + product_b1 + product_b2 + product_a1 + product_a2;
    // Truncate to internal size
    assign y_n_int = y_n_add >>> (INTERNAL_DECIMAL_WIDTH);
    // Lastly put INOUT_WIDTH bits on output
    assign dout = y_n_int >>> (INTERNAL_DECIMAL_WIDTH-INOUT_DECIMAL_WIDTH)    ;
endmodule