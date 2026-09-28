`timescale 1ns/1ps

module tb_fp_alu16;

    logic [15:0] a;
    logic [15:0] b;
    logic [1:0] op;
    logic [15:0] result;

    localparam logic [1:0] OP_ADD = 2'b00;
    localparam logic [1:0] OP_SUB = 2'b01;
    localparam logic [1:0] OP_MUL = 2'b10;
    localparam logic [1:0] OP_DIV = 2'b11;

    integer pass_count;
    integer fail_count;

    fp_alu #(.WIDTH(16)) dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result)
    );

    task automatic test_alu(
        input [15:0] in_a,
        input [15:0] in_b,
        input [1:0] in_op,
        input [15:0] expected
    );
        begin
            a = in_a;
            b = in_b;
            op = in_op;

            #1;

            $display("---------------------------------------------");
            $display("A        = %h", a);
            $display("B        = %h", b);
            $display("OP       = %b", op);
            $display("Result   = %h", result);
            $display("Expected = %h", expected);

            if (result === expected) begin
                $display("STATUS   = PASS");
                pass_count = pass_count + 1;
            end
            else begin
                $display("STATUS   = FAIL");
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin

        pass_count = 0;
        fail_count = 0;

        $display("");
        $display("=============================================");
        $display("IEEE-754 FP16 ALU TEST");
        $display("=============================================");

        test_alu(
            16'h3C00,       // 1.0
            16'h4000,       // 2.0
            OP_ADD,
            16'h4200        // 3.0
        );

        test_alu(
            16'h4000,       // 2.0
            16'h4000,       // 2.0
            OP_ADD,
            16'h4400        // 4.0
        );

        test_alu(
            16'hC000,       // -2.0
            16'h4500,       // 5.0
            OP_ADD,
            16'h4200        // 3.0
        );
        test_alu(
            16'h4500,       // 5.0
            16'h4000,       // 2.0
            OP_SUB,
            16'h4200        // 3.0
        );

        test_alu(
            16'h4000,       // 2.0
            16'h4500,       // 5.0
            OP_SUB,
            16'hC200        // -3.0
        );

        test_alu(
            16'h4000,       // 2.0
            16'h4000,       // 2.0
            OP_SUB,
            16'h0000        // 0.0
        );
        test_alu(
            16'h4000,       // 2.0
            16'h4200,       // 3.0
            OP_MUL,
            16'h4600        // 6.0
        );

        test_alu(
            16'hC000,       // -2.0
            16'h4200,       // 3.0
            OP_MUL,
            16'hC600        // -6.0
        );

        test_alu(
            16'h3E00,       // 1.5
            16'h4000,       // 2.0
            OP_MUL,
            16'h4200        // 3.0
        );
        test_alu(
            16'h4600,       // 6.0
            16'h4000,       // 2.0
            OP_DIV,
            16'h4200        // 3.0
        );

        test_alu(
            16'h4400,       // 4.0
            16'h4000,       // 2.0
            OP_DIV,
            16'h4000        // 2.0
        );

        test_alu(
            16'h3C00,       // 1.0
            16'h4000,       // 2.0
            OP_DIV,
            16'h3800        // 0.5
        );

        test_alu(
            16'hC600,       // -6.0
            16'h4000,       // 2.0
            OP_DIV,
            16'hC200        // -3.0
        );

        test_alu(
            16'h3C00,
            16'h0000,
            OP_DIV,
            16'h7C00
        );

        // Infinity * 0 = NaN
        test_alu(
            16'h7C00,
            16'h0000,
            OP_MUL,
            16'h7E01
        );
        $display("");
        $display("=============================================");
        $display("FP16 ALU TEST SUMMARY");
        $display("=============================================");
        $display("TOTAL TESTS = %0d", pass_count + fail_count);
        $display("PASSED      = %0d", pass_count);
        $display("FAILED      = %0d", fail_count);

        if (fail_count == 0)
            $display("OVERALL     = PASS");
        else
            $display("OVERALL     = FAIL");



        $finish;
    end

endmodule