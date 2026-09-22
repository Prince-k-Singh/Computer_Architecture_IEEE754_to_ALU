`timescale 1ns/1ps

module tb_fp_unpack_all;

    // ============================================================
    // FP16
    // ============================================================

    logic [15:0] fp16_data;
    logic fp16_sign;
    logic [4:0] fp16_exp;
    logic [9:0] fp16_frac;
    logic [10:0] fp16_sig;

    logic fp16_zero;
    logic fp16_subnormal;
    logic fp16_normal;
    logic fp16_inf;
    logic fp16_nan;

    fp_unpack #(
        .WIDTH(16)
    ) fp16 (
        .in_data(fp16_data),
        .sign(fp16_sign),
        .exponent(fp16_exp),
        .fraction(fp16_frac),
        .significand(fp16_sig),
        .is_zero(fp16_zero),
        .is_subnormal(fp16_subnormal),
        .is_normal(fp16_normal),
        .is_infinity(fp16_inf),
        .is_nan(fp16_nan)
    );

    // ============================================================
    // FP32
    // ============================================================

    logic [31:0] fp32_data;
    logic fp32_sign;
    logic [7:0] fp32_exp;
    logic [22:0] fp32_frac;
    logic [23:0] fp32_sig;

    logic fp32_zero;
    logic fp32_subnormal;
    logic fp32_normal;
    logic fp32_inf;
    logic fp32_nan;

    fp_unpack #(
        .WIDTH(32)
    ) fp32 (
        .in_data(fp32_data),
        .sign(fp32_sign),
        .exponent(fp32_exp),
        .fraction(fp32_frac),
        .significand(fp32_sig),
        .is_zero(fp32_zero),
        .is_subnormal(fp32_subnormal),
        .is_normal(fp32_normal),
        .is_infinity(fp32_inf),
        .is_nan(fp32_nan)
    );

    // ============================================================
    // FP64
    // ============================================================

    logic [63:0] fp64_data;
    logic fp64_sign;
    logic [10:0] fp64_exp;
    logic [51:0] fp64_frac;
    logic [52:0] fp64_sig;

    logic fp64_zero;
    logic fp64_subnormal;
    logic fp64_normal;
    logic fp64_inf;
    logic fp64_nan;

    fp_unpack #(
        .WIDTH(64)
    ) fp64 (
        .in_data(fp64_data),
        .sign(fp64_sign),
        .exponent(fp64_exp),
        .fraction(fp64_frac),
        .significand(fp64_sig),
        .is_zero(fp64_zero),
        .is_subnormal(fp64_subnormal),
        .is_normal(fp64_normal),
        .is_infinity(fp64_inf),
        .is_nan(fp64_nan)
    );

    // ============================================================
    // Test
    // ============================================================

    initial begin

        // 1.0
        fp16_data = 16'b0011110000000000;
        fp32_data = 32'b00111111100000000000000000000000;
        fp64_data = 64'b0011111111110000000000000000000000000000000000000000000000000000;

        #1;

        $display("=============================================");
        $display("PARAMETERIZATION TEST");
        $display("=============================================");

        $display("FP16:");
        $display(" Sign = %b", fp16_sign);
        $display(" Exp  = %0d", fp16_exp);
        $display(" Frac = %b", fp16_frac);

        $display("---------------------------------------------");

        $display("FP32:");
        $display(" Sign = %b", fp32_sign);
        $display(" Exp  = %0d", fp32_exp);
        $display(" Frac = %b", fp32_frac);

        $display("---------------------------------------------");

        $display("FP64:");
        $display(" Sign = %b", fp64_sign);
        $display(" Exp  = %0d", fp64_exp);
        $display(" Frac = %b", fp64_frac);

        $display("=============================================");

        $finish;

    end

endmodule