`include "defines.v"

module Regfile(
    input wire clk, 
    input wire rst, 

    input wire enWrt, 
    input wire [`NameBus] wrtName, 
    input wire [`DataBus] wrtData, 
    input wire [`TagBus] wrtTag, 

    input wire [`NameBus] rdNameO, 
    output wire [`DataBus] rdDataO, 
    output wire [`TagBus] rdTagO, 

    input wire [`NameBus] rdNameT, 
    output wire [`DataBus] rdDataT, 
    output wire [`TagBus] rdTagT, 

    input wire enWrtDec, 
    input wire [`TagBus] wrtTagDec, 
    input wire [`NameBus] wrtNameDec
)
    reg [`regSize - 1 : 0] data[`DataBus];
    reg [`regSize - 1 : 0] tag[`TagBus];

    integer i;

    always @ (posedge clk) begin
      if (rst) begin

        for (i = 0;i < regSize;i = i + 1) begin
          tag[i] = `tagFree;
        end

      end else begin
        if (enWrt) begin
          if (wrtName) begin
            data[wrtName] <= wrtData;
            if (wrtTag == tag[wrtName]) begin
              tag[wrtName] <= `tagFree;
            end
          end
        end

        if (enWrtDec) begin
          tag[wrtNameDec] <= wrtTagDec;
        end
      end
    end

    always @ (*) begin
      if (rst) begin
        

      end else if (enWrt && wrtName == rdNameO) begin
        rdDataO <= wrtData;
        rdTagO <= wrtTag;
      end else begin
        rdDataO <= data[rdNameO];
        rdTagO <= tag[rdNameO];
      end
    end

    always @ (*) begin
      if (rst) begin
        

      end else if (enWrt && wrtName == rdNameT) begin
        rdDataT <= wrtData;
        rdTagT <= wrtTag;
      end else begin
        rdDataT <= data[rdNameT];
        rdTagT <= tag[rdNameT];
      end
    end
endmodule 