module fp_mul #(
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

    localparam int PRODUCT_WIDTH =
        2 * SIG_WIDTH;

    localparam int BIAS =
        (WIDTH == 16) ? 15 :
        (WIDTH == 32) ? 127 :
        (WIDTH == 64) ? 1023 : 0;

    localparam int MAX_EXP_FIELD =
        (1 << EXP_WIDTH) - 1;

    localparam int MIN_NORMAL_EXP =
        1 - BIAS;


    // ============================================================
    // QUIET NaN
    //
    // FP64:
    // 0 11111111111 1 000000000000000000000000000000000000000000000000001
    //
    // = 7FF8000000000001
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
    // PRODUCT
    // ============================================================

    logic [PRODUCT_WIDTH-1:0] product;


    // ============================================================
    // INTERMEDIATE VALUES
    // ============================================================

    integer signed exp_a_unbiased;
    integer signed exp_b_unbiased;
    integer signed exp_result_unbiased;

    integer shift_amount;

    logic [SIG_WIDTH-1:0] sig_main;

    logic guard_bit;
    logic round_bit;
    logic sticky_bit;

    logic round_up;

    logic [SIG_WIDTH:0] rounded_ext;

    logic [SIG_WIDTH-1:0] sig_rounded;

    logic [SIG_WIDTH+2:0] sig_ext;
    logic [SIG_WIDTH+2:0] subnormal_ext;

    logic sub_sticky;

    // IMPORTANT:
    // Explicitly sized result exponent.
    // This prevents the integer exponent from making
    // the final concatenation wider than WIDTH.
    logic [EXP_WIDTH-1:0] result_exp_field;

    logic result_sign;

    integer i;


    // ============================================================
    // MAIN COMBINATIONAL LOGIC
    // ============================================================

    always_comb begin

        // --------------------------------------------------------
        // DEFAULTS
        // --------------------------------------------------------

        result = '0;

        sign_a = a[WIDTH-1];
        sign_b = b[WIDTH-1];

        exp_a = a[WIDTH-2 -: EXP_WIDTH];
        exp_b = b[WIDTH-2 -: EXP_WIDTH];

        frac_a = a[FRAC_WIDTH-1:0];
        frac_b = b[FRAC_WIDTH-1:0];


        // --------------------------------------------------------
        // CLASSIFICATION
        // --------------------------------------------------------

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


        // --------------------------------------------------------
        // RAW SIGNIFICANDS
        //
        // Normal:
        //      1.fraction
        //
        // Subnormal:
        //      0.fraction
        // --------------------------------------------------------

        if (exp_a == 0)
            sig_a_raw = {1'b0, frac_a};
        else
            sig_a_raw = {1'b1, frac_a};

        if (exp_b == 0)
            sig_b_raw = {1'b0, frac_b};
        else
            sig_b_raw = {1'b1, frac_b};


        // --------------------------------------------------------
        // INITIALIZE NORMALIZED SIGNIFICANDS
        // --------------------------------------------------------

        sig_a_norm = sig_a_raw;
        sig_b_norm = sig_b_raw;


        // --------------------------------------------------------
        // UNBIASED EXPONENTS
        // --------------------------------------------------------

        if (exp_a == 0)
            exp_a_unbiased = MIN_NORMAL_EXP;
        else
            exp_a_unbiased = exp_a - BIAS;

        if (exp_b == 0)
            exp_b_unbiased = MIN_NORMAL_EXP;
        else
            exp_b_unbiased = exp_b - BIAS;


        // --------------------------------------------------------
        // NORMALIZE SUBNORMAL A
        // --------------------------------------------------------

        if (a_subnormal) begin

            for (i = 0; i < SIG_WIDTH; i = i + 1) begin

                if (sig_a_norm[SIG_WIDTH-1] == 1'b0) begin

                    sig_a_norm =
                        sig_a_norm << 1;

                    exp_a_unbiased =
                        exp_a_unbiased - 1;

                end

            end

        end


        // --------------------------------------------------------
        // NORMALIZE SUBNORMAL B
        // --------------------------------------------------------

        if (b_subnormal) begin

            for (i = 0; i < SIG_WIDTH; i = i + 1) begin

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
        //
        // NaN × anything = NaN
        // --------------------------------------------------------

        if (a_nan || b_nan) begin

            result = QNAN;

        end


        // --------------------------------------------------------
        // Infinity × Zero = NaN
        // --------------------------------------------------------

        else if (
            (a_infinity && b_zero) ||
            (b_infinity && a_zero)
        ) begin

            result = QNAN;

        end


        // --------------------------------------------------------
        // Infinity
        //
        // Inf × finite non-zero = Inf
        // --------------------------------------------------------

        else if (a_infinity || b_infinity) begin

            result = {
                sign_a ^ sign_b,
                {EXP_WIDTH{1'b1}},
                {FRAC_WIDTH{1'b0}}
            };

        end


        // --------------------------------------------------------
        // Zero
        //
        // 0 × finite = 0
        // --------------------------------------------------------

        else if (a_zero || b_zero) begin

            result = {
                sign_a ^ sign_b,
                {EXP_WIDTH{1'b0}},
                {FRAC_WIDTH{1'b0}}
            };

        end


        // ========================================================
        // NORMAL MULTIPLICATION
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
            // Eresult = Ea + Eb
            // ----------------------------------------------------

            exp_result_unbiased =
                exp_a_unbiased +
                exp_b_unbiased;


            // ----------------------------------------------------
            // SIGNIFICAND MULTIPLICATION
            //
            // Example FP64:
            //
            // 53 bits × 53 bits = 106 bits
            // ----------------------------------------------------

            product =
                sig_a_norm *
                sig_b_norm;


            // ====================================================
            // NORMALIZE PRODUCT
            // ====================================================

            if (product[PRODUCT_WIDTH-1]) begin

                // ------------------------------------------------
                // Product is in [2,4)
                //
                // Shift right by one and increment exponent.
                // ------------------------------------------------

                sig_main =
                    product[PRODUCT_WIDTH-1 -: SIG_WIDTH];

                guard_bit =
                    product[PRODUCT_WIDTH-SIG_WIDTH-1];

                round_bit =
                    product[PRODUCT_WIDTH-SIG_WIDTH-2];

                sticky_bit =
                    |product[
                        PRODUCT_WIDTH-SIG_WIDTH-3:0
                    ];

                exp_result_unbiased =
                    exp_result_unbiased + 1;

            end

            else begin

                // ------------------------------------------------
                // Product is in [1,2)
                // ------------------------------------------------

                sig_main =
                    product[PRODUCT_WIDTH-2 -: SIG_WIDTH];

                guard_bit =
                    product[PRODUCT_WIDTH-SIG_WIDTH-2];

                round_bit =
                    product[PRODUCT_WIDTH-SIG_WIDTH-3];

                sticky_bit =
                    |product[
                        PRODUCT_WIDTH-SIG_WIDTH-4:0
                    ];

            end


            // ====================================================
            // CREATE EXTENDED SIGNIFICAND
            //
            // [ SIGNIFICAND | GUARD | ROUND | STICKY ]
            //
            // Used for round-to-nearest-even.
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


                subnormal_ext = '0;


                // ------------------------------------------------
                // Result is too small to retain any significant
                // bits.
                // ------------------------------------------------

                if (shift_amount >= SIG_WIDTH + 3) begin

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
                    // Shift significand into subnormal range
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
                // Rounding crossed into minimum normal number
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
                //
                // Round up when:
                //
                // G = 1 AND
                // (
                //      R = 1
                //      OR S = 1
                //      OR LSB = 1
                // )
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
                // Example:
                //
                // 1.111... + rounding
                //        ↓
                // 10.000...
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
                    // FIX:
                    //
                    // Explicitly convert integer exponent into
                    // exactly EXP_WIDTH bits before concatenation.
                    //
                    // This prevents the 32-bit integer from making
                    // the concatenation wider than WIDTH.
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