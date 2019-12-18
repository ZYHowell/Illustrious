`include "defines.v"
module LSALU(
    input wire  LSworkEn, 
    input wire[`DataBus]  operandO, 
    input wire[`DataBus]  operandT,  
    input wire[`DataBus]  imm, 
    input wire[`TagBus] wrtTag, 
    input wire[`NameBus]  wrtName, 
    input wire[`OpBus]  opCode, 

    output reg LSROBen, 
    output reg LSRW, 
    output reg[`LenBus] LSlen, 
    output reg[`NameBus]LSROBname, 
    output reg[`DataBus]Sdata, 
    output reg[`TagBus] LSROBtag, 
    output reg[`DataAddrBus]  dataAddr, 
    output reg sign
);

    always @(*) begin
      LSRW = `Read;
      LSlen = `ByteLen;
      Sdata = `dataFree;
      LSROBname = `nameFree;
      LSROBtag = `tagFree;
      sign = `SignEx;
      LSROBen = LSworkEn;
      dataAddr = operandO + imm;
      case (opCode) 
        `LB: begin
          LSlen = `ByteLen;
          LSROBname = wrtName;
          LSROBtag = wrtTag;
          sign = `SignEx;
        end
        `LH: begin
          LSlen = `HexLen;
          LSROBname = wrtName;
          LSROBtag = wrtTag;
          sign = `SignEx;
        end
        `LW: begin
          LSlen = `WordLen;
          LSROBname = wrtName;
          LSROBtag = wrtTag;
          sign = `SignEx;
        end
        `LBU: begin
          LSlen = `ByteLen;
          LSROBname = wrtName;
          LSROBtag = wrtTag;
          sign = `UnsignEx;
        end
        `LHU: begin
          LSlen = `HexLen;
          LSROBname = wrtName;
          LSROBtag = wrtTag;
          sign = `UnsignEx;
        end
        `SB: begin
          LSRW = `Write;
          LSlen = 3'b000;
          Sdata = operandT;
          sign = `SignEx;
        end
        `SH: begin
          LSRW = `Write;
          LSlen = 3'b001;
          Sdata = operandT;
          sign = `SignEx;
        end
        `SW: begin
          LSRW = `Write;
          LSlen = 3'b011;
          Sdata = operandT;
          sign = `SignEx;
        end
      endcase
    end
endmodule