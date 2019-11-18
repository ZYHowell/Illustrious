`include "defines.v"

module Table(
    input wire rst, 
    input wire[`rsSize - 1] freeStatusALU, 
    input wire[`rsSize - 1] freeStatusLS,
    output wire[`TagRootBus] freeTagALU, 
    output wire[`TagRootBus] freeTagLS
);
    reg[`TagRootBus] list[`rsSize - 1];

    assign freeTagALU = list[freeStatusALU];
    assign freeTagLS = list[freeStatusLS];

    always @ (posedge rst) begin
        list[6'b000000] = `NoFreeTag;
        list[6'b000001] = 3'b000;
        list[6'b000010] = 3'b001;
        list[6'b000011] = 3'b000;
        list[6'b000100] = 3'b010;
        list[6'b000101] = 3'b000;
        list[6'b000110] = 3'b001;
        list[6'b000111] = 3'b000;
        list[6'b001000] = 3'b011;
        list[6'b001001] = 3'b000;
        list[6'b001010] = 3'b001;
        list[6'b001011] = 3'b000;
        list[6'b001100] = 3'b010;
        list[6'b001101] = 3'b000;
        list[6'b001110] = 3'b001;
        list[6'b001111] = 3'b000;
        list[6'b010000] = 3'b100;
        list[6'b010001] = 3'b000;
        list[6'b010010] = 3'b001;
        list[6'b010011] = 3'b000;
        list[6'b010100] = 3'b010;
        list[6'b010101] = 3'b000;
        list[6'b010110] = 3'b001;
        list[6'b010111] = 3'b000;
        list[6'b011000] = 3'b011;
        list[6'b011001] = 3'b000;
        list[6'b011010] = 3'b001;
        list[6'b011011] = 3'b000;
        list[6'b011100] = 3'b010;
        list[6'b011101] = 3'b000;
        list[6'b011110] = 3'b001;
        list[6'b011111] = 3'b000;
        list[6'b100000] = 3'b101;
        list[6'b100001] = 3'b000;
        list[6'b100010] = 3'b001;
        list[6'b100011] = 3'b000;
        list[6'b100100] = 3'b010;
        list[6'b100101] = 3'b000;
        list[6'b100110] = 3'b001;
        list[6'b100111] = 3'b000;
        list[6'b101000] = 3'b011;
        list[6'b101001] = 3'b000;
        list[6'b101010] = 3'b001;
        list[6'b101011] = 3'b000;
        list[6'b101100] = 3'b010;
        list[6'b101101] = 3'b000;
        list[6'b101110] = 3'b001;
        list[6'b101111] = 3'b000;
        list[6'b110000] = 3'b100;
        list[6'b110001] = 3'b000;
        list[6'b110010] = 3'b001;
        list[6'b110011] = 3'b000;
        list[6'b110100] = 3'b010;
        list[6'b110101] = 3'b000;
        list[6'b110110] = 3'b001;
        list[6'b110111] = 3'b000;
        list[6'b111000] = 3'b011;
        list[6'b111001] = 3'b000;
        list[6'b111010] = 3'b001;
        list[6'b111011] = 3'b000;
        list[6'b111100] = 3'b010;
        list[6'b111101] = 3'b000;
        list[6'b111110] = 3'b001;
        list[6'b111111] = 3'b000;
    end

endmodule