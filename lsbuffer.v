`include "defines.v"
module lsBuffer(
    input rst, 
    input clk, 
    //input from CDB
    input wire             enCDBwrt, 
    input wire[`TagBus]    CDBTag, 
    input wire[`DataBus]   CDBData, 
    //input from dispatcher
    input wire LSen, 
    input wire[`DataBus]        LSoperandO, 
    input wire[`DataBus]        LSoperandT, 
    input wire[`TagBus]         LStagO, 
    input wire[`TagBus]         LStagT, 
    input wire[`TagBus]         LStagW, 
    input wire[`NameBus]        LSnameW, 
    input wire[`OpBus]          LSop, 
    input wire[`DataBus]        LSimm, 
    //from the LS
    input wire LSreadEn, 
    //to branchEx
    output reg LSworkEn, 
    output reg[`DataBus]        operandO, 
    output reg[`DataBus]        operandT,
    output reg[`DataBus]        imm, 
    output reg[`TagBus]         wrtTag, 
    output reg[`NameBus]        wrtName, 
    output reg[`OpBus]          opCode, 
    //to dispatcher
    output wire[`rsSize - 1 : 0] LSfreeStatus
);
    reg [`rsSize - 1 : 0] ready;
    reg [`rsSize - 1 : 0] empty;

    wire [`rsSize - 1 : 0] issueRS;

    reg [`DataBus]      rsDataO[`rsSize - 1:0];
    reg [`DataBus]      rsDataT[`rsSize - 1:0];
    reg [`TagBus]       rsTagO[`rsSize - 1:0];
    reg [`TagBus]       rsTagT[`rsSize - 1:0];
    reg [`OpBus]        rsOp[`rsSize - 1:0];
    reg [`DataBus]      rsImm[`rsSize - 1:0];
    reg [`NameBus]      rsNameW[`rsSize - 1:0];

    assign issueRS = ready & -ready;
    
    assign LSfreeStatus = empty;

    integer i;
    //deal with rst
    always @ (*) begin
      if (rst == `Enable) begin
        empty = {`rsSize{1'b1}};
        ready = {`rsSize{1'b0}};
      end else begin
        for (i = 0;i < `rsSize;i = i + 1) begin
          empty[i] = rsOp[i] == `NOP;
          ready[i] = !empty[i] && rsTagO[i] == `tagFree && rsTagT[i] == `tagFree;
        end
      end
    end 

    //receive boardcast from CDB
    always @ (negedge clk or posedge rst) begin
      if (rst == `Disable) begin
        if (CDBTag != `tagFree && enCDBwrt) begin
          for (i = 0;i < `rsSize;i = i + 1) begin
            if (!empty[i] && rsTagO[i] == CDBTag) begin
              rsTagO[i] <= `tagFree;
              rsDataO[i] <= CDBData;
            end
            if (!empty[i] && rsTagT[i] == CDBTag) begin
              rsTagT[i] <= `tagFree;
              rsDataT[i] <= CDBData;
            end
          end
        end
      end else begin
        for (i = 0;i < `rsSize;i = i + 1) begin
          rsTagO[i] <= `tagFree;
          rsDataO[i] <= `dataFree;
          rsTagT[i] <= `tagFree;
          rsDataT[i] <= `dataFree;
          rsOp[i] <= `NOP;
          rsNameW[i] <= `nameFree;
          rsImm[i] <= `dataFree;
        end
      end
    end

    //push inst to RS, each tag can be assigned to an RS
    always @ (posedge clk) begin
      if (rst == `Disable) begin
        if (LSen) begin
          rsOp[rsTagW[`TagRootBus]]     <= LSop;
          rsDataO[rsTagW[`TagRootBus]]  <= LSoperandO;
          rsDataT[rsTagW[`TagRootBus]]  <= LSoperandT;
          rsTagO[rsTagW[`TagRootBus]]   <= LStagO;
          rsTagT[rsTagW[`TagRootBus]]   <= LStagT;
          rsNameW[rsTagW[`TagRootBus]]  <= LSnameW;
          rsImm[rsTagW[`TagRootBus]]    <= LSimm;
        end
      end
    end

    always @ (posedge clk) begin
      if (rst == `Disable && LSreadEn == `Enable) begin
        for (i = 0;i < rsSize;i = i + 1) begin
          if (issueRS == 1'b1 << (i - 1)) begin
            LSworkEn <= `Enable;
            operandO <= rsDataO[i];
            operandT <= rsDataT[i];
            opCode <= rsOp[i];
            wrtName <= rsNameW[i];
            wrtTag <= {`LStagPrefix, i};
            imm <= rsImm[i];
          end
        end
      end else begin
        LSworkEn <= `Disable;
        operandO <= `dataFree;
        operandT <= `dataFree;
        opCode <= `NOP;
        wrtName <= `nameFree;
        wrtTag <= `tagFree;
        imm <= `dataFree;
      end
    end
endmodule