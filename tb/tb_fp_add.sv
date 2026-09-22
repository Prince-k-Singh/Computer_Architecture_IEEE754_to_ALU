`timescale 1ns/1ps

module tb_fp_add;

    logic [63:0] a;
    logic [63:0] b;

    logic [63:0] result;

    fp_add #(
        .WIDTH(64)
    ) dut (
        .a(a),
        .b(b),
        .result(result)
    );


    task test_add(
        input real value_a,
        input real value_b
    );

        reg [63:0] expected;

        begin

            a = $realtobits(value_a);
            b = $realtobits(value_b);

            expected =
                $realtobits(value_a + value_b);

            #1;

            $display("---------------------------------------------");

            $display("A        = %f", value_a);
            $display("B        = %f", value_b);

            $display("A bits   = %h", a);
            $display("B bits   = %h", b);

            $display("Result   = %h", result);
            $display("Expected = %h", expected);

            if (result == expected)
                $display("STATUS   = PASS");
            else
                $display("STATUS   = FAIL");

        end

    endtask


    initial begin

        $display("=============================================");
        $display("IEEE-754 FP64 ADDITION TEST");
        $display("=============================================");


        // --------------------------------------------------------
        // Basic addition
        // --------------------------------------------------------

        test_add(1.0, 2.0);

        test_add(1.5, 2.25);

        test_add(6.5, 3.5);


        // --------------------------------------------------------
        // Same number
        // --------------------------------------------------------

        test_add(5.0, 5.0);


        // --------------------------------------------------------
        // Negative numbers
        // --------------------------------------------------------

        test_add(-1.0, 2.0);

        test_add(1.0, -2.0);

        test_add(-1.5, -2.25);


        // --------------------------------------------------------
        // Cancellation
        // --------------------------------------------------------

        test_add(5.0, -5.0);

        test_add(10.0, -9.0);


        // --------------------------------------------------------
        // Zero
        // --------------------------------------------------------

        test_add(0.0, 5.0);

        test_add(5.0, 0.0);


        // --------------------------------------------------------
        // Large exponent difference
        // --------------------------------------------------------

        test_add(1000000.0, 1.0);

        test_add(1.0, 1000000.0);


        $display("=============================================");
        $display("ADDITION TESTS COMPLETED");
        $display("=============================================");

        $finish;

    end

endmodule