`include "defines.v"

module Regfile(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    //from the ROB. 
    input wire wrtEn, 
    input wire [`NameBus] wrtName, 
    input wire [`TagBus] wrtTag,
    input wire [`DataBus] wrtData, 
    //from decoder
    input wire [`NameBus]   regNameO, 
    input wire [`NameBus]   regNameT, 
    //from dispatcher
    input wire enWrtDec, 
    input wire [`TagBus]    wrtTagDec, 
    input wire [`NameBus]   wrtNameDec, 

    output reg [`DataBus]   regDataO, 
    output reg [`TagBus]    regTagO, 
    output reg [`DataBus]   regDataT, 
    output reg [`TagBus]    regTagT
);
    reg [`DataBus] data[`regSize - 1 : 0];
    reg [`TagBus] tag[`regSize - 1 : 0];

    wire tagClear, wrtCover;
    assign tagClear  = wrtEn & (wrtTag == tag[wrtName]);
    assign wrtCover  = ((wrtName == wrtNameDec) & enWrtDec);

    integer i;
    //change tags and datas
    always @ (posedge clk) begin
      if (rst) begin
        for (i = 0;i < `regSize;i = i + 1) begin
          tag[i] <= `tagFree;
          data[i] <= `dataFree;
        end
      end else if (rdy) begin
        if (tagClear & ~wrtCover) begin
          data[wrtName] <= wrtData;
          tag[wrtName] <= `tagFree;
        end
        if (enWrtDec) 
          tag[wrtNameDec] <= wrtTagDec;
      end
    end

    //reg1
    always @ (*) begin
      if (rst | (!regNameO)) begin
        regDataO = `dataFree;
        regTagO = `tagFree; 
      end else begin
        regDataO = ((wrtName == regNameO) && tagClear) ? wrtData : data[regNameO];
        regTagO = ((wrtName == regNameO) && tagClear) ? `tagFree : tag[regNameO];
      end
    end

    //reg2
    always @ (*) begin
      if (rst | (!regNameT)) begin
        regDataT = `dataFree;
        regTagT = `tagFree;
      end else begin
        regDataT = ((wrtName == regNameT) && tagClear) ? wrtData : data[regNameT];
        regTagT = ((wrtName == regNameT) && tagClear) ? `tagFree : tag[regNameT];
      end
    end
endmodule 