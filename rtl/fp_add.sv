module fp_add #(
    parameter int WIDTH = 64
)(
    input  logic             clk,
    input  logic             rst,
    input  logic             start,

    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,

    output logic [WIDTH-1:0] result,
    output logic             busy,
    output logic             valid
);

    // ================================================================
    // IEEE-754 PARAMETERS
    // ================================================================

    localparam int EXP_WIDTH =
        (WIDTH == 16) ? 5  :
        (WIDTH == 32) ? 8  :
        (WIDTH == 64) ? 11 :
        0;

    localparam int FRAC_WIDTH = WIDTH - EXP_WIDTH - 1;

    // Fraction + hidden bit
    localparam int SIG_WIDTH = FRAC_WIDTH + 1;

    // 3 extra bits:
    // bit 2 = Guard
    // bit 1 = Round
    // bit 0 = Sticky
    localparam int EXT_WIDTH = SIG_WIDTH + 3;

    localparam logic [EXP_WIDTH-1:0] MAX_EXP =
        {EXP_WIDTH{1'b1}};

    // Canonical quiet NaN
    localparam logic [WIDTH-1:0] QNAN = {
        1'b0,
        {EXP_WIDTH{1'b1}},
        1'b1,
        {(FRAC_WIDTH-1){1'b0}}
    };


    // ================================================================
    // FUNCTION 1:
    // RIGHT SHIFT WITH STICKY BIT
    // ================================================================
    //
    // When bits are shifted out, OR them together into bit 0.
    //
    // This preserves information required for IEEE-754 rounding.
    //
    // ================================================================

    function automatic logic [EXT_WIDTH-1:0]
        shift_right_sticky(
            input logic [EXT_WIDTH-1:0] value,
            input integer shamt
        );

        logic [EXT_WIDTH-1:0] shifted;
        logic lost;

        integer i;

        begin

            shifted = '0;
            lost    = 1'b0;

            // No shift
            if (shamt <= 0) begin

                shifted = value;

            end

            // Everything shifted out
            else if (shamt >= EXT_WIDTH) begin

                shifted = '0;
                lost    = |value;

            end

            // Normal right shift
            else begin

                shifted = value >> shamt;

                for (i = 0; i < EXT_WIDTH; i = i + 1) begin

                    if (i < shamt)
                        lost = lost | value[i];

                end

            end

            // Sticky bit
            shifted[0] = shifted[0] | lost;

            shift_right_sticky = shifted;

        end

    endfunction


    // ================================================================
    // FUNCTION 2:
    // LEADING ZERO COUNT
    // ================================================================

    function automatic integer
        leading_zero_count(
            input logic [EXT_WIDTH-1:0] value
        );

        integer i;

        begin

            leading_zero_count = EXT_WIDTH;

            for (i = EXT_WIDTH-1; i >= 0; i = i - 1) begin

                if (
                    (leading_zero_count == EXT_WIDTH) &&
                    value[i]
                ) begin

                    leading_zero_count =
                        EXT_WIDTH - 1 - i;

                end

            end

        end

    endfunction


    // ================================================================
    // ====================== STAGE 1 ================================
    // ================================================================
    //
    // UNPACK
    // CLASSIFY
    // EFFECTIVE EXPONENT
    // SELECT LARGER OPERAND
    // ALIGN SMALLER SIGNIFICAND
    //
    // ================================================================

    logic s1_valid;
    logic s1_special;

    logic [WIDTH-1:0] s1_special_result;

    logic s1_sign_large;
    logic s1_sign_small;

    logic [EXP_WIDTH-1:0] s1_exp_large;

    logic [EXT_WIDTH-1:0] s1_sig_large_ext;
    logic [EXT_WIDTH-1:0] s1_sig_small_aligned;


    // ------------------------------------------------
    // Current input decoding
    // ------------------------------------------------

    logic sign_a;
    logic sign_b;

    logic [EXP_WIDTH-1:0] exp_a;
    logic [EXP_WIDTH-1:0] exp_b;

    logic [FRAC_WIDTH-1:0] frac_a;
    logic [FRAC_WIDTH-1:0] frac_b;

    logic [SIG_WIDTH-1:0] sig_a;
    logic [SIG_WIDTH-1:0] sig_b;


    // Classification

    logic a_zero;
    logic b_zero;

    logic a_inf;
    logic b_inf;

    logic a_nan;
    logic b_nan;


    // Effective exponent

    logic [EXP_WIDTH-1:0] eff_exp_a;
    logic [EXP_WIDTH-1:0] eff_exp_b;


    // Larger/smaller operand

    logic [SIG_WIDTH-1:0] sig_large;
    logic [SIG_WIDTH-1:0] sig_small;

    logic [EXP_WIDTH-1:0] exp_large;
    logic [EXP_WIDTH-1:0] exp_small;

    logic sign_large;
    logic sign_small;

    integer exp_diff;


    // ================================================================
    // ====================== STAGE 2 ================================
    // ================================================================
    //
    // ADD / SUBTRACT
    // NORMALIZATION
    //
    // ================================================================

    logic s2_valid;
    logic s2_special;

    logic [WIDTH-1:0] s2_special_result;

    logic s2_result_sign;

    logic [EXP_WIDTH:0] s2_exp_work;

    logic [EXT_WIDTH-1:0] s2_norm_sig_ext;


    // Stage 2 temporary values

    logic [EXT_WIDTH:0] arithmetic_ext;

    logic [EXT_WIDTH-1:0] norm_sig_next;

    logic [EXP_WIDTH:0] exp_next;

    logic result_sign_next;

    integer lz_count;
    integer left_shift;


    // ================================================================
    // ====================== STAGE 3 ================================
    // ================================================================
    //
    // ROUNDING
    // PACKING
    //
    // ================================================================

    logic [WIDTH-1:0] s3_result_next;


    // ================================================================
    // COMBINATIONAL LOGIC BETWEEN PIPELINE REGISTERS
    // ================================================================

    always_comb begin

        // ============================================================
        // STAGE 1 : UNPACK INPUT A
        // ============================================================

        sign_a = a[WIDTH-1];

        exp_a =
            a[WIDTH-2 -: EXP_WIDTH];

        frac_a =
            a[FRAC_WIDTH-1:0];


        // Hidden bit:
        //
        // Normal    = 1.fraction
        // Subnormal = 0.fraction

        sig_a =
            (exp_a == 0)
            ? {1'b0, frac_a}
            : {1'b1, frac_a};


        // ============================================================
        // STAGE 1 : UNPACK INPUT B
        // ============================================================

        sign_b = b[WIDTH-1];

        exp_b =
            b[WIDTH-2 -: EXP_WIDTH];

        frac_b =
            b[FRAC_WIDTH-1:0];


        sig_b =
            (exp_b == 0)
            ? {1'b0, frac_b}
            : {1'b1, frac_b};


        // ============================================================
        // CLASSIFICATION
        // ============================================================

        a_zero =
            (exp_a == 0) &&
            (frac_a == 0);

        b_zero =
            (exp_b == 0) &&
            (frac_b == 0);


        a_inf =
            (&exp_a) &&
            (frac_a == 0);

        b_inf =
            (&exp_b) &&
            (frac_b == 0);


        a_nan =
            (&exp_a) &&
            (frac_a != 0);

        b_nan =
            (&exp_b) &&
            (frac_b != 0);


        // ============================================================
        // EFFECTIVE EXPONENT
        // ============================================================
        //
        // Important:
        //
        // normal:
        //     exponent = exponent field
        //
        // subnormal:
        //     alignment exponent = 1
        //
        // This fixes the normal/subnormal boundary.
        //
        // ============================================================

        eff_exp_a =
            (exp_a == 0)
            ? {{(EXP_WIDTH-1){1'b0}},1'b1}
            : exp_a;

        eff_exp_b =
            (exp_b == 0)
            ? {{(EXP_WIDTH-1){1'b0}},1'b1}
            : exp_b;


        // ============================================================
        // DEFAULTS
        // ============================================================

        sig_large  = '0;
        sig_small  = '0;

        exp_large  = '0;
        exp_small  = '0;

        sign_large = 1'b0;
        sign_small = 1'b0;

        exp_diff = 0;


        // ============================================================
        // SELECT LARGER MAGNITUDE
        // ============================================================

        if (eff_exp_a > eff_exp_b) begin

            sig_large  = sig_a;
            sig_small  = sig_b;

            exp_large  = eff_exp_a;
            exp_small  = eff_exp_b;

            sign_large = sign_a;
            sign_small = sign_b;

        end

        else if (eff_exp_b > eff_exp_a) begin

            sig_large  = sig_b;
            sig_small  = sig_a;

            exp_large  = eff_exp_b;
            exp_small  = eff_exp_a;

            sign_large = sign_b;
            sign_small = sign_a;

        end

        else if (sig_a >= sig_b) begin

            sig_large  = sig_a;
            sig_small  = sig_b;

            exp_large  = eff_exp_a;
            exp_small  = eff_exp_b;

            sign_large = sign_a;
            sign_small = sign_b;

        end

        else begin

            sig_large  = sig_b;
            sig_small  = sig_a;

            exp_large  = eff_exp_b;
            exp_small  = eff_exp_a;

            sign_large = sign_b;
            sign_small = sign_a;

        end


        // ============================================================
        // EXPONENT DIFFERENCE
        // ============================================================

        exp_diff =
            exp_large - exp_small;


        // ============================================================
        // STAGE 2 DEFAULTS
        // ============================================================

        arithmetic_ext = '0;

        norm_sig_next = '0;

        exp_next =
            {1'b0, s1_exp_large};

        result_sign_next =
            s1_sign_large;

        lz_count = 0;
        left_shift = 0;


        // ============================================================
        // SAME SIGN -> ADD
        // ============================================================

        if (s1_sign_large == s1_sign_small) begin

            arithmetic_ext =
                {1'b0, s1_sig_large_ext} +
                {1'b0, s1_sig_small_aligned};


            // --------------------------------------------------------
            // Carry out
            // --------------------------------------------------------

            if (arithmetic_ext[EXT_WIDTH]) begin

                norm_sig_next =
                    arithmetic_ext[EXT_WIDTH:1];

                // Preserve sticky information

                norm_sig_next[0] =
                    norm_sig_next[0] |
                    arithmetic_ext[0];


                exp_next =
                    {1'b0, s1_exp_large} + 1'b1;

            end

            else begin

                norm_sig_next =
                    arithmetic_ext[EXT_WIDTH-1:0];

                exp_next =
                    {1'b0, s1_exp_large};

            end

        end


        // ============================================================
        // DIFFERENT SIGNS -> SUBTRACT
        // ============================================================

        else begin

            arithmetic_ext =
                {1'b0, s1_sig_large_ext} -
                {1'b0, s1_sig_small_aligned};


            // --------------------------------------------------------
            // Exact cancellation
            // --------------------------------------------------------

            if (arithmetic_ext == 0) begin

                norm_sig_next = '0;

                exp_next = '0;

            end

            else begin

                norm_sig_next =
                    arithmetic_ext[EXT_WIDTH-1:0];

                exp_next =
                    {1'b0, s1_exp_large};


                // ----------------------------------------------------
                // Find leading zeros
                // ----------------------------------------------------

                lz_count =
                    leading_zero_count(
                        norm_sig_next
                    );


                // ----------------------------------------------------
                // Normalize left
                //
                // Never reduce effective exponent below 1.
                //
                // If exponent reaches 1 while hidden bit is zero,
                // final result is subnormal.
                // ----------------------------------------------------

                if (exp_next > 1) begin

                    if (
                        lz_count <
                        (exp_next - 1)
                    )

                        left_shift = lz_count;

                    else

                        left_shift =
                            exp_next - 1;


                    norm_sig_next =
                        norm_sig_next << left_shift;


                    exp_next =
                        exp_next - left_shift;

                end

            end

        end


        // ============================================================
        // STAGE 3 : ROUND + PACK
        // ============================================================

        s3_result_next =
            s2_special_result;


        if (
            s2_valid &&
            !s2_special
        ) begin

            logic guard_bit;
            logic round_bit;
            logic sticky_bit;
            logic round_up;

            logic [SIG_WIDTH:0] rounded_ext;
            logic [SIG_WIDTH-1:0] rounded_sig;

            logic [EXP_WIDTH:0] exp_after_round;

            logic [EXP_WIDTH-1:0] packed_exp;


            // --------------------------------------------------------
            // Guard / Round / Sticky
            // --------------------------------------------------------

            guard_bit =
                s2_norm_sig_ext[2];

            round_bit =
                s2_norm_sig_ext[1];

            sticky_bit =
                s2_norm_sig_ext[0];


            // --------------------------------------------------------
            // Round-to-nearest-even
            // --------------------------------------------------------

            round_up =
                guard_bit &&
                (
                    round_bit ||
                    sticky_bit ||
                    s2_norm_sig_ext[3]
                );


            // --------------------------------------------------------
            // Remove G/R/S bits
            // --------------------------------------------------------

            rounded_ext =
                {
                    1'b0,
                    s2_norm_sig_ext[EXT_WIDTH-1:3]
                };


            // --------------------------------------------------------
            // Apply rounding
            // --------------------------------------------------------

            if (round_up)

                rounded_ext =
                    rounded_ext + 1'b1;


            // --------------------------------------------------------
            // Rounding overflow
            // --------------------------------------------------------

            if (rounded_ext[SIG_WIDTH]) begin

                rounded_sig =
                    rounded_ext[SIG_WIDTH:1];

                exp_after_round =
                    s2_exp_work + 1'b1;

            end

            else begin

                rounded_sig =
                    rounded_ext[SIG_WIDTH-1:0];

                exp_after_round =
                    s2_exp_work;

            end


            // ========================================================
            // OVERFLOW -> INFINITY
            // ========================================================

            if (
                exp_after_round >=
                {1'b0, MAX_EXP}
            ) begin

                s3_result_next = {
                    s2_result_sign,
                    MAX_EXP,
                    {FRAC_WIDTH{1'b0}}
                };

            end


            // ========================================================
            // ZERO
            // ========================================================

            else if (rounded_sig == 0) begin

                s3_result_next = {
                    s2_result_sign,
                    {EXP_WIDTH{1'b0}},
                    {FRAC_WIDTH{1'b0}}
                };

            end


            // ========================================================
            // NORMAL / SUBNORMAL
            // ========================================================

            else begin

                // ----------------------------------------------------
                // If effective exponent is 1 and hidden bit is zero,
                // this is subnormal.
                // ----------------------------------------------------

                if (
                    (exp_after_round == 1) &&
                    !rounded_sig[SIG_WIDTH-1]
                )

                    packed_exp = '0;

                else

                    packed_exp =
                        exp_after_round[
                            EXP_WIDTH-1:0
                        ];


                // ----------------------------------------------------
                // Pack IEEE-754 number
                // ----------------------------------------------------

                s3_result_next = {
                    s2_result_sign,
                    packed_exp,
                    rounded_sig[FRAC_WIDTH-1:0]
                };

            end

        end

    end


    // ================================================================
    // PIPELINE REGISTERS
    // ================================================================

    always_ff @(posedge clk) begin

        // ============================================================
        // RESET
        // ============================================================

        if (rst) begin

            // Pipeline valid

            s1_valid <= 1'b0;
            s2_valid <= 1'b0;

            valid <= 1'b0;
            busy  <= 1'b0;


            // Output

            result <= '0;


            // Stage 1

            s1_special <= 1'b0;

            s1_special_result <= '0;

            s1_sign_large <= 1'b0;
            s1_sign_small <= 1'b0;

            s1_exp_large <= '0;

            s1_sig_large_ext <= '0;
            s1_sig_small_aligned <= '0;


            // Stage 2

            s2_special <= 1'b0;

            s2_special_result <= '0;

            s2_result_sign <= 1'b0;

            s2_exp_work <= '0;

            s2_norm_sig_ext <= '0;

        end

        else begin

            // ========================================================
            // STAGE 3 -> OUTPUT
            // ========================================================

            valid <= s2_valid;

            if (s2_valid)

                result <= s3_result_next;


            // ========================================================
            // STAGE 2 REGISTER
            // ========================================================

            s2_valid <= s1_valid;

            s2_special <= s1_special;

            s2_special_result <=
                s1_special_result;


            s2_result_sign <=
                result_sign_next;

            s2_exp_work <=
                exp_next;

            s2_norm_sig_ext <=
                norm_sig_next;


            // ========================================================
            // STAGE 1 REGISTER
            // ========================================================

            s1_valid <= start;


            if (start) begin

                // ----------------------------------------------------
                // Special cases
                // ----------------------------------------------------

                if (a_nan || b_nan) begin

                    s1_special <= 1'b1;

                    s1_special_result <=
                        QNAN;

                end

                else if (a_inf && b_inf) begin

                    s1_special <= 1'b1;

                    // +Inf + -Inf = NaN

                    if (sign_a != sign_b)

                        s1_special_result <=
                            QNAN;

                    else

                        s1_special_result <= {
                            sign_a,
                            MAX_EXP,
                            {FRAC_WIDTH{1'b0}}
                        };

                end

                else if (a_inf) begin

                    s1_special <= 1'b1;

                    s1_special_result <= {
                        sign_a,
                        MAX_EXP,
                        {FRAC_WIDTH{1'b0}}
                    };

                end

                else if (b_inf) begin

                    s1_special <= 1'b1;

                    s1_special_result <= {
                        sign_b,
                        MAX_EXP,
                        {FRAC_WIDTH{1'b0}}
                    };

                end

                else if (a_zero && b_zero) begin

                    s1_special <= 1'b1;

                    s1_special_result <= {
                        sign_a & sign_b,
                        {EXP_WIDTH{1'b0}},
                        {FRAC_WIDTH{1'b0}}
                    };

                end

                else if (a_zero) begin

                    s1_special <= 1'b1;

                    s1_special_result <= b;

                end

                else if (b_zero) begin

                    s1_special <= 1'b1;

                    s1_special_result <= a;

                end

                else begin

                    s1_special <= 1'b0;

                    s1_special_result <= '0;

                end


                // ----------------------------------------------------
                // Register aligned operands
                // ----------------------------------------------------

                s1_sign_large <=
                    sign_large;

                s1_sign_small <=
                    sign_small;


                s1_exp_large <=
                    exp_large;


                s1_sig_large_ext <=
                    {sig_large, 3'b000};


                s1_sig_small_aligned <=
                    shift_right_sticky(
                        {sig_small, 3'b000},
                        exp_diff
                    );

            end


            // ========================================================
            // BUSY
            // ========================================================

            busy <=
                start |
                s1_valid |
                s2_valid;

        end

    end

endmodule