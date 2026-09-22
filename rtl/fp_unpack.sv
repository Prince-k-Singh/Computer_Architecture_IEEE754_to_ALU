module fp_unpack #(
    parameter int WIDTH = 64,

    // IEEE-754 exponent width
    parameter int EXP_WIDTH =
        (WIDTH == 16) ? 5 :
        (WIDTH == 32) ? 8 :
        (WIDTH == 64) ? 11 : 0,

    // IEEE-754 fraction width
    parameter int FRAC_WIDTH = WIDTH - EXP_WIDTH - 1
)(
    input logic [WIDTH-1:0] in_data,

    output logic sign,
    output logic [EXP_WIDTH-1:0] exponent,
    output logic [FRAC_WIDTH-1:0] fraction,
    output logic [FRAC_WIDTH:0] significand,

    output logic is_zero,
    output logic is_subnormal,
    output logic is_normal,
    output logic is_infinity,
    output logic is_nan
);

    // ------------------------------------------------------------
    // IEEE-754 exponent values
    // ------------------------------------------------------------

    localparam logic [EXP_WIDTH-1:0] EXP_ZERO =
        {EXP_WIDTH{1'b0}};

    localparam logic [EXP_WIDTH-1:0] EXP_MAX =
        {EXP_WIDTH{1'b1}};

    // ------------------------------------------------------------
    // Extract fields
    // ------------------------------------------------------------

    assign sign = in_data[WIDTH-1];

    assign exponent =
        in_data[WIDTH-2 -: EXP_WIDTH];

    assign fraction =
        in_data[FRAC_WIDTH-1:0];

    // ------------------------------------------------------------
    // Number classification
    // ------------------------------------------------------------

    assign is_zero =
        (exponent == EXP_ZERO) &&
        (fraction == 0);

    assign is_subnormal =
        (exponent == EXP_ZERO) &&
        (fraction != 0);

    assign is_infinity =
        (exponent == EXP_MAX) &&
        (fraction == 0);

    assign is_nan =
        (exponent == EXP_MAX) &&
        (fraction != 0);

    assign is_normal =
        !is_zero &&
        !is_subnormal &&
        !is_infinity &&
        !is_nan;

    // ------------------------------------------------------------
    // Significand
    //
    // Normal number:
    //      1.fraction
    //
    // Subnormal/zero:
    //      0.fraction
    // ------------------------------------------------------------

    always_comb begin

        if (is_normal)
            significand = {1'b1, fraction};
        else
            significand = {1'b0, fraction};

    end

endmodule