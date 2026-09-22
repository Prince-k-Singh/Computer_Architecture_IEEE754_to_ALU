module tb_fp_alu;

    logic [63:0] a;
    logic [63:0] b;
    logic [1:0]  op;
    logic [63:0] result;

    fp_alu #(
        .WIDTH(64)
    ) dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result)
    );

endmodule