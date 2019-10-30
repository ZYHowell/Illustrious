`include "defines.v"

module nextFree(
    input wire rst, 
    input wire[`rsSize - 1] ALUfreeState, 

    output wire[`TagBus] ALUfreeTag
)
    reg [`rsSize - 1] list[`TagBus];

    assign freeTag = list[freeStatus];

    always @ (posedge rst) begin
        list[6'b000000] = 4'b1000;
        list[6'b000001] = 4'b0000;
        list[6'b000010] = 4'b0001;
        list[6'b000011] = 4'b0000;
        list[6'b000100] = 4'b0010;
        list[6'b000101] = 4'b0000;
        list[6'b000110] = 4'b0001;
        list[6'b000111] = 4'b0000;
        list[6'b001000] = 4'b0011;
        list[6'b001001] = 4'b0000;
        list[6'b001010] = 4'b0001;
        list[6'b001011] = 4'b0000;
        list[6'b001100] = 4'b0010;
        list[6'b001101] = 4'b0000;
        list[6'b001110] = 4'b0001;
        list[6'b001111] = 4'b0000;
        list[6'b010000] = 4'b0100;
        list[6'b010001] = 4'b0000;
        list[6'b010010] = 4'b0001;
        list[6'b010011] = 4'b0000;
        list[6'b010100] = 4'b0010;
        list[6'b010101] = 4'b0000;
        list[6'b010110] = 4'b0001;
        list[6'b010111] = 4'b0000;
        list[6'b011000] = 4'b0011;
        list[6'b011001] = 4'b0000;
        list[6'b011010] = 4'b0001;
        list[6'b011011] = 4'b0000;
        list[6'b011100] = 4'b0010;
        list[6'b011101] = 4'b0000;
        list[6'b011110] = 4'b0001;
        list[6'b011111] = 4'b0000;
        list[6'b100000] = 4'b0101;
        list[6'b100001] = 4'b0000;
        list[6'b100010] = 4'b0001;
        list[6'b100011] = 4'b0000;
        list[6'b100100] = 4'b0010;
        list[6'b100101] = 4'b0000;
        list[6'b100110] = 4'b0001;
        list[6'b100111] = 4'b0000;
        list[6'b101000] = 4'b0011;
        list[6'b101001] = 4'b0000;
        list[6'b101010] = 4'b0001;
        list[6'b101011] = 4'b0000;
        list[6'b101100] = 4'b0010;
        list[6'b101101] = 4'b0000;
        list[6'b101110] = 4'b0001;
        list[6'b101111] = 4'b0000;
        list[6'b110000] = 4'b0100;
        list[6'b110001] = 4'b0000;
        list[6'b110010] = 4'b0001;
        list[6'b110011] = 4'b0000;
        list[6'b110100] = 4'b0010;
        list[6'b110101] = 4'b0000;
        list[6'b110110] = 4'b0001;
        list[6'b110111] = 4'b0000;
        list[6'b111000] = 4'b0011;
        list[6'b111001] = 4'b0000;
        list[6'b111010] = 4'b0001;
        list[6'b111011] = 4'b0000;
        list[6'b111100] = 4'b0010;
        list[6'b111101] = 4'b0000;
        list[6'b111110] = 4'b0001;
        list[6'b111111] = 4'b0000;
    end

endmodule

module dispatcher(
    //from decoder
    input wire[`NameBus]        regNameO, 
    input wire[`NameBus]        regNameT, 
    input wire[`NameBus]        rdName,
    input wire[`OpBus]          opCode,
    //from regfile
    input wire[`TagBus]         regTagO, 
    input wire[`DataBus]        regDataO, 
    input wire[`TagBus]         regTagT, 
    input wire[`DataBus]        regDataT, 
    //from ALUrs, which tag is avaliable
    input wire[`rsSize - 1:0]   ALUfreeState,
    //from LSbuffer, which tag is avaliable


    //to regfile(rename the rd)
    output wire                 enWrt, 
    output wire[`TagBus]        wrtTag, 
    output wire[`NameBus]       wrtName, 
    //to ALUrs
    output wire[`DataBus]       ALUoperandO, 
    output wire[`DataBus]       ALUoperandT, 
    output wire[`TagBus]        ALUtagO, 
    output wire[`TagBus]        ALUtagT,
    output wire[`TagBus]        ALUtagW, 
    output wire[`OpBus]         ALUop
    //to BranchRS
    //to LSbuffer
)
    wire [`TagBus] ALUfreeTag;
    
    nextFree freetag(
        .rst(rst),
        .ALUfreeState(ALUfreeState), 
        .ALUfreeTag(ALUfreeTag)
    );

    always @ (posedge clk) begin
        
    end

endmodule