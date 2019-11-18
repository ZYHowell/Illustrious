`include "defines.v"

module Regfile(
    input wire clk, 
    input wire rst, 
    //from CDB
    input wire enCDBWrt, 
    input wire [`NameBus]   CDBwrtName, 
    input wire [`DataBus]   CDBwrtData, 
    input wire [`TagBus]    CDBwrtTag, 
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
    reg [`regSize - 1 : 0] data[`DataBus];
    reg [`regSize - 1 : 0] tag[`TagBus];

    integer i;
    //change tags and datas
    always @ (posedge clk) begin
      if (rst == `Enable) begin
        for (i = 0;i < `regSize;i = i + 1) begin
          tag[i] = `tagFree;
          data[i] = `dataFree;
        end
      end else begin
        if (enCDBWrt == `Enable) begin
          if (CDBwrtName) begin
            data[CDBwrtName] <= CDBwrtData;
            if (CDBwrtTag == tag[CDBwrtName] && CDBwrtTag != wrtTagDec) 
              tag[CDBwrtName] <= `tagFree;
          end
        end

        if (enWrtDec == `Enable) tag[wrtNameDec] <= wrtTagDec;
      end
    end

    //reg1
    always @ (*) begin
      if (rst == `Enable) begin
        regDataO = `dataFree;
        regTagO = `tagFree; 
      end else if (enCDBWrt && CDBwrtName == regNameO) begin
        regDataO = CDBwrtData;
        regTagO = `tagFree;
      end else begin
        regDataO = data[regNameO];
        regTagO = tag[regNameO];
      end
    end

    //reg2
    always @ (*) begin
      if (rst == `Enable) begin
        regDataT = `dataFree;
        regTagT = `tagFree;
      end else if (enCDBWrt && CDBwrtName == regNameT) begin
        regDataT <= CDBwrtData;
        regTagT <= `tagFree;
      end else begin
        regDataT <= data[regNameT];
        regTagT <= tag[regNameT];
      end
    end
endmodule 