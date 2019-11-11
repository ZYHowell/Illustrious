`include "defines.v";
//maybe for all rs, i need to add a "next data" and "next tag" to prevent some problems waiting to improve.
module BranchRS(
    input rst, 
    input clk, 
    //input from CDB
    input wire             enCDBwrt, 
    input wire[`TagBus]    CDBTag, 
    input wire[`DataBus]   CDBData, 
    //input from dispatcher
    input wire BranchEn, 
    input wire[`DataBus]        BranchOperandO, 
    input wire[`DataBus]        BranchOperandT, 
    input wire[`TagBus]         BranchTagO, 
    input wire[`TagBus]         BranchTagT, 
    input wire[`OpBus]          BranchOp, 
    input wire[`DataBus]        BranchImm, 
    input wire[`InstAddrBus]    BranchPC
    //to branchEx
    output reg BranchWorkEn, 
    output reg[`DataBus]        operandO, 
    output reg[`DataBus]        operandT, 
    output reg[`DataBus]        imm, 
    output reg[`OpBus]          opCode, 
    output reg[`InstAddrBus]    PC, 
    //to dispatcher
    output wire[`rsSize - 1 : 0] BranchFreeStatus
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
    reg [`InstAddrBus]  rsPC[`rsSize - 1:0];

    assign issueRS = ready & -ready;
    
    assign BranchFreeStatus = empty;

    integer i;

    //check readyState and issue
    always @ (*) begin
        if (rst) begin
          empty <= {`rsSize{1'b1}};
          ready <= {`rsSize{1'b0}};
        end else begin
          for (i = 1; i < `rsSize;i = i + 1) begin
            empty[i] = rsOp[i] == `NOP;
            ready[i] = !empty[i] && rsTagO[i] == `freeTag && rsTagT[i] == `freeTag;
          end
        end
    end

    //receive boardcast from CDB
    always @ (negedge clk) begin
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
    end

    //push inst to RS, each tag can be assigned to an RS
    always @ (posedge clk) begin
      if (BranchEn) begin
        rsOp[rsTagW]    <= BranchOp;
        rsDataO[rsTagW] <= BranchOperandO;
        rsDataT[rsTagW] <= BranchOperandT;
        rsTagO[rsTagW]  <= BranchTagO;
        rsTagT[rsTagW]  <= BranchTagT;
        rsPC[rsTagW]    <= BranchPC;
      end
    end

    always @ (posedge clk) begin
      for (i = 0;i < rsSize; i = i + 1) begin
        if (issueRS == 1'b1 << (i - 1)) begin
          BranchWorkEn <= `Enable;
          operandO <= rsDataO[i];
          operandT <= rsDataT[i];
          imm <= rsImm[i];
          opCode <= rsOp[i];
          PC <= rsPC[i];
        end
      end
    end
endmodule