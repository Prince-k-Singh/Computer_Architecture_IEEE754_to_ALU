module fp_div #(
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

    localparam int BIAS =
        (WIDTH == 16) ? 15 :
        (WIDTH == 32) ? 127 :
        (WIDTH == 64) ? 1023 : 0;

    localparam int MAX_EXP_FIELD =
        (1 << EXP_WIDTH) - 1;

    localparam int MIN_NORMAL_EXP =
        1 - BIAS;


    // ============================================================
    // INTERNAL WIDTHS
    //
    // We calculate:
    //
    //       A significand
    // -----------------------
    //       B significand
    //
    // with extra bits for rounding.
    //
    // For FP64:
    //
    // SIG_WIDTH = 53
    // QUOT_WIDTH = 57
    // ============================================================

    localparam int QUOT_WIDTH =
        SIG_WIDTH + 4;

    localparam int NUM_WIDTH =
        SIG_WIDTH + QUOT_WIDTH;


    // ============================================================
    // QUIET NaN
    // ============================================================

    localparam logic [WIDTH-1:0] QNAN = {
        1'b0,
        {EXP_WIDTH{1'b1}},
        1'b1,
        {(FRAC_WIDTH-2){1'b0}},
        1'b1
    };


    // ============================================================
    // INPUT FIELDS
    // ============================================================

    logic sign_a;
    logic sign_b;

    logic [EXP_WIDTH-1:0] exp_a;
    logic [EXP_WIDTH-1:0] exp_b;

    logic [FRAC_WIDTH-1:0] frac_a;
    logic [FRAC_WIDTH-1:0] frac_b;


    // ============================================================
    // CLASSIFICATION
    // ============================================================

    logic a_zero;
    logic b_zero;

    logic a_subnormal;
    logic b_subnormal;

    logic a_infinity;
    logic b_infinity;

    logic a_nan;
    logic b_nan;


    // ============================================================
    // SIGNIFICANDS
    // ============================================================

    logic [SIG_WIDTH-1:0] sig_a_raw;
    logic [SIG_WIDTH-1:0] sig_b_raw;

    logic [SIG_WIDTH-1:0] sig_a_norm;
    logic [SIG_WIDTH-1:0] sig_b_norm;


    // ============================================================
    // EXPONENTS
    // ============================================================

    integer signed exp_a_unbiased;
    integer signed exp_b_unbiased;
    integer signed exp_result_unbiased;


    // ============================================================
    // DIVISION
    // ============================================================

    logic [NUM_WIDTH-1:0] numerator;

    logic [NUM_WIDTH-1:0] quotient_full;

    logic [NUM_WIDTH-1:0] remainder_full;

    logic [QUOT_WIDTH-1:0] quotient;


    // ============================================================
    // NORMALIZED QUOTIENT
    // ============================================================

    logic [QUOT_WIDTH-1:0] quotient_norm;


    // ============================================================
    // ROUNDING BITS
    // ============================================================

    logic [SIG_WIDTH-1:0] sig_main;

    logic guard_bit;
    logic round_bit;
    logic sticky_bit;

    logic round_up;


    // ============================================================
    // ROUNDED RESULT
    // ============================================================

    logic [SIG_WIDTH:0] rounded_ext;

    logic [SIG_WIDTH-1:0] sig_rounded;

    logic [EXP_WIDTH-1:0] result_exp_field;

    logic result_sign;


    // ============================================================
    // SUBNORMAL RESULT
    // ============================================================

    logic [SIG_WIDTH+2:0] sig_ext;

    logic [SIG_WIDTH+2:0] subnormal_ext;

    logic sub_sticky;

    integer shift_amount;


    // ============================================================
    // LOOP VARIABLE
    // ============================================================

    integer i;


    // ============================================================
    // MAIN COMBINATIONAL LOGIC
    // ============================================================

    always_comb begin

        // ========================================================
        // DEFAULT VALUES
        // ========================================================

        result = '0;

        numerator = '0;

        quotient_full = '0;
        remainder_full = '0;

        quotient = '0;
        quotient_norm = '0;

        sig_ext = '0;
        subnormal_ext = '0;

        sig_main = '0;
        sig_rounded = '0;

        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky_bit = 1'b0;

        round_up = 1'b0;

        result_exp_field = '0;

        result_sign = 1'b0;

        shift_amount = 0;

        sub_sticky = 1'b0;


        // ========================================================
        // EXTRACT IEEE-754 FIELDS
        // ========================================================

        sign_a = a[WIDTH-1];
        sign_b = b[WIDTH-1];

        exp_a = a[WIDTH-2 -: EXP_WIDTH];
        exp_b = b[WIDTH-2 -: EXP_WIDTH];

        frac_a = a[FRAC_WIDTH-1:0];
        frac_b = b[FRAC_WIDTH-1:0];


        // ========================================================
        // CLASSIFICATION
        // ========================================================

        a_zero =
            (exp_a == 0) &&
            (frac_a == 0);

        b_zero =
            (exp_b == 0) &&
            (frac_b == 0);

        a_subnormal =
            (exp_a == 0) &&
            (frac_a != 0);

        b_subnormal =
            (exp_b == 0) &&
            (frac_b != 0);

        a_infinity =
            (&exp_a) &&
            (frac_a == 0);

        b_infinity =
            (&exp_b) &&
            (frac_b == 0);

        a_nan =
            (&exp_a) &&
            (frac_a != 0);

        b_nan =
            (&exp_b) &&
            (frac_b != 0);


        // ========================================================
        // RAW SIGNIFICANDS
        // ========================================================

        if (exp_a == 0)
            sig_a_raw = {1'b0, frac_a};
        else
            sig_a_raw = {1'b1, frac_a};


        if (exp_b == 0)
            sig_b_raw = {1'b0, frac_b};
        else
            sig_b_raw = {1'b1, frac_b};


        sig_a_norm = sig_a_raw;
        sig_b_norm = sig_b_raw;


        // ========================================================
        // UNBIASED EXPONENTS
        // ========================================================

        if (exp_a == 0)
            exp_a_unbiased = MIN_NORMAL_EXP;
        else
            exp_a_unbiased = exp_a - BIAS;


        if (exp_b == 0)
            exp_b_unbiased = MIN_NORMAL_EXP;
        else
            exp_b_unbiased = exp_b - BIAS;


        // ========================================================
        // NORMALIZE SUBNORMAL A
        // ========================================================

        if (a_subnormal) begin

            for (
                i = 0;
                i < SIG_WIDTH;
                i = i + 1
            ) begin

                if (sig_a_norm[SIG_WIDTH-1] == 1'b0) begin

                    sig_a_norm =
                        sig_a_norm << 1;

                    exp_a_unbiased =
                        exp_a_unbiased - 1;

                end

            end

        end


        // ========================================================
        // NORMALIZE SUBNORMAL B
        // ========================================================

        if (b_subnormal) begin

            for (
                i = 0;
                i < SIG_WIDTH;
                i = i + 1
            ) begin

                if (sig_b_norm[SIG_WIDTH-1] == 1'b0) begin

                    sig_b_norm =
                        sig_b_norm << 1;

                    exp_b_unbiased =
                        exp_b_unbiased - 1;

                end

            end

        end


        // ========================================================
        // SPECIAL CASES
        // ========================================================

        // --------------------------------------------------------
        // NaN
        // --------------------------------------------------------

        if (a_nan || b_nan) begin

            result = QNAN;

        end


        // --------------------------------------------------------
        // Infinity / Infinity
        //
        // IEEE-754:
        //
        // Inf / Inf = NaN
        // --------------------------------------------------------

        else if (a_infinity && b_infinity) begin

            result = QNAN;

        end


        // --------------------------------------------------------
        // Zero / Zero
        //
        // IEEE-754:
        //
        // 0 / 0 = NaN
        // --------------------------------------------------------

        else if (a_zero && b_zero) begin

            result = QNAN;

        end


        // --------------------------------------------------------
        // Infinity / finite
        //
        // Inf / finite = Inf
        // --------------------------------------------------------

        else if (a_infinity) begin

            result = {
                sign_a ^ sign_b,
                {EXP_WIDTH{1'b1}},
                {FRAC_WIDTH{1'b0}}
            };

        end


        // --------------------------------------------------------
        // finite / Infinity
        //
        // finite / Inf = 0
        // --------------------------------------------------------

        else if (b_infinity) begin

            result = {
                sign_a ^ sign_b,
                {EXP_WIDTH{1'b0}},
                {FRAC_WIDTH{1'b0}}
            };

        end


        // --------------------------------------------------------
        // finite / Zero
        //
        // finite / 0 = Inf
        // --------------------------------------------------------

        else if (b_zero) begin

            result = {
                sign_a ^ sign_b,
                {EXP_WIDTH{1'b1}},
                {FRAC_WIDTH{1'b0}}
            };

        end


        // --------------------------------------------------------
        // Zero / finite
        //
        // 0 / finite = 0
        // --------------------------------------------------------

        else if (a_zero) begin

            result = {
                sign_a ^ sign_b,
                {EXP_WIDTH{1'b0}},
                {FRAC_WIDTH{1'b0}}
            };

        end


        // ========================================================
        // NORMAL DIVISION
        // ========================================================

        else begin

            // ----------------------------------------------------
            // RESULT SIGN
            // ----------------------------------------------------

            result_sign =
                sign_a ^ sign_b;


            // ----------------------------------------------------
            // RESULT EXPONENT
            //
            // Eresult = Ea - Eb
            // ----------------------------------------------------

            exp_result_unbiased =
                exp_a_unbiased -
                exp_b_unbiased;


            // ====================================================
            // SIGNIFICAND DIVISION
            //
            // We shift the numerator left to obtain extra bits:
            //
            //        Ma << (SIG_WIDTH + 3)
            //        --------------------
            //                 Mb
            //
            // This gives us:
            //
            // significand
            // guard
            // round
            // sticky
            // ====================================================

            numerator = {
                sig_a_norm,
                {(SIG_WIDTH+3){1'b0}}
            };


            quotient_full =
                numerator /
                sig_b_norm;


            remainder_full =
                numerator %
                sig_b_norm;


            quotient =
                quotient_full[QUOT_WIDTH-1:0];


            // ====================================================
            // NORMALIZE QUOTIENT
            //
            // For:
            //
            // 1 <= Ma/Mb < 2
            //
            // quotient[56] is the leading 1 for FP64.
            //
            // If quotient[56] = 0, the quotient is below 1,
            // so shift left and decrease exponent.
            // ====================================================

            if (quotient[QUOT_WIDTH-1]) begin

                quotient_norm =
                    quotient;

            end

            else begin

                quotient_norm =
                    quotient << 1;

                exp_result_unbiased =
                    exp_result_unbiased - 1;

            end


            // ====================================================
            // EXTRACT SIGNIFICAND + ROUNDING BITS
            // ====================================================

            sig_main =
                quotient_norm[
                    QUOT_WIDTH-1 -: SIG_WIDTH
                ];


            guard_bit =
                quotient_norm[3];


            round_bit =
                quotient_norm[2];


            // ----------------------------------------------------
            // Sticky bit:
            //
            // Any discarded quotient bit OR non-zero remainder
            // means information was lost.
            // ----------------------------------------------------

            sticky_bit =
                (|quotient_norm[1:0]) ||
                (remainder_full != 0);


            // ====================================================
            // EXTENDED SIGNIFICAND
            // ====================================================

            sig_ext = '0;

            sig_ext[SIG_WIDTH+2:3] =
                sig_main;

            sig_ext[2] =
                guard_bit;

            sig_ext[1] =
                round_bit;

            sig_ext[0] =
                sticky_bit;


            // ====================================================
            // UNDERFLOW / SUBNORMAL RESULT
            // ====================================================

            if (
                exp_result_unbiased <
                MIN_NORMAL_EXP
            ) begin

                shift_amount =
                    MIN_NORMAL_EXP -
                    exp_result_unbiased;


                // ------------------------------------------------
                // Result too small
                // ------------------------------------------------

                if (
                    shift_amount >=
                    SIG_WIDTH + 3
                ) begin

                    subnormal_ext = '0;

                    sub_sticky = 1'b0;

                    for (
                        i = 0;
                        i < SIG_WIDTH + 3;
                        i = i + 1
                    ) begin

                        sub_sticky =
                            sub_sticky |
                            sig_ext[i];

                    end

                    subnormal_ext[0] =
                        sub_sticky;

                end

                else begin

                    // --------------------------------------------
                    // Shift into subnormal range
                    // --------------------------------------------

                    subnormal_ext =
                        sig_ext >> shift_amount;


                    sub_sticky = 1'b0;

                    for (
                        i = 0;
                        i < shift_amount;
                        i = i + 1
                    ) begin

                        sub_sticky =
                            sub_sticky |
                            sig_ext[i];

                    end


                    subnormal_ext[0] =
                        subnormal_ext[0] |
                        sub_sticky;

                end


                // =================================================
                // ROUND TO NEAREST, TIES TO EVEN
                // =================================================

                round_up =
                    subnormal_ext[2] &&
                    (
                        subnormal_ext[1] ||
                        subnormal_ext[0] ||
                        subnormal_ext[3]
                    );


                rounded_ext =
                    {1'b0,
                     subnormal_ext[SIG_WIDTH+2:3]}
                    +
                    round_up;


                // ------------------------------------------------
                // Rounding crossed into minimum normal
                // ------------------------------------------------

                if (rounded_ext[SIG_WIDTH]) begin

                    result = {
                        result_sign,
                        {{(EXP_WIDTH-1){1'b0}}, 1'b1},
                        {FRAC_WIDTH{1'b0}}
                    };

                end

                else begin

                    result = {
                        result_sign,
                        {EXP_WIDTH{1'b0}},
                        rounded_ext[FRAC_WIDTH-1:0]
                    };

                end

            end


            // ====================================================
            // NORMAL RESULT
            // ====================================================

            else begin

                // =================================================
                // ROUND TO NEAREST, TIES TO EVEN
                // =================================================

                round_up =
                    guard_bit &&
                    (
                        round_bit ||
                        sticky_bit ||
                        sig_main[0]
                    );


                rounded_ext =
                    {1'b0, sig_main}
                    +
                    round_up;


                // ------------------------------------------------
                // Rounding overflow
                //
                // 1.111... → 10.000...
                // ------------------------------------------------

                if (rounded_ext[SIG_WIDTH]) begin

                    sig_rounded =
                        rounded_ext[SIG_WIDTH:1];

                    exp_result_unbiased =
                        exp_result_unbiased + 1;

                end

                else begin

                    sig_rounded =
                        rounded_ext[SIG_WIDTH-1:0];

                end


                // =================================================
                // EXPONENT OVERFLOW
                // =================================================

                if (
                    (exp_result_unbiased + BIAS)
                    >= MAX_EXP_FIELD
                ) begin

                    result = {
                        result_sign,
                        {EXP_WIDTH{1'b1}},
                        {FRAC_WIDTH{1'b0}}
                    };

                end

                else begin

                    // ------------------------------------------------
                    // Explicitly size exponent field.
                    // ------------------------------------------------

                    result_exp_field =
                        exp_result_unbiased + BIAS;


                    result = {
                        result_sign,
                        result_exp_field,
                        sig_rounded[FRAC_WIDTH-1:0]
                    };

                end

            end

        end

    end

endmodule