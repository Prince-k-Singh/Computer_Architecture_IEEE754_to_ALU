module fp_add #(parameter int WIDTH=64)(
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] result
);


    // IEEE-754 parameters according to sizes

    localparam int EXP_WIDTH =
        (WIDTH == 16) ? 5 :
        (WIDTH == 32) ? 8 :
        (WIDTH == 64) ? 11 : 0;

    localparam int FRAC_WIDTH = WIDTH-EXP_WIDTH-1;
    localparam int SIG_WIDTH = FRAC_WIDTH+1;

    // QNAN just stores the definition for NAN for compact if-else use
    localparam logic [WIDTH-1:0] QNAN = {1'b0,{EXP_WIDTH{1'b1}},1'b1,{(FRAC_WIDTH-1){1'b0}}};


    // Definitions for further operations
    logic sign_a;
    logic sign_b;
    logic [EXP_WIDTH-1:0] exp_a;
    logic [EXP_WIDTH-1:0] exp_b;
    logic [FRAC_WIDTH-1:0] frac_a;
    logic [FRAC_WIDTH-1:0] frac_b;
    logic [SIG_WIDTH-1:0] sig_a;
    logic [SIG_WIDTH-1:0] sig_b;


    // Definitions for classification of a and b
    logic a_zero;
    logic a_subnormal;
    logic a_normal;
    logic a_infinity;
    logic a_nan;
    logic b_zero;
    logic b_subnormal;
    logic b_normal;
    logic b_infinity;
    logic b_nan;

    logic [SIG_WIDTH-1:0] sig_large;
    logic [SIG_WIDTH-1:0] sig_small;
    logic [EXP_WIDTH-1:0] exp_large;
    logic [EXP_WIDTH-1:0] exp_small;
    logic sign_large;
    logic sign_small;
    logic [EXP_WIDTH-1:0] exp_diff;
    logic [SIG_WIDTH-1:0] sig_small_shifted;

    // Extra bit handles 1.x + 1.x = 10.x
    logic [SIG_WIDTH:0] arithmetic_result;

    // Normalized result
    logic result_sign;
    logic [EXP_WIDTH-1:0] result_exp;
    logic [SIG_WIDTH-1:0] result_sig;


    // Unpack A
    always_comb begin
        sign_a = a[WIDTH-1];
        exp_a = a[WIDTH-2 -: EXP_WIDTH];
        frac_a = a[FRAC_WIDTH-1:0];

        if (exp_a == 0)
            sig_a = {1'b0,frac_a};
        else
            sig_a = {1'b1,frac_a};
    end

    // Unpack B
    always_comb begin
        sign_b = b[WIDTH-1];
        exp_b = b[WIDTH-2 -: EXP_WIDTH];
        frac_b = b[FRAC_WIDTH-1:0];

        if (exp_b == 0)
            sig_b = {1'b0,frac_b};
        else
            sig_b = {1'b1,frac_b};
    end

    // Classification
    always_comb begin
        a_zero = (exp_a == 0) && (frac_a == 0);
        a_subnormal = (exp_a == 0) && (frac_a != 0);
        a_infinity = (&exp_a) && (frac_a == 0);
        a_nan = (&exp_a) && (frac_a != 0);
        a_normal = !a_zero && !a_subnormal && !a_infinity && !a_nan;

        b_zero = (exp_b == 0) && (frac_b == 0);
        b_subnormal = (exp_b == 0) && (frac_b != 0);
        b_infinity = (&exp_b) && (frac_b == 0);
        b_nan = (&exp_b) && (frac_b != 0);
        b_normal = !b_zero && !b_subnormal && !b_infinity && !b_nan;
    end

    // Main arithmetic
    always_comb begin
        result = '0;
        sig_large = '0;
        sig_small = '0;
        exp_large = '0;
        exp_small = '0;
        sign_large = 1'b0;
        sign_small = 1'b0;
        exp_diff = '0;
        sig_small_shifted = '0;
        arithmetic_result = '0;
        result_sign = 1'b0;
        result_exp = '0;
        result_sig = '0;

        if (a_nan || b_nan) begin
            result = QNAN;
        end

        else if (a_infinity && b_infinity) begin
            if (sign_a == sign_b) begin
                result = {sign_a,{EXP_WIDTH{1'b1}},{FRAC_WIDTH{1'b0}}};
            end
            else begin
                result = QNAN;
            end
        end

        else if (a_infinity) begin
            result = {sign_a,{EXP_WIDTH{1'b1}},{FRAC_WIDTH{1'b0}}};
        end

        else if (b_infinity) begin
            result = {sign_b,{EXP_WIDTH{1'b1}},{FRAC_WIDTH{1'b0}}};
        end

        else if (a_zero && b_zero) begin
            result = {sign_a & sign_b,{EXP_WIDTH{1'b0}},{FRAC_WIDTH{1'b0}}};
        end

        else if (a_zero) begin
            result = b;
        end

        else if (b_zero) begin
            result = a;
        end

        else begin
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

            exp_diff = exp_large-exp_small;

            if (exp_diff >= SIG_WIDTH)
                sig_small_shifted = '0;
            else
                sig_small_shifted = sig_small >> exp_diff;

            if (sign_large == sign_small) begin
                arithmetic_result = {1'b0,sig_large}+{1'b0,sig_small_shifted};
                result_sign = sign_large;
            end
            else begin
                arithmetic_result = {1'b0,sig_large}-{1'b0,sig_small_shifted};
                result_sign = sign_large;
            end

            if (arithmetic_result == 0) begin
                result = '0;
            end

            else begin
                result_exp = exp_large;
                result_sig = arithmetic_result[SIG_WIDTH-1:0];

                if (arithmetic_result[SIG_WIDTH]) begin
                    result_sig = arithmetic_result[SIG_WIDTH:1];
                    result_exp = exp_large+1'b1;
                end

                else begin
                    for (int i=0;i<SIG_WIDTH;i=i+1) begin
                        if ((result_sig[SIG_WIDTH-1] == 1'b0) && (result_exp > 0)) begin
                            result_sig = result_sig << 1;
                            result_exp = result_exp-1'b1;
                        end
                    end
                end

                if (&result_exp) begin
                    result = {result_sign,{EXP_WIDTH{1'b1}},{FRAC_WIDTH{1'b0}}};
                end
                else begin
                    result = {result_sign,result_exp,result_sig[FRAC_WIDTH-1:0]};
                end
            end
        end
    end

endmodule