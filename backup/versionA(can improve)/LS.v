`include "defines.v"
module LS(
    input wire clk, 
    input wire rst, 

    //from lsbuffer
    input wire  LSworkEn, 
    input wire[`DataBus]  operandO, 
    input wire[`DataBus]  operandT,  
    input wire[`DataBus]  imm, 
    input wire[`TagBus] wrtTag, 
    input wire[`OpBus]  opCode, 

    //to lsbuffer
    output wire LSunwork, 

    //with mem
    input wire LSoutEn, 
    input wire[`DataBus]  Ldata, 

    output reg dataEn, 
    output reg LSRW, 
    output reg[`DataAddrBus]  dataAddr,
    output reg[`LenBus] LSlen, 
    output reg[`DataBus] Sdata,
    //to ROB
    output reg LSROBen, 
    output reg[`DataBus] LSROBdata, 
    output reg[`TagBus] LSROBtag, 
    output reg LSdone
  );
    reg status, sign; 

    assign LSunwork = (status == `IsFree) ? ~LSworkEn : LSoutEn;
    always @ (posedge clk or posedge rst) begin
      if (rst) begin
        status <= `IsFree;
        sign <= `SignEx;
        dataEn <= `Disable;
        LSRW <= `Read;
        dataAddr <= `addrFree;
        LSlen <= `ZeroLen;
        Sdata <= `dataFree;
        LSROBen <= `Disable;
        LSROBdata <= `dataFree;
        LSROBtag <= `tagFree;
        LSdone <= 0;
      end else begin
        LSdone <= 0;
        case(status)
          `IsFree: begin
            LSROBen <= `Disable;
            if (LSworkEn) begin
              dataAddr <= operandO + imm;
              status <= `NotFree;
              dataEn <= `Enable;
              case (opCode) 
                `LB: begin
                  LSRW <= `Read;
                  LSlen <= `ByteLen;
                  Sdata <= `dataFree;
                  LSROBtag <= wrtTag;
                  sign <= `SignEx;
                end
                `LH: begin
                  LSRW <= `Read;
                  LSlen <= `HexLen;
                  Sdata <= `dataFree;
                  LSROBtag <= wrtTag;
                  sign <= `SignEx;
                end
                `LW: begin
                  LSRW <= `Read;
                  LSlen <= `WordLen;
                  Sdata <= `dataFree;
                  LSROBtag <= wrtTag;
                  sign <= `SignEx;
                end
                `LBU: begin
                  LSRW <= `Read;
                  LSlen <= `ByteLen;
                  Sdata <= `dataFree;
                  LSROBtag <= wrtTag;
                  sign <= `UnsignEx;
                end
                `LHU: begin
                  LSRW <= `Read;
                  LSlen <= `HexLen;
                  Sdata <= `dataFree;
                  LSROBtag <= wrtTag;
                  sign <= `UnsignEx;
                end
                `SB: begin
                  LSRW <= `Write;
                  LSlen <= 3'b000;
                  Sdata <= operandT;
                  LSROBtag <= `tagFree;
                  sign <= `SignEx;
                end
                `SH: begin
                  LSRW <= `Write;
                  LSlen <= 3'b001;
                  Sdata <= operandT;
                  LSROBtag <= `tagFree;
                  sign <= `SignEx;
                end
                `SW: begin
                  LSRW <= `Write;
                  LSlen <= 3'b011;
                  Sdata <= operandT;
                  LSROBtag <= `tagFree;
                  sign <= `SignEx;
                end
              endcase
            end else begin
              dataEn <= `Disable;
              LSRW <= `Read;
              dataAddr <= `addrFree;
              LSlen <= `ZeroLen;
              Sdata <= `dataFree;
              LSROBen <= `Disable;
              LSROBdata <= `dataFree;
              LSROBtag <= `tagFree;
            end
          end
          `NotFree: begin
            dataEn <= `Disable;
            if (LSoutEn) begin
              LSdone <= 1;
              LSRW <= `Read;
              LSROBen <= (LSRW == `Read) ? `Enable : `Disable;
              status <= `IsFree;
              LSlen <= `ZeroLen;
              Sdata <= `dataFree;
              dataAddr <= `addrFree;
              if (sign == `SignEx) begin
                case (LSlen)
                  `ByteLen: LSROBdata <= {{24{Ldata[7]}}, Ldata[7:0]};
                  `HexLen:  LSROBdata <= {{16{Ldata[15]}}, Ldata[15:0]};
                  `WordLen: LSROBdata <= Ldata;
                endcase
              end else begin
                case (LSlen)
                  `ByteLen: LSROBdata <= {{24{1'b0}}, Ldata[7:0]};
                  `HexLen:  LSROBdata <= {{16{1'b0}}, Ldata[7:0]};
                  `WordLen: LSROBdata <= Ldata;
                endcase
              end
            end
          end
        endcase
      end
    end
endmodule