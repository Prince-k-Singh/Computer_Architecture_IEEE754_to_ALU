`timescale 1ns/1ps

module tb_fp_alu;

    logic [63:0] a;
    logic [63:0] b;
    logic [1:0] op;
    logic [63:0] result;

    // Operation codes

    localparam logic [1:0] OP_ADD = 2'b00;
    localparam logic [1:0] OP_SUB = 2'b01;
    localparam logic [1:0] OP_MUL = 2'b10;
    localparam logic [1:0] OP_DIV = 2'b11;

    // DUT

    fp_alu #(.WIDTH(64)) dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result)
    );

    // Test task

    task automatic test_alu(
        input [63:0] in_a,
        input [63:0] in_b,
        input [1:0] in_op,
        input [63:0] expected
    );
        begin
            a = in_a;
            b = in_b;
            op = in_op;

            #1;

            $display("---------------------------------------------");
            $display("A        = %h",a);
            $display("B        = %h",b);
            $display("OP       = %b",op);
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
        $display("IEEE-754 FP64 ALU TEST");
        $display("=============================================");

        // Addition

        test_alu(
            64'h3FF0000000000000,
            64'h4000000000000000,
            OP_ADD,
            64'h4008000000000000
        );

        test_alu(
            64'h4014000000000000,
            64'h4008000000000000,
            OP_ADD,
            64'h4020000000000000
        );

        test_alu(
            64'hC000000000000000,
            64'h4014000000000000,
            OP_ADD,
            64'h4008000000000000
        );

        // Subtraction

        test_alu(
            64'h4014000000000000,
            64'h4000000000000000,
            OP_SUB,
            64'h4008000000000000
        );

        test_alu(
            64'h4000000000000000,
            64'h4014000000000000,
            OP_SUB,
            64'hC008000000000000
        );

        test_alu(
            64'h4014000000000000,
            64'h4014000000000000,
            OP_SUB,
            64'h0000000000000000
        );

        // Multiplication

        test_alu(
            64'h4000000000000000,
            64'h4008000000000000,
            OP_MUL,
            64'h4018000000000000
        );

        test_alu(
            64'hC000000000000000,
            64'h4008000000000000,
            OP_MUL,
            64'hC018000000000000
        );

        test_alu(
            64'h3FF8000000000000,
            64'h4000000000000000,
            OP_MUL,
            64'h4008000000000000
        );

        // Division

        test_alu(
            64'h4018000000000000,
            64'h4000000000000000,
            OP_DIV,
            64'h4008000000000000
        );

        test_alu(
            64'h4020000000000000,
            64'h4000000000000000,
            OP_DIV,
            64'h4010000000000000
        );

        test_alu(
            64'h3FF0000000000000,
            64'h4000000000000000,
            OP_DIV,
            64'h3FE0000000000000
        );

        test_alu(
            64'hC018000000000000,
            64'h4000000000000000,
            OP_DIV,
            64'hC008000000000000
        );

        // Special values

        test_alu(
            64'h7FF0000000000000,
            64'h3FF0000000000000,
            OP_ADD,
            64'h7FF0000000000000
        );

        test_alu(
            64'h7FF0000000000000,
            64'h0000000000000000,
            OP_MUL,
            64'h7FF8000000000001
        );

        test_alu(
            64'h3FF0000000000000,
            64'h0000000000000000,
            OP_DIV,
            64'h7FF0000000000000
        );

        test_alu(
            64'h0000000000000000,
            64'h0000000000000000,
            OP_DIV,
            64'h7FF8000000000001
        );

        $display("=============================================");
        $display("FP64 ALU TESTS COMPLETED");
        $display("=============================================");

        $finish;
    end

endmodule