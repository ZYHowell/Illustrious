//`include "defines.v"

module Regfile(
    input wire clk, 
    input wire rst, 
    // //from CDB
    // input wire enCDBWrt, 
    // input wire [`NameBus]   CDBwrtName, 
    // input wire [`DataBus]   CDBwrtData, 
    // input wire [`TagBus]    CDBwrtTag, 
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
        if ((ALUwrtEn == `Enable) && ALUwrtName) begin
          data[ALUwrtName] <= ALUwrtData;
          if (ALUwrtTag == tag[ALUwrtName] && ((ALUwrtName != wrtNameDec) | ~enWrtDec))
            tag[ALUwrtName] <= `tagFree;
        end
        if ((LSwrtEn == `Enable) && LSwrtName) begin
          data[LSwrtName] <= LSwrtData;
          if (LSwrtTag == tag[LSwrtName] && ((LSwrtName != wrtNameDec) | ~enWrtDec))
            tag[LSwrtName] <= `tagFree;
        end
        
        if (enWrtDec == `Enable) 
          tag[wrtNameDec] <= wrtTagDec;
      end
    end

    //reg1
    always @ (*) begin
      if ((rst == `Enable) | (!regNameO)) begin
        regDataO = `dataFree;
        regTagO = `tagFree; 
      end else begin
        regDataO = (ALUwrtEn && ALUwrtName == regNameO) ? ALUwrtData : 
                   (LSwrtEn && LSwrtName == regNameO) ? LSwrtData : 
                   data[regNameO];
        regTagO = (ALUwrtEn && ALUwrtName == regNameO) ? ALUwrtTag : 
                  (LSwrtEn && LSwrtName == regNameO) ? LSwrtTag : 
                  tag[regNameO];
      end
    end

    //reg2
    always @ (*) begin
      if ((rst == `Enable) | (!regNameT)) begin
        regDataT = `dataFree;
        regTagT = `tagFree;
      end else begin
        regDataT = (ALUwrtEn && ALUwrtName == regNameT) ? ALUwrtData : 
                   (LSwrtEn && LSwrtName == regNameT) ? LSwrtData : 
                   data[regNameT];
        regTagT = (ALUwrtEn && ALUwrtName == regNameT) ? ALUwrtTag : 
                  (LSwrtEn && LSwrtName == regNameT) ? LSwrtTag : 
                  tag[regNameT];
      end
    end
endmodule 