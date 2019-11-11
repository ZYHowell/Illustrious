`include "defines.v"
//caution! not test if Status == 0
module ALUrs(
    input rst,
    input clk,
    //from CDB
    input wire             enCDBwrt, 
    input wire[`TagBus]    CDBTag, 
    input wire[`DataBus]   CDBData
    
    //from dispatcher
    input wire              ALUen, 
    input wire[`DataBus]    ALUOperandO, 
    input wire[`DataBus]    ALUoperandO, 
    input wire[`TagBus]     ALUtagO, 
    input wire[`TagBus]     ALUtagT,
    input wire[`TagBus]     ALUtagW,
    input wire[`NameBus]    ALUnameW,  
    input wire[`OpBus]      DecOpCode, 

    //to ALU
    output reg ALUworkEn, 
    output reg[`DataBus]    operandO, 
    output reg[`DataBus]    operandT,
    output reg[`TagBus]     wrtTag, 
    output reg[`NameBus]    wrtName, 
    output reg[`OpBus]      opCode, 
    //to dispatcher
    output wire[`rsSize - 1 : 0] ALUfreeStatus
);

    reg [`rsSize - 1 : 0] ready;
    reg [`rsSize - 1 : 0] empty;

    wire [`rsSize - 1 : 0] issueRS;

    reg [`DataBus]  rsDataO[`rsSize - 1:0];
    reg [`DataBus]  rsDataT[`rsSize - 1:0];
    reg [`TagBus]   rsTagO[`rsSize - 1:0];
    reg [`TagBus]   rsTagT[`rsSize - 1:0];
    reg [`OpBus]    rsOp[`rsSize - 1:0];
    reg [`TagBus]   rsNameW[`rsSize - 1:0];

    assign issueRS = ready & -ready;

    assign ALUfreeStatus = empty;

    integer i;
    //deal with rst
    always @ (posedge rst) begin
        empty <= {`rsSize{1'b1}};
        ready <= {`rsSize{1'b0}};
    end

    //check readyState and issue
    always @ (*) begin
        for (i = 1; i < `rsSize;i = i + 1) begin
            empty[i] = rsOp[i] == `NOP;
            ready[i] = !empty[i] && rsTagO[i] == `freeTag && rsTagT[i] == `freeTag;
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
      if (ALUen) begin
        rsOp[rsTagW]    <= DecOpCode;
        rsDataO[rsTagW] <= DecOperandO;
        rsDataT[rsTagW] <= DecOperandT;
        rsTagO[rsTagW]  <= DecOpTagO;
        rsTagT[rsTagW]  <= DecOpTagT;
        rsNameW[rsTagW] <= DecWrtTag;
      end
    end

    always @ (posedge clk) begin
        for (i = 0;i < rsSize;i = i + 1) begin
            if (issueRS == 1'b1 << (i - 1)) begin
                ALUworkEn <= `Enable;
                operandO <= rsDataO[i];
                operandT <= rsDataT[i];
                opCode <= rsOp[i];
                wrtName <= rsNameW[i];
                wrtTag <= i;
            end
        end
    end
endmodule