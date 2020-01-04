//this is a dcache with write back policy. but it costs 12% LUT dispite it has only 64 entries. 
`include "defines.v"

module dcache(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    input wire LSen, 
    input wire LSRW, 
    input wire[`AddrBus] Addr, 
    input wire[2:0] LSlen, 
    input wire[`DataBus] Sdata,

    input wire memDone, 
    input wire[`DataBus]  memLdData, 

    output reg done, 
    output reg [`DataBus]  LdData, 

    output reg memLSen, 
    output reg memLSRW, 
    output reg[2:0] memLSlen, 
    output reg[`DataBus] memSdata, 
    output reg[`InstAddrBus] memLSAddr
);
    localparam TagLen = 10;
    localparam IndexLen = 6;
    localparam CacheSize = 64;
    reg[`DataBus]   memData[CacheSize - 1 : 0];
    reg[TagLen - 1 : 0] memTag[CacheSize - 1 : 0];
    reg[CacheSize - 1 : 0] memValid;
    reg[CacheSize - 1 : 0] memDirty;

    wire[IndexLen - 1 : 0] index;
    wire[TagLen - 1 : 0]  tag;
    wire hit;
    reg[`DataBus] otData;
    reg[`DataBus] wrtData;

    assign tag = Addr[17 : 8];
    assign index = Addr[7 : 2];

    assign hit = (memTag[index] == tag) & (memValid[index]);

    reg IsLoad; 
    wire IsWord, DoMore;
    assign DoMore = IsLoad & IsWord & memDirty[index];
    assign IsWord = (LSlen + LSRW == 3'b100) && Addr[17:16] != 2'b11;
    always @(*) begin
      otData = memData[index];
    end
    always @(*) begin
      wrtData = memData[index];
      case(LSlen)
        3'b000:begin
          case(Addr[1:0])
          2'b00:wrtData[7:0] = Sdata[7:0];
          2'b01:wrtData[15:8] = Sdata[7:0];
          2'b10:wrtData[23:16] = Sdata[7:0];
          2'b11:wrtData[31:24] = Sdata[7:0];
          endcase
        end
        3'b001:begin
          case(Addr[1:0])
          2'b00:wrtData[15:0] = Sdata[15:0];
          2'b01:wrtData[23:8] = Sdata[15:0];
          2'b10:wrtData[31:16] = Sdata[15:0];
          endcase
        end
        3'b011:wrtData = Sdata;
      endcase
    end

    //the one is load or not
    always @(posedge clk) begin
      if (rst) begin
        IsLoad <= 0;
      end else if (rdy) begin
        if (LSen) IsLoad <= ~LSRW;
        else if (memDone && DoMore) IsLoad <= 0;
      end
    end
    //done or not
    always @(posedge clk) begin
      if (rst) begin
        done <= 0;
        LdData <= 0;
      end else if (rdy) begin
        if (LSen) begin
          if (hit || (LSRW && !memDirty[index] && IsWord)) begin
            done <= 1;
            case(LSlen)
              3'b001:begin
                case(Addr[1:0])
                2'b00:LdData <= otData[7:0];
                2'b01:LdData <= otData[15:8];
                2'b10:LdData <= otData[23:16];
                2'b11:LdData <= otData[31:24];
                endcase
              end
              3'b010:begin
                case(Addr[1:0])
                2'b00:LdData <= otData[15:0];
                2'b01:LdData <= otData[23:8];
                2'b10:LdData <= otData[31:16];
                endcase
              end
              3'b100:LdData <= otData;
              default:LdData <= `dataFree;
            endcase
          end 
        end else if (memDone) begin
          if (IsLoad) LdData <= memLdData;
          done <= ~DoMore;
        end else done <= 0;
      end
    end

    always @(posedge clk) begin
      if (rst) begin
        memLSen <= `Disable;
      end else if (rdy) begin
        if (LSen & ~hit) begin
          memLSen <= !(LSRW && ~memDirty[index] && IsWord);
          memLSRW <= LSRW;
          memLSlen <= LSlen;
          if (IsWord & LSRW) begin
            memSdata <= otData;
            memLSAddr <= {memTag[index], index, 2'b00};
          end else begin
            memSdata <= Sdata;
            memLSAddr <= Addr;
          end
        end else if (memDone & DoMore) begin
          memLSen <= `Enable;
          memLSRW <= `Write;
          memLSlen <= 3'b011;
          memSdata <= otData;
          memLSAddr <= {memTag[index], index, 2'b00};
        end else begin
          memLSen <= `Disable;
        end
      end
    end
    

    //add to cache
    integer i;
    always @(posedge clk) begin
      if (rst) begin
        memValid <= 0;
        memDirty <= 0;
      end else if (rdy) begin
        if (memDone & IsWord & IsLoad) begin
          memValid[index] <= `Valid;
          memDirty[index] <= 0;
          memTag[index] <= tag;
          memData[index] <= memLdData;
        end
        if (LSen & LSRW & (hit | IsWord)) begin
          memValid[index] <= `Valid;
          memDirty[index] <= 1;
          memTag[index] <= tag;
          memData[index] <= wrtData;
        end
      end
    end
    
endmodule