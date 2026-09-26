module fp_add #(
    parameter int WIDTH = 64
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,

    output logic [WIDTH-1:0] result
);

    // ============================================================
    // IEEE-754 PARAMETERS
    // ============================================================

    localparam int EXP_WIDTH =
        (WIDTH == 16) ? 5 :
        (WIDTH == 32) ? 8 :
        (WIDTH == 64) ? 11 : 0;

    localparam int FRAC_WIDTH =
        WIDTH - EXP_WIDTH - 1;

    localparam int SIG_WIDTH =
        FRAC_WIDTH + 1;

    // Three extra bits:
    // Guard, Round, Sticky
    localparam int EXT_WIDTH =
        SIG_WIDTH + 3;


    // Quiet NaN
    localparam logic [WIDTH-1:0] QNAN = {
        1'b0,
        {EXP_WIDTH{1'b1}},
        1'b1,
        {(FRAC_WIDTH-2){1'b0}},
        1'b1
    };


    // ============================================================
    // UNPACKED FIELDS
    // ============================================================

    logic sign_a;
    logic sign_b;

    logic [EXP_WIDTH-1:0] exp_a;
    logic [EXP_WIDTH-1:0] exp_b;

    logic [FRAC_WIDTH-1:0] frac_a;
    logic [FRAC_WIDTH-1:0] frac_b;

    logic [SIG_WIDTH-1:0] sig_a;
    logic [SIG_WIDTH-1:0] sig_b;


    // ============================================================
    // CLASSIFICATION
    // ============================================================

    logic a_zero;
    logic a_subnormal;
    logic a_infinity;
    logic a_nan;

    logic b_zero;
    logic b_subnormal;
    logic b_infinity;
    logic b_nan;


    // ============================================================
    // EXTENDED SIGNIFICANDS
    // ============================================================

    logic [EXT_WIDTH-1:0] sig_large_ext;
    logic [EXT_WIDTH-1:0] sig_small_ext;

    logic [EXT_WIDTH-1:0] sig_small_shifted;

    logic [EXT_WIDTH:0] arithmetic_result;


    // ============================================================
    // RESULT
    // ============================================================

    logic result_sign;

    logic [EXP_WIDTH-1:0] result_exp;

    logic [SIG_WIDTH-1:0] result_sig;


    // ============================================================
    // TEMPORARY VARIABLES
    // ============================================================

    integer i;

    logic sticky_bit;

    logic guard_bit;
    logic round_bit;

    logic round_increment;

    logic [SIG_WIDTH:0] rounded_sig;


    // ============================================================
    // UNPACK
    // ============================================================

    always_comb begin

        sign_a = a[WIDTH-1];
        sign_b = b[WIDTH-1];

        exp_a = a[WIDTH-2 -: EXP_WIDTH];
        exp_b = b[WIDTH-2 -: EXP_WIDTH];

        frac_a = a[FRAC_WIDTH-1:0];
        frac_b = b[FRAC_WIDTH-1:0];


        // Hidden bit

        if (exp_a == 0)
            sig_a = {1'b0, frac_a};
        else
            sig_a = {1'b1, frac_a};


        if (exp_b == 0)
            sig_b = {1'b0, frac_b};
        else
            sig_b = {1'b1, frac_b};

    end


    // ============================================================
    // CLASSIFICATION
    // ============================================================

    always_comb begin

        a_zero =
            (exp_a == 0) &&
            (frac_a == 0);

        a_subnormal =
            (exp_a == 0) &&
            (frac_a != 0);

        a_infinity =
            (&exp_a) &&
            (frac_a == 0);

        a_nan =
            (&exp_a) &&
            (frac_a != 0);


        b_zero =
            (exp_b == 0) &&
            (frac_b == 0);

        b_subnormal =
            (exp_b == 0) &&
            (frac_b != 0);

        b_infinity =
            (&exp_b) &&
            (frac_b == 0);

        b_nan =
            (&exp_b) &&
            (frac_b != 0);

    end


    // ============================================================
    // MAIN ARITHMETIC
    // ============================================================

    always_comb begin

        // --------------------------------------------------------
        // Defaults
        // --------------------------------------------------------

        result = '0;

        sig_large_ext = '0;
        sig_small_ext = '0;
        sig_small_shifted = '0;

        arithmetic_result = '0;

        result_sign = 1'b0;
        result_exp = '0;
        result_sig = '0;

        sticky_bit = 1'b0;

        guard_bit = 1'b0;
        round_bit = 1'b0;

        round_increment = 1'b0;

        rounded_sig = '0;


        // ========================================================
        // SPECIAL VALUES
        // ========================================================

        // --------------------------------------------------------
        // NaN
        // --------------------------------------------------------

        if (a_nan || b_nan) begin

            result = QNAN;

        end


        // --------------------------------------------------------
        // Infinity + Infinity
        // --------------------------------------------------------

        else if (a_infinity && b_infinity) begin

            if (sign_a == sign_b) begin

                result = {
                    sign_a,
                    {EXP_WIDTH{1'b1}},
                    {FRAC_WIDTH{1'b0}}
                };

            end
            else begin

                result = QNAN;

            end

        end


        // --------------------------------------------------------
        // A = Infinity
        // --------------------------------------------------------

        else if (a_infinity) begin

            result = {
                sign_a,
                {EXP_WIDTH{1'b1}},
                {FRAC_WIDTH{1'b0}}
            };

        end


        // --------------------------------------------------------
        // B = Infinity
        // --------------------------------------------------------

        else if (b_infinity) begin

            result = {
                sign_b,
                {EXP_WIDTH{1'b1}},
                {FRAC_WIDTH{1'b0}}
            };

        end


        // ========================================================
        // ZERO CASES
        // ========================================================

        else if (a_zero && b_zero) begin

            result = {
                sign_a & sign_b,
                {EXP_WIDTH{1'b0}},
                {FRAC_WIDTH{1'b0}}
            };

        end


        else if (a_zero) begin

            result = b;

        end


        else if (b_zero) begin

            result = a;

        end


        // ========================================================
        // FINITE ARITHMETIC
        // ========================================================

        else begin

            // ----------------------------------------------------
            // Select larger operand
            // ----------------------------------------------------

            logic [SIG_WIDTH-1:0] sig_large;
            logic [SIG_WIDTH-1:0] sig_small;

            logic [EXP_WIDTH-1:0] exp_large;
            logic [EXP_WIDTH-1:0] exp_small;

            logic sign_large;
            logic sign_small;

            logic [EXP_WIDTH-1:0] exp_diff;


            if (exp_a > exp_b) begin

                sig_large = sig_a;
                sig_small = sig_b;

                exp_large = exp_a;
                exp_small = exp_b;

                sign_large = sign_a;
                sign_small = sign_b;

            end

            else if (exp_b > exp_a) begin

                sig_large = sig_b;
                sig_small = sig_a;

                exp_large = exp_b;
                exp_small = exp_a;

                sign_large = sign_b;
                sign_small = sign_a;

            end

            else begin

                if (sig_a >= sig_b) begin

                    sig_large = sig_a;
                    sig_small = sig_b;

                    exp_large = exp_a;
                    exp_small = exp_b;

                    sign_large = sign_a;
                    sign_small = sign_b;

                end

                else begin

                    sig_large = sig_b;
                    sig_small = sig_a;

                    exp_large = exp_b;
                    exp_small = exp_a;

                    sign_large = sign_b;
                    sign_small = sign_a;

                end

            end


            // ----------------------------------------------------
            // Exponent difference
            // ----------------------------------------------------

            exp_diff = exp_large - exp_small;


            // ----------------------------------------------------
            // Extend significands
            //
            // [SIG_WIDTH+2 : 3] = actual significand
            // [2]              = guard
            // [1]              = round
            // [0]              = sticky
            // ----------------------------------------------------

            sig_large_ext = {
                sig_large,
                3'b000
            };

            sig_small_ext = {
                sig_small,
                3'b000
            };


            // ----------------------------------------------------
            // Alignment with sticky-bit generation
            // ----------------------------------------------------

            if (exp_diff == 0) begin

                sig_small_shifted = sig_small_ext;

            end

            else if (exp_diff >= EXT_WIDTH) begin

                sig_small_shifted = '0;

                if (sig_small_ext != 0)
                    sig_small_shifted[0] = 1'b1;

            end

            else begin

                sig_small_shifted =
                    sig_small_ext >> exp_diff;


                // Anything shifted out contributes to sticky

                sticky_bit = 1'b0;

                for (i = 0; i < EXT_WIDTH; i = i + 1) begin

                    if (i < exp_diff) begin

                        if (sig_small_ext[i])
                            sticky_bit = 1'b1;

                    end

                end


                if (sticky_bit)
                    sig_small_shifted[0] = 1'b1;

            end


            // ====================================================
            // ADD / SUBTRACT
            // ====================================================

            if (sign_large == sign_small) begin

                arithmetic_result =
                    {1'b0, sig_large_ext} +
                    {1'b0, sig_small_shifted};

                result_sign = sign_large;

            end

            else begin

                arithmetic_result =
                    {1'b0, sig_large_ext} -
                    {1'b0, sig_small_shifted};

                result_sign = sign_large;

            end


            // ====================================================
            // EXACT CANCELLATION
            // ====================================================

            if (arithmetic_result == 0) begin

                result = '0;

            end

            else begin

                result_exp = exp_large;


                // ------------------------------------------------
                // Addition overflow:
                //
                // 1.x + 1.x = 10.x
                // ------------------------------------------------

                if (arithmetic_result[EXT_WIDTH]) begin

                    result_sig =
                        arithmetic_result[EXT_WIDTH:4];

                    result_exp =
                        exp_large + 1'b1;

                    // New G/R/S after right shift
                    guard_bit =
                        arithmetic_result[3];

                    round_bit =
                        arithmetic_result[2];

                    sticky_bit =
                        arithmetic_result[1] |
                        arithmetic_result[0];

                end

                else begin

                    result_sig =
                        arithmetic_result[EXT_WIDTH-1:3];


                    guard_bit =
                        arithmetic_result[2];

                    round_bit =
                        arithmetic_result[1];

                    sticky_bit =
                        arithmetic_result[0];


                    // ------------------------------------------------
                    // Normalize subtraction result
                    // ------------------------------------------------

                    for (
                        i = 0;
                        i < SIG_WIDTH;
                        i = i + 1
                    ) begin

                        if (
                            (result_sig[SIG_WIDTH-1] == 1'b0) &&
                            (result_exp > 0)
                        ) begin

                            result_sig =
                                result_sig << 1;

                            guard_bit =
                                round_bit;

                            round_bit =
                                sticky_bit;

                            sticky_bit =
                                1'b0;

                            result_exp =
                                result_exp - 1'b1;

                        end

                    end

                end


                // =================================================
                // ROUND TO NEAREST, TIES TO EVEN
                // =================================================

                round_increment =
                    guard_bit &&
                    (
                        round_bit ||
                        sticky_bit ||
                        result_sig[0]
                    );


                rounded_sig = {
                    1'b0,
                    result_sig
                };


                if (round_increment)
                    rounded_sig = rounded_sig + 1'b1;


                // ------------------------------------------------
                // Rounding overflow
                //
                // 1.111... + rounding
                // becomes
                // 10.000...
                // ------------------------------------------------

                if (rounded_sig[SIG_WIDTH]) begin

                    result_sig =
                        rounded_sig[SIG_WIDTH:1];

                    result_exp =
                        result_exp + 1'b1;

                end

                else begin

                    result_sig =
                        rounded_sig[SIG_WIDTH-1:0];

                end


                // =================================================
                // EXPONENT OVERFLOW
                // =================================================

                if (&result_exp) begin

                    result = {
                        result_sign,
                        {EXP_WIDTH{1'b1}},
                        {FRAC_WIDTH{1'b0}}
                    };

                end

                else begin

                    result = {
                        result_sign,
                        result_exp,
                        result_sig[FRAC_WIDTH-1:0]
                    };

                end

            end

        end

    end

endmodule