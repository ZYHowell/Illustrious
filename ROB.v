`include "defines.v"
//caution! not test if Status == 0
module ROB(
    input wire clk, 
    input wire rst, 
    //input from alu
    input wire              ROBenW, 
    input wire[`TagBus]     ROBtagW, 
    input wire[`DataBus]    ROBdataW, 
    input wire[`NameBus]    ROBnameW, 
    //output
    output reg enCDBWrt, 
    output reg[`NameBus]    CDBwrtName, 
    output reg[`TagBus]     CDBwrtTag, 
    output reg[`DataBus]    CDBwrtData
);
    reg [`DataBus] ROBdata[`ROBsize - 1 : 0];
    reg [`TagBus]  ROBtag[`ROBsize - 1 : 0];
    reg [`NameBus] ROBname[`ROBsize - 1 : 0];
    
    reg [`ROBsize - 1 : 0] freeStatus;
    wire [`ROBsize - 1 : 0] freeROB;

    reg [`ROBsize - 1 : 0] readyStatus;
    wire [`ROBsize - 1 : 0] readyROB;

    assign freeROB = freeStatus & (-freeStatus);
    assign readyROB = readyStatus & (-readyStatus);

    always @(*) begin
      if (ROBenW) begin
        for (i = 0; i < `ROBsize;i = i + 1) begin
          if (freeROB == 1'b1 << (i - 1)) begin
            ROBname[i] = ROBnameW;
            ROBtag[i] =ROBtagW;
            ROBdata[i] = ROBdataW;
          end
        end
      end
    end

    integer i;
    always @(*) begin
      for (i = 0;i < `ROBsize;i = i + 1) begin
        freeStatus[i] = ROBname[i] == `nameFree;
        readyStatus[i] = ROBname[i] ~= `nameFree;
        //readyStatus[i] = BranchTag[i] == `tagFree;
      end
    end

    always @(posedge clk or posedge rst) begin
      if (rst) begin
        enCDBWrt <= `WrtDisable;
        CDBwrtName <= `nameFree;
        CDBwrtTag <= `tagFree;
        CDBwrtData <= `dataFree;
      end
      else begin
        enCDBWrt <= `WrtEnable;
        for (i = 0;i < `ROBsize;i = i + 1) begin
          if (readyROB == 1'b1 << i) begin
            CDBwrtName <= ROBname[i];
            CDBwrtTag <= ROBtag[i];
            CDBwrtData <= ROBdata[i];
          end
        end
      end
    end


endmodule