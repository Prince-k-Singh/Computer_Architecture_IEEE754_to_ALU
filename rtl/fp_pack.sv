module fp_pack #(
    parameter int WIDTH = 64
)(
    input logic sign,

    input logic [
        ((WIDTH == 16) ? 5 : (WIDTH == 32) ? 8 : 11)-1:0
    ] exponent,

    input logic [
        (WIDTH - ((WIDTH == 16) ? 5 : (WIDTH == 32) ? 8 : 11) - 1)-1:0
    ] fraction,

    input logic is_zero,
    input logic is_infinity,
    input logic is_nan,

    output logic [WIDTH-1:0] out_data
);

    // ------------------------------------------------------------
    // IEEE-754 parameters
    // ------------------------------------------------------------

    localparam int EXP_WIDTH =
        (WIDTH == 16) ? 5 :
        (WIDTH == 32) ? 8 :
        (WIDTH == 64) ? 11 : 0;

    localparam int FRAC_WIDTH =
        WIDTH - EXP_WIDTH - 1;

    // ------------------------------------------------------------
    // Special exponent
    // ------------------------------------------------------------

    localparam logic [EXP_WIDTH-1:0] EXP_ZERO =
        {EXP_WIDTH{1'b0}};

    localparam logic [EXP_WIDTH-1:0] EXP_MAX =
        {EXP_WIDTH{1'b1}};

    // ------------------------------------------------------------
    // Packing
    // ------------------------------------------------------------

    always_comb begin

        // Default: normal number
        out_data = {
            sign,
            exponent,
            fraction
        };

        // Zero
        if (is_zero) begin

            out_data = {
                sign,
                EXP_ZERO,
                {FRAC_WIDTH{1'b0}}
            };

        end

        // Infinity
        else if (is_infinity) begin

            out_data = {
                sign,
                EXP_MAX,
                {FRAC_WIDTH{1'b0}}
            };

        end

        // NaN
        else if (is_nan) begin

            out_data = {
                1'b0,
                EXP_MAX,
                {{(FRAC_WIDTH-1){1'b0}}, 1'b1}
            };

        end

    end

endmodule