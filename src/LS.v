//`include "defines.v"
module LS(
    input wire clk, 
    input wire rst, 

    //from lsbuffer
    input wire  LSworkEn, 
    input wire[`DataBus]  operandO, 
    input wire[`DataBus]  operandT,  
    input wire[`DataBus]  imm, 
    input wire[`TagBus] wrtTag, 
    input wire[`NameBus]  wrtName, 
    input wire[`OpBus]  opCode, 

    //to lsbuffer
    output wire LSunwork, 

    //with mem
    input wire LSoutEn, 
    input wire[`DataBus]  Ldata,  
    input wire LSfree, 

    output reg dataEn, 
    output reg LSRW, 
    output reg[`DataAddrBus]  dataAddr,
    output reg[1:0] LSlen, 
    output reg[`DataBus] Sdata,
    //to ROB
    output reg LSROBen, 
    output reg[`DataBus] LSROBdata, 
    output reg[`TagBus] LSROBtag, 
    output reg[`NameBus]  LSROBname
  );
    reg status, sign; 

    assign LSunwork = (status == `IsFree) ? ~LSworkEn : LSoutEn;

    always @ (posedge clk or posedge rst) begin
      if (rst == `Enable) begin
        status <= `IsFree;
        dataEn <= `Disable;
        LSRW <= `Read;
        dataAddr <= `addrFree;
        LSlen <= 0;
        Sdata <= `dataFree;
        LSROBen <= `Disable;
        LSROBdata <= `dataFree;
        LSROBtag <= `tagFree;
        LSROBname <= `nameFree;
      end else begin
        case(status)
          `IsFree: begin
            LSROBen <= `Disable;
            if (LSworkEn == `Enable) begin
              dataAddr <= operandO + imm;
              status <= `NotFree;
              dataEn <= `Enable;
              case (opCode) 
                `LB: begin
                  LSRW <= `Read;
                  LSlen <= 2'b00;
                  Sdata <= `dataFree;
                  LSROBname <= wrtName;
                  LSROBtag <= wrtTag;
                  sign <= `SignEx;
                end
                `LH: begin
                  LSRW <= `Read;
                  LSlen <= 2'b01;
                  Sdata <= `dataFree;
                  LSROBname <= wrtName;
                  LSROBtag <= wrtTag;
                  sign <= `SignEx;
                end
                `LW: begin
                  LSRW <= `Read;
                  LSlen <= 2'b11;
                  Sdata <= `dataFree;
                  LSROBname <= wrtName;
                  LSROBtag <= wrtTag;
                  sign <= `SignEx;
                end
                `LBU: begin
                  LSRW <= `Read;
                  LSlen <= 2'b00;
                  Sdata <= `dataFree;
                  LSROBname <= wrtName;
                  LSROBtag <= wrtTag;
                  sign <= `UnsignEx;
                end
                `LHU: begin
                  LSRW <= `Read;
                  LSlen <= 2'b01;
                  Sdata <= `dataFree;
                  LSROBname <= wrtName;
                  LSROBtag <= wrtTag;
                  sign <= `UnsignEx;
                end
                `SB: begin
                  LSRW <= `Write;
                  LSlen <= 2'b00;
                  Sdata <= operandT;
                  LSROBname <= `nameFree;
                  LSROBtag <= `tagFree;
                  sign <= `SignEx;
                end
                `SH: begin
                  LSRW <= `Write;
                  LSlen <= 2'b01;
                  Sdata <= operandT;
                  LSROBname <= `nameFree;
                  LSROBtag <= `tagFree;
                  sign <= `SignEx;
                end
                `SW: begin
                  LSRW <= `Write;
                  LSlen <= 2'b11;
                  Sdata <= operandT;
                  LSROBname <= `nameFree;
                  LSROBtag <= `tagFree;
                  sign <= `SignEx;
                end
              endcase
            end else begin
              dataEn <= `Disable;
              LSRW <= `Read;
              dataAddr <= `addrFree;
              LSlen <= 2'b00;
              Sdata <= `dataFree;
              LSROBen <= `Disable;
              LSROBdata <= `dataFree;
              LSROBtag <= `tagFree;
              LSROBname <= `nameFree;
            end
          end
          `NotFree: begin
            dataEn <= `Disable;
            if (LSoutEn == `Enable) begin
              LSRW <= `Read;
              LSROBen <= (LSRW == `Read) ? `Enable : `Disable;
              status <= `IsFree;
              LSlen <= 2'b00;
              Sdata <= `dataFree;
              dataAddr <= `addrFree;
              if (sign == `SignEx) begin
                case (LSlen)
                  2'b00: LSROBdata <= {{24{Ldata[7]}}, Ldata[7:0]};
                  2'b01: LSROBdata <= {{16{Ldata[15]}}, Ldata[15:0]};
                  2'b11: LSROBdata <= Ldata;
                endcase
              end else begin
                case (LSlen)
                  2'b00: LSROBdata <= {{24{1'b0}}, Ldata[7:0]};
                  2'b01: LSROBdata <= {{16{1'b0}}, Ldata[7:0]};
                  2'b11: LSROBdata <= Ldata;
                endcase
              end
            end
          end
        endcase
      end
    end
endmodule