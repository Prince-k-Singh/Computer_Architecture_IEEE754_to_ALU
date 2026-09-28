`timescale 1ns/1ps


module tb_fp_add;

    logic [63:0] a;
    logic [63:0] b;
    logic [63:0] result;
    // DUT
    fp_add #(.WIDTH(64)) dut (
        .a(a),
        .b(b),
        .result(result)
    );
    // Test task
    task automatic test_add(
        input [63:0] in_a,
        input [63:0] in_b,
        input [63:0] expected
    );
        begin
            a = in_a;
            b = in_b;

            #1;

            $display("---------------------------------------------");
            $display("A        = %h", a);
            $display("B        = %h", b);
            $display("Result   = %h", result);
            $display("Expected = %h", expected);

            if (result === expected)
                $display("STATUS = PASS");
            else
                $display("STATUS= FAIL");
        end
    endtask

    // Test cases
    initial begin

        //$display("=============================================");
        $display("IEEE-754 FP64 ADDITION TEST");
        //$display("=============================================");
        //1.0+2.0=3.0
        test_add(
            64'h3FF0000000000000,
            64'h4000000000000000,
            64'h4008000000000000
        );
        //5.0+3.0=8.0
        test_add(
            64'h4014000000000000,
            64'h4008000000000000,
            64'h4020000000000000
        );
        //1.5+1.5=3.0
        test_add(
            64'h3FF8000000000000,
            64'h3FF8000000000000,
            64'h4008000000000000
        );
        //2.5+0.5=3.0
        test_add(
            64'h4004000000000000,
            64'h3FE0000000000000,
            64'h4008000000000000
        );
        //2.0+0.25=2.25
        test_add(
            64'h4000000000000000,
            64'h3FD0000000000000,
            64'h4002000000000000
        );
        //4.0+0.5=4.5
        test_add(
            64'h4010000000000000,
            64'h3FE0000000000000,
            64'h4012000000000000
        );
        //-2.0+3.0=1.0
        test_add(
            64'hC000000000000000,
            64'h4008000000000000,
            64'h3FF0000000000000
        );
        //-3.0-2.0=-5.0
        test_add(
            64'hC008000000000000,
            64'hC000000000000000,
            64'hC014000000000000
        );
        //3.0-2.0=1.0
        test_add(
            64'h4008000000000000,
            64'hC000000000000000,
            64'h3FF0000000000000
        );
        //1.0-1.0=0.0
        test_add(
            64'h3FF0000000000000,
            64'hBFF0000000000000,
            64'h0000000000000000
        );
        //0+5.0=5.0
        test_add(
            64'h0000000000000000,
            64'h4014000000000000,
            64'h4014000000000000
        );

        //5.0-0.0 = 5.0
        test_add(
            64'h8000000000000000,
            64'h4014000000000000,
            64'h4014000000000000
        );

        //+Infinity+2.0=+Infinity
        test_add(
            64'h7FF0000000000000,
            64'h4000000000000000,
            64'h7FF0000000000000
        );

        //-Infinity+2.0=-Infinity
        test_add(
            64'hFFF0000000000000,
            64'h4000000000000000,
            64'hFFF0000000000000
        );

        //+Infinity-Infinity=NaN
        test_add(
            64'h7FF0000000000000,
            64'hFFF0000000000000,
            64'h7FF8000000000000
        );

        //NaN+1.0=NaN
        test_add(
            64'h7FF8000000000001,
            64'h3FF0000000000000,
            64'h7FF8000000000000
        );

        //maximum finite+maximum finite=+Infinity
        test_add(
            64'h7FEFFFFFFFFFFFFF,
            64'h7FEFFFFFFFFFFFFF,
            64'h7FF0000000000000
        );

        $display("=============================================");
        $display("ADDITION TESTS COMPLETED");
        $display("=============================================");

        $finish;

    end

endmodule
