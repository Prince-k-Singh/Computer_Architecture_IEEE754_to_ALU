module fp_alu #(parameter int WIDTH=64)(
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    input logic [1:0] op,
    output logic [WIDTH-1:0] result
);

    // 00 = ADD, 01 = SUB, 10 = MUL, 11 = DIV

    logic [WIDTH-1:0] add_result;
    logic [WIDTH-1:0] sub_result;
    logic [WIDTH-1:0] mul_result;
    logic [WIDTH-1:0] div_result;

    // Negating B only needs the sign bit to be flipped
    logic [WIDTH-1:0] b_neg;
    assign b_neg={~b[WIDTH-1],b[WIDTH-2:0]};

    fp_add #(.WIDTH(WIDTH)) add_unit (.a(a),.b(b),.result(add_result));

    fp_add #(.WIDTH(WIDTH)) sub_unit (.a(a),.b(b_neg),.result(sub_result));
    fp_mul #(.WIDTH(WIDTH)) mul_unit (.a(a),.b(b),.result(mul_result));
    fp_div #(.WIDTH(WIDTH)) div_unit (.a(a),.b(b),.result(div_result));

    // Select result according to which operatipn we hav chosem
    always_comb begin
        case(op)
            2'b00: result=add_result;
            2'b01: result=sub_result;
            2'b10: result=mul_result;
            2'b11: result=div_result;
            default: result='0;
        endcase
    end

endmodule