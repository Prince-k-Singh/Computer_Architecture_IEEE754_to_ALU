`timescale 1ns/1ps

module tb_fp_alu_param #(
    parameter int WIDTH = 64
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


    // ============================================================
    // OPERATION CODES
    // ============================================================

    localparam logic [1:0] OP_ADD = 2'b00;
    localparam logic [1:0] OP_SUB = 2'b01;
    localparam logic [1:0] OP_MUL = 2'b10;
    localparam logic [1:0] OP_DIV = 2'b11;


    // ============================================================
    // SIGNALS
    // ============================================================

    logic [WIDTH-1:0] a;
    logic [WIDTH-1:0] b;

    logic [1:0] op;

    logic [WIDTH-1:0] result;


    // ============================================================
    // DUT
    // ============================================================

    fp_alu #(
        .WIDTH(WIDTH)
    ) dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result)
    );


    // ============================================================
    // TEST COUNTERS
    // ============================================================

    integer total_tests;
    integer passed_tests;
    integer failed_tests;


    // ============================================================
    // TEST TASK
    // ============================================================

    task automatic check(
        input logic [WIDTH-1:0] in_a,
        input logic [WIDTH-1:0] in_b,
        input logic [1:0] in_op,
        input logic [WIDTH-1:0] expected
    );

        begin

            a  = in_a;
            b  = in_b;
            op = in_op;

            #1;

            total_tests = total_tests + 1;


            if (result === expected) begin

                passed_tests = passed_tests + 1;

            end

            else begin

                failed_tests = failed_tests + 1;

                $display("---------------------------------------------");

                $display("FAIL");

                $display("WIDTH    = %0d", WIDTH);
                $display("A        = %h", a);
                $display("B        = %h", b);
                $display("OP       = %b", op);

                $display("RESULT   = %h", result);
                $display("EXPECTED = %h", expected);

                $display("---------------------------------------------");

            end

        end

    endtask


    // ============================================================
    // TEST SUITE
    // ============================================================

    initial begin

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;


        $display("");
        $display("=============================================");
        $display("IEEE-754 ALU TEST");
        $display("WIDTH = %0d", WIDTH);
        $display("=============================================");


        // ========================================================
        // ADDITION
        // ========================================================

        // 1 + 2 = 3
        check(
            WIDTH'(64'h3FF0000000000000),
            WIDTH'(64'h4000000000000000),
            OP_ADD,
            WIDTH'(64'h4008000000000000)
        );


        // 5 + 3 = 8
        check(
            WIDTH'(64'h4014000000000000),
            WIDTH'(64'h4008000000000000),
            OP_ADD,
            WIDTH'(64'h4020000000000000)
        );


        // -2 + 5 = 3
        check(
            WIDTH'(64'hC000000000000000),
            WIDTH'(64'h4014000000000000),
            OP_ADD,
            WIDTH'(64'h4008000000000000)
        );


        // ========================================================
        // SUBTRACTION
        // ========================================================

        // 5 - 2 = 3
        check(
            WIDTH'(64'h4014000000000000),
            WIDTH'(64'h4000000000000000),
            OP_SUB,
            WIDTH'(64'h4008000000000000)
        );


        // 2 - 5 = -3
        check(
            WIDTH'(64'h4000000000000000),
            WIDTH'(64'h4014000000000000),
            OP_SUB,
            WIDTH'(64'hC008000000000000)
        );


        // 5 - 5 = 0
        check(
            WIDTH'(64'h4014000000000000),
            WIDTH'(64'h4014000000000000),
            OP_SUB,
            WIDTH'(64'h0000000000000000)
        );


        // ========================================================
        // MULTIPLICATION
        // ========================================================

        // 2 × 3 = 6
        check(
            WIDTH'(64'h4000000000000000),
            WIDTH'(64'h4008000000000000),
            OP_MUL,
            WIDTH'(64'h4018000000000000)
        );


        // -2 × 3 = -6
        check(
            WIDTH'(64'hC000000000000000),
            WIDTH'(64'h4008000000000000),
            OP_MUL,
            WIDTH'(64'hC018000000000000)
        );


        // 1.5 × 2 = 3
        check(
            WIDTH'(64'h3FF8000000000000),
            WIDTH'(64'h4000000000000000),
            OP_MUL,
            WIDTH'(64'h4008000000000000)
        );


        // ========================================================
        // DIVISION
        // ========================================================

        // 6 / 2 = 3
        check(
            WIDTH'(64'h4018000000000000),
            WIDTH'(64'h4000000000000000),
            OP_DIV,
            WIDTH'(64'h4008000000000000)
        );


        // 8 / 2 = 4
        check(
            WIDTH'(64'h4020000000000000),
            WIDTH'(64'h4000000000000000),
            OP_DIV,
            WIDTH'(64'h4010000000000000)
        );


        // 1 / 2 = 0.5
        check(
            WIDTH'(64'h3FF0000000000000),
            WIDTH'(64'h4000000000000000),
            OP_DIV,
            WIDTH'(64'h3FE0000000000000)
        );


        // ========================================================
        // ZERO
        // ========================================================

        check(
            WIDTH'(64'h0000000000000000),
            WIDTH'(64'h4000000000000000),
            OP_ADD,
            WIDTH'(64'h4000000000000000)
        );


        check(
            WIDTH'(64'h0000000000000000),
            WIDTH'(64'h4000000000000000),
            OP_MUL,
            WIDTH'(64'h0000000000000000)
        );


        check(
            WIDTH'(64'h0000000000000000),
            WIDTH'(64'h4000000000000000),
            OP_DIV,
            WIDTH'(64'h0000000000000000)
        );


        // ========================================================
        // SPECIAL CASES
        // ========================================================

        // 1 / 0 = Infinity
        check(
            WIDTH'(64'h3FF0000000000000),
            WIDTH'(64'h0000000000000000),
            OP_DIV,
            WIDTH'(64'h7FF0000000000000)
        );


        // Inf / Inf = NaN
        check(
            WIDTH'(64'h7FF0000000000000),
            WIDTH'(64'h7FF0000000000000),
            OP_DIV,
            WIDTH'(64'h7FF8000000000001)
        );


        // Inf × 0 = NaN
        check(
            WIDTH'(64'h7FF0000000000000),
            WIDTH'(64'h0000000000000000),
            OP_MUL,
            WIDTH'(64'h7FF8000000000001)
        );


        // ========================================================
        // SUMMARY
        // ========================================================

        $display("");
        $display("=============================================");
        $display("WIDTH %0d TEST SUMMARY", WIDTH);
        $display("=============================================");

        $display("TOTAL  = %0d", total_tests);
        $display("PASSED = %0d", passed_tests);
        $display("FAILED = %0d", failed_tests);

        if (failed_tests == 0)
            $display("STATUS = ALL TESTS PASSED");
        else
            $display("STATUS = TEST FAILURES");

        $display("=============================================");
        $display("");

        $finish;

    end

endmodule