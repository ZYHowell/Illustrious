`include "defines.v"

module Regfile(
    input wire clk, 
    input wire rst, 
    //ALU is actually from the ROB. 
    input wire ALUwrtEn, 
    input wire [`NameBus] ALUwrtName, 
    input wire [`TagBus] ALUwrtTag,
    input wire [`DataBus] ALUwrtData, 

    input wire LSwrtEn, 
    input wire [`NameBus] LSwrtName,
    input wire [`TagBus] LSwrtTag,
    input wire [`DataBus] LSwrtData,
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

    wire ALUtagClear, LStagClear, ALUwrtCover, LSwrtCover;
    assign ALUtagClear  = ALUwrtEn & (ALUwrtTag == tag[ALUwrtName]);
    assign LStagClear   = LSwrtEn  & (LSwrtTag  == tag[LSwrtName]);
    assign ALUwrtCover  = ((ALUwrtName == wrtNameDec) & enWrtDec);
    assign LSwrtCover   = ((LSwrtName  == wrtNameDec) & enWrtDec);

    integer i;
    //change tags and datas
    always @ (posedge clk) begin
      if (rst == `Enable) begin
        for (i = 0;i < `regSize;i = i + 1) begin
          tag[i] <= `tagFree;
          data[i] <= `dataFree;
        end
      end else begin
        // if (enCDBWrt == `Enable) begin
        //   if (CDBwrtName) begin
        //     data[CDBwrtName] <= CDBwrtData;
        //     if (CDBwrtTag == tag[CDBwrtName] && CDBwrtTag != wrtTagDec) 
        //       tag[CDBwrtName] <= `tagFree;
        //   end
        // end
        if (ALUtagClear & ~ALUwrtCover) begin
          data[ALUwrtName] <= ALUwrtData;
          tag[ALUwrtName] <= `tagFree;
        end
        if (LStagClear & ~LSwrtCover) begin
          data[LSwrtName] <=LSwrtData;
          tag[LSwrtName] <= `tagFree;
        end
        
        if (enWrtDec && wrtNameDec) 
          tag[wrtNameDec] <= wrtTagDec;
      end
    end

    //reg1
    always @ (*) begin
      if ((rst == `Enable) | (!regNameO)) begin
        regDataO = `dataFree;
        regTagO = `tagFree; 
      end else begin
        regDataO = ((ALUwrtName == regNameO) && ALUtagClear) ? ALUwrtData : 
                   ((LSwrtName == regNameO) && LStagClear) ? LSwrtData : data[regNameO];
        regTagO = ((ALUwrtName == regNameO) && ALUtagClear) ? `tagFree : 
                  ((LSwrtName == regNameO) && LStagClear) ? `tagFree : tag[regNameO];
      end
    end

    //reg2
    always @ (*) begin
      if ((rst == `Enable) | (!regNameT)) begin
        regDataT = `dataFree;
        regTagT = `tagFree;
      end else begin
        regDataT = ((ALUwrtName == regNameT) && ALUtagClear) ? ALUwrtData : 
                    ((LSwrtName == regNameT) && LStagClear) ? LSwrtData : data[regNameT];
        regTagT = ((ALUwrtName == regNameT) && ALUtagClear) ? `tagFree : 
                  ((LSwrtName == regNameT) && LStagClear) ? `tagFree : tag[regNameT];
      end
    end
endmodule 