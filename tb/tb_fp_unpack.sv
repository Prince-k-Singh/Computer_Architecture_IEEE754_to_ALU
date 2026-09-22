`timescale 1ns/1ps

module tb_fp_unpack;

    // ------------------------------------------------------------
    // FP64 input
    // ------------------------------------------------------------

    logic [63:0] in_data;

    logic        sign;
    logic [10:0] exponent;
    logic [51:0] fraction;
    logic [52:0] significand;

    logic is_zero;
    logic is_subnormal;
    logic is_normal;
    logic is_infinity;
    logic is_nan;

    // ------------------------------------------------------------
    // Device Under Test
    // ------------------------------------------------------------

    fp_unpack #(
        .WIDTH(64)
    ) dut (
        .in_data(in_data),

        .sign(sign),
        .exponent(exponent),
        .fraction(fraction),
        .significand(significand),

        .is_zero(is_zero),
        .is_subnormal(is_subnormal),
        .is_normal(is_normal),
        .is_infinity(is_infinity),
        .is_nan(is_nan)
    );

    // ------------------------------------------------------------
    // Test task
    // ------------------------------------------------------------

    task test_value(input real value);

        begin

            in_data = $realtobits(value);

            #1;

            $display("---------------------------------------------");
            $display("Input value : %f", value);
            $display("IEEE-754    : %b", in_data);
            $display("Sign        : %b", sign);
            $display("Exponent    : %b (%0d)", exponent, exponent);
            $display("Fraction    : %b", fraction);
            $display("Significand : %b", significand);

            $display("Zero        : %b", is_zero);
            $display("Subnormal   : %b", is_subnormal);
            $display("Normal      : %b", is_normal);
            $display("Infinity    : %b", is_infinity);
            $display("NaN         : %b", is_nan);

        end

    endtask

    // ------------------------------------------------------------
    // Tests
    // ------------------------------------------------------------

    initial begin

        test_value(1.0);
        test_value(1.5);
        test_value(6.5);
        test_value(-2.75);
        test_value(0.0);

        $display("---------------------------------------------");
        $display("All unpack tests completed.");
        $display("---------------------------------------------");

        $finish;

    end

endmodule