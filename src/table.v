`include "defines.v"

module TableSix(
    input wire[5:0] emptyStatus, 
    output reg[2:0] num
);
    always @(*) begin
      case(emptyStatus)
        6'b000000: num = 3'b110;
        6'b000001: num = 3'b101;
        6'b000010: num = 3'b101;
        6'b000011: num = 3'b100;
        6'b000100: num = 3'b101;
        6'b000101: num = 3'b100;
        6'b000110: num = 3'b100;
        6'b000111: num = 3'b011;
        6'b001000: num = 3'b101;
        6'b001001: num = 3'b100;
        6'b001010: num = 3'b100;
        6'b001011: num = 3'b011;
        6'b001100: num = 3'b100;
        6'b001101: num = 3'b011;
        6'b001110: num = 3'b011;
        6'b001111: num = 3'b010;
        6'b010000: num = 3'b101;
        6'b010001: num = 3'b100;
        6'b010010: num = 3'b100;
        6'b010011: num = 3'b011;
        6'b010100: num = 3'b100;
        6'b010101: num = 3'b011;
        6'b010110: num = 3'b011;
        6'b010111: num = 3'b010;
        6'b011000: num = 3'b100;
        6'b011001: num = 3'b011;
        6'b011010: num = 3'b011;
        6'b011011: num = 3'b010;
        6'b011100: num = 3'b011;
        6'b011101: num = 3'b010;
        6'b011110: num = 3'b010;
        6'b011111: num = 3'b001;
        6'b100000: num = 3'b101;
        6'b100001: num = 3'b100;
        6'b100010: num = 3'b100;
        6'b100011: num = 3'b011;
        6'b100100: num = 3'b100;
        6'b100101: num = 3'b011;
        6'b100110: num = 3'b011;
        6'b100111: num = 3'b010;
        6'b101000: num = 3'b100;
        6'b101001: num = 3'b011;
        6'b101010: num = 3'b011;
        6'b101011: num = 3'b010;
        6'b101100: num = 3'b011;
        6'b101101: num = 3'b010;
        6'b101110: num = 3'b010;
        6'b101111: num = 3'b001;
        6'b110000: num = 3'b100;
        6'b110001: num = 3'b011;
        6'b110010: num = 3'b011;
        6'b110011: num = 3'b010;
        6'b110100: num = 3'b011;
        6'b110101: num = 3'b010;
        6'b110110: num = 3'b010;
        6'b110111: num = 3'b001;
        6'b111000: num = 3'b011;
        6'b111001: num = 3'b010;
        6'b111010: num = 3'b010;
        6'b111011: num = 3'b001;
        6'b111100: num = 3'b010;
        6'b111101: num = 3'b001;
        6'b111110: num = 3'b001;
        6'b111111: num = 3'b000;
        default:num = 0;
      endcase
    end
endmodule

module TableThree(
    input wire[2:0] emptyStatus, 
    output reg[1:0] num
);
    always @(*) begin
      case(emptyStatus)
        3'b000: num <= 2'b11;
        3'b001: num <= 2'b10;
        3'b010: num <= 2'b10;
        3'b011: num <= 2'b01;
        3'b100: num <= 2'b10;
        3'b101: num <= 2'b01;
        3'b110: num <= 2'b01;
        3'b111: num <= 2'b00;
      endcase
    end
endmodule