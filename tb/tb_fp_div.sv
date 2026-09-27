`timescale 1ns/1ps

module tb_fp_div;

    logic [63:0] a;
    logic [63:0] b;
    logic [63:0] result;

    // DUT

    fp_div #(.WIDTH(64)) dut (
        .a(a),
        .b(b),
        .result(result)
    );

    // Test task

    task automatic test_div(
        input [63:0] in_a,
        input [63:0] in_b,
        input [63:0] expected
    );
        begin
            a = in_a;
            b = in_b;

            #1;

            $display("---------------------------------------------");
            $display("A        = %h",a);
            $display("B        = %h",b);
            $display("Result   = %h",result);
            $display("Expected = %h",expected);

            if (result === expected)
                $display("STATUS   = PASS");
            else
                $display("STATUS   = FAIL");
        end
    endtask

    // Tests

    initial begin
        $display("=============================================");
        $display("IEEE-754 FP64 DIVISION TEST");
        $display("=============================================");

        // Basic division

        test_div(
            64'h4018000000000000,
            64'h4000000000000000,
            64'h4008000000000000
        );

        test_div(
            64'h4024000000000000,
            64'h4000000000000000,
            64'h4014000000000000
        );

        test_div(
            64'h4020000000000000,
            64'h4000000000000000,
            64'h4010000000000000
        );

        test_div(
            64'h3FF0000000000000,
            64'h4000000000000000,
            64'h3FE0000000000000
        );

        test_div(
            64'h3FF0000000000000,
            64'h4010000000000000,
            64'h3FD0000000000000
        );

        test_div(
            64'h401C000000000000,
            64'h4000000000000000,
            64'h400C000000000000
        );

        // Negative numbers

        test_div(
            64'hC018000000000000,
            64'h4000000000000000,
            64'hC008000000000000
        );

        test_div(
            64'h4018000000000000,
            64'hC000000000000000,
            64'hC008000000000000
        );

        test_div(
            64'hC018000000000000,
            64'hC000000000000000,
            64'h4008000000000000
        );

        // Zero

        test_div(
            64'h0000000000000000,
            64'h4000000000000000,
            64'h0000000000000000
        );

        test_div(
            64'h8000000000000000,
            64'h4000000000000000,
            64'h8000000000000000
        );

        // Division by zero

        test_div(
            64'h3FF0000000000000,
            64'h0000000000000000,
            64'h7FF0000000000000
        );

        test_div(
            64'hBFF0000000000000,
            64'h0000000000000000,
            64'hFFF0000000000000
        );

        // Infinity

        test_div(
            64'h7FF0000000000000,
            64'h4000000000000000,
            64'h7FF0000000000000
        );

        test_div(
            64'hFFF0000000000000,
            64'h4000000000000000,
            64'hFFF0000000000000
        );

        test_div(
            64'h4000000000000000,
            64'h7FF0000000000000,
            64'h0000000000000000
        );

        // Invalid operations

        test_div(
            64'h7FF0000000000000,
            64'h7FF0000000000000,
            64'h7FF8000000000001
        );

        test_div(
            64'h0000000000000000,
            64'h0000000000000000,
            64'h7FF8000000000001
        );

        // NaN

        test_div(
            64'h7FF8000000000001,
            64'h3FF0000000000000,
            64'h7FF8000000000001
        );

        test_div(
            64'h3FF0000000000000,
            64'h7FF8000000000001,
            64'h7FF8000000000001
        );

        // Underflow

        test_div(
            64'h0010000000000000,
            64'h4000000000000000,
            64'h0008000000000000
        );

        // Overflow

        test_div(
            64'h7FEFFFFFFFFFFFFF,
            64'h3FE0000000000000,
            64'h7FF0000000000000
        );

        $display("=============================================");
        $display("DIVISION TESTS COMPLETED");
        $display("=============================================");

        $finish;
    end

endmodule