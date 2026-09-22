`timescale 1ns/1ps

module tb_fp_classify;

    logic [63:0] in_data;

    logic is_zero;
    logic is_subnormal;
    logic is_normal;
    logic is_infinity;
    logic is_nan;

    fp_classify #(
        .WIDTH(64)
    ) dut (
        .in_data(in_data),

        .is_zero(is_zero),
        .is_subnormal(is_subnormal),
        .is_normal(is_normal),
        .is_infinity(is_infinity),
        .is_nan(is_nan)
    );

    task show_classification(input [63:0] value);

        begin

            in_data = value;

            #1;

            $display("---------------------------------------------");
            $display("Input       : %h", in_data);
            $display("Zero        : %b", is_zero);
            $display("Subnormal   : %b", is_subnormal);
            $display("Normal      : %b", is_normal);
            $display("Infinity    : %b", is_infinity);
            $display("NaN         : %b", is_nan);

        end

    endtask

    initial begin

        // +0
        show_classification(
            64'h0000000000000000
        );

        // 1.0
        show_classification(
            64'h3FF0000000000000
        );

        // +Infinity
        show_classification(
            64'h7FF0000000000000
        );

        // NaN
        show_classification(
            64'h7FF8000000000000
        );

        // Smallest positive subnormal
        show_classification(
            64'h0000000000000001
        );

        $display("---------------------------------------------");
        $display("Classification tests completed.");
        $display("---------------------------------------------");

        $finish;

    end

endmodule