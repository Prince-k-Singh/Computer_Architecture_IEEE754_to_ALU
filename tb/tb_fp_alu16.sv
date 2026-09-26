`timescale 1ns/1ps

module tb_fp_alu16;

    logic [15:0] a;
    logic [15:0] b;
    logic [1:0] op;

    logic [15:0] result;

    localparam logic [1:0] ADD = 2'b00;
    localparam logic [1:0] SUB = 2'b01;
    localparam logic [1:0] MUL = 2'b10;
    localparam logic [1:0] DIV = 2'b11;


    fp_alu #(
        .WIDTH(16)
    ) dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result)
    );


    task automatic test(
        input [15:0] x,
        input [15:0] y,
        input [1:0] operation,
        input [15:0] expected
    );

        begin

            a = x;
            b = y;
            op = operation;

            #1;

            if (result === expected)

                $display(
                    "PASS: A=%h B=%h OP=%b RESULT=%h",
                    a, b, op, result
                );

            else

                $display(
                    "FAIL: A=%h B=%h OP=%b RESULT=%h EXPECTED=%h",
                    a, b, op, result, expected
                );

        end

    endtask


    initial begin

        $display("");
        $display("=============================================");
        $display("FP16 ALU TEST");
        $display("=============================================");


        // ========================================================
        // ADD
        // ========================================================

        // 1 + 2 = 3
        test(
            16'h3C00,
            16'h4000,
            ADD,
            16'h4200
        );


        // 2 + 2 = 4
        test(
            16'h4000,
            16'h4000,
            ADD,
            16'h4400
        );


        // -2 + 5 = 3
        test(
            16'hC000,
            16'h4500,
            ADD,
            16'h4200
        );


        // ========================================================
        // SUB
        // ========================================================

        // 5 - 2 = 3
        test(
            16'h4500,
            16'h4000,
            SUB,
            16'h4200
        );


        // 2 - 5 = -3
        test(
            16'h4000,
            16'h4500,
            SUB,
            16'hC200
        );


        // ========================================================
        // MUL
        // ========================================================

        // 2 × 3 = 6
        test(
            16'h4000,
            16'h4200,
            MUL,
            16'h4600
        );


        // -2 × 3 = -6
        test(
            16'hC000,
            16'h4200,
            MUL,
            16'hC600
        );


        // ========================================================
        // DIV
        // ========================================================

        // 6 / 2 = 3
        test(
            16'h4600,
            16'h4000,
            DIV,
            16'h4200
        );


        // 1 / 2 = 0.5
        test(
            16'h3C00,
            16'h4000,
            DIV,
            16'h3800
        );


        // ========================================================
        // SPECIAL VALUES
        // ========================================================

        // 1 / 0 = Inf
        test(
            16'h3C00,
            16'h0000,
            DIV,
            16'h7C00
        );


        // Inf × 0 = NaN
        test(
            16'h7C00,
            16'h0000,
            MUL,
            16'h7E01
        );


        $display("=============================================");
        $display("FP16 TEST COMPLETED");
        $display("=============================================");

        $finish;

    end

endmodule