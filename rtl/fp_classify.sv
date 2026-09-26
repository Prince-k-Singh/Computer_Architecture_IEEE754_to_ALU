module fp_classify #(parameter int WIDTH=64)(
    input logic [WIDTH-1:0] in_data,
    output logic is_zero,
    output logic is_subnormal,
    output logic is_normal,
    output logic is_infinity,
    output logic is_nan
);

    // IEEE-754 parameters according to sizes

    localparam int EXP_WIDTH =
        (WIDTH == 16) ? 5 :
        (WIDTH == 32) ? 8 :
        (WIDTH == 64) ? 11 : 0;

    localparam int FRAC_WIDTH = WIDTH-EXP_WIDTH-1;

    // Extract fields

    logic [EXP_WIDTH-1:0] exponent;
    logic [FRAC_WIDTH-1:0] fraction;

    assign exponent = in_data[WIDTH-2 -: EXP_WIDTH];
    assign fraction = in_data[FRAC_WIDTH-1:0];

    // Special exponent values

    localparam logic [EXP_WIDTH-1:0] EXP_ZERO = {EXP_WIDTH{1'b0}};
    localparam logic [EXP_WIDTH-1:0] EXP_MAX = {EXP_WIDTH{1'b1}};

    // Classification

    assign is_zero = (exponent == EXP_ZERO) && (fraction == 0);
    assign is_subnormal = (exponent == EXP_ZERO) && (fraction != 0);
    assign is_infinity = (exponent == EXP_MAX) && (fraction == 0);
    assign is_nan = (exponent == EXP_MAX) && (fraction != 0);
    assign is_normal = !is_zero && !is_subnormal && !is_infinity && !is_nan;

endmodule