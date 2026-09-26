module fp_alu #(parameter int WIDTH=64)(
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    input logic [1:0] op,
    output logic [WIDTH-1:0] result
);

    // 00 = ADD, 01 = SUB, 10 = MUL, 11 = DIV

    localparam logic [1:0] OP_ADD = 2'b00;
    localparam logic [1:0] OP_SUB = 2'b01;
    localparam logic [1:0] OP_MUL = 2'b10;
    localparam logic [1:0] OP_DIV = 2'b11;

    // Internal results
    logic [WIDTH-1:0] add_result;
    logic [WIDTH-1:0] sub_result;
    logic [WIDTH-1:0] mul_result;
    logic [WIDTH-1:0] div_result;

    // Negating B only requires flipping the sign bit
    logic [WIDTH-1:0] b_neg;

    assign b_neg = {~b[WIDTH-1],b[WIDTH-2:0]};

    fp_add #(.WIDTH(WIDTH)) add_unit (
        .a(a),
        .b(b),
        .result(add_result)
    );

    fp_add #(.WIDTH(WIDTH)) sub_unit (
        .a(a),
        .b(b_neg),
        .result(sub_result)
    );

    fp_mul #(.WIDTH(WIDTH)) mul_unit (
        .a(a),
        .b(b),
        .result(mul_result)
    );

    fp_div #(.WIDTH(WIDTH)) div_unit (
        .a(a),
        .b(b),
        .result(div_result)
    );

    // Select the result based on the operation
    always_comb begin
        case (op)
            OP_ADD:
                result = add_result;
            OP_SUB:
                result = sub_result;
            OP_MUL:
                result = mul_result;
            OP_DIV:
                result = div_result;
            default:
                result = '0;
        endcase
    end

endmodule