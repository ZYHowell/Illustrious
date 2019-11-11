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
        if (rst) begin

            for (i = 0;i < regSize;i = i + 1) begin
                tag[i] = `tagFree;
            end

        end else begin
            if (enCDBWrt) begin
                if (CDBwrtName) begin
                    data[CDBwrtName] <= CDBwrtData;
                    if (CDBwrtTag == tag[CDBwrtName] && CDBwrtTag != wrtTagDec) begin
                        tag[CDBwrtName] <= `tagFree;
                    end
                end
            end

            if (enWrtDec) begin
                tag[wrtNameDec] <= wrtTagDec;
            end
        end
    end

    //reg1
    always @ (*) begin
      if (rst) begin
        

      end else if (enWrt && wrtName == regNameO) begin
          regDataO <= wrtData;
          regTagO <= `tagFree;
      end else begin
          regDataO <= data[regNameO];
          regTagO <= tag[regNameO];
      end
    end

    //reg2
    always @ (*) begin
        if (rst) begin
          

        end else if (enWrt && wrtName == regNameT) begin
            regDataT <= wrtData;
            regTagT <= `tagFree;
        end else begin
            regDataT <= data[regNameT];
            regTagT <= tag[regNameT];
        end
    end
endmodule 