module fp_alu #(parameter int WIDTH = 64)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,

    input  logic [1:0] op,

    output logic [WIDTH-1:0] result
);

    localparam logic [1:0] OP_ADD = 2'b00;
    localparam logic [1:0] OP_SUB = 2'b01;
    localparam logic [1:0] OP_MUL = 2'b10;
    localparam logic [1:0] OP_DIV = 2'b11;

endmodule