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
    input wire[`OpBus]      DecopCode, 

    //to ALU
    output wire[`DataBus]   operandO, 
    output wire[`DataBus]   operandT,
    output wire[`TagBus]    wrtTag, 
    output wire[`NameBus]   wrtName, 
    output wire[`OpBus]     opCode, 
    //to dispatcher
    output wire[`rsSize - 1 : 0] ALUfreeStatus
);

    reg [`rsSize - 1 : 0] ready;
    reg [`rsSize - 1 : 0] empty;

    wire [`rsSize - 1 : 0] freeRS;
    wire [`rsSize - 1 : 0] issueRS;

    reg [`DataBus]  rsDataO[`rsSize - 1:0];
    reg [`DataBus]  rsDataT[`rsSize - 1:0];
    reg [`TagBus]   rsTagO[`rsSize - 1:0];
    reg [`TagBus]   rsTagT[`rsSize - 1:0];
    reg [`OpBus]    rsOp[`rsSize - 1:0];
    reg [`TagBus]   rsTagW[`rsSize - 1:0];

    assign freeRS = empty & -empty;
    assign issueRS = ready & -ready;

    assign ALUfreeStatus = freeRS;

    integer i;
    //deal with rst
    always @ (posedge rst) begin

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
        if (CDBTag != `tagFree) begin
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

    //push inst to RS, by freeRS.
    always @ (posedge clk) begin
        for (i = 0;i < `rsSize;i = i + 1) begin
            if (freeRS == `IsFree << (i - 1)) begin
                rsOp[i] <= DecopCode;
                rsDataO[i] <= DecOperandO;
                rsDataT[i] <= DecOperandT;
                rsTagO[i] <= DecOpTagO;
                rsTagT[i] <= DecOpTagT;
                rsTagW[i] <= DecWrtTag;
            end
        end
    end

    always @ (posedge clk) begin
        for (i = 0;i < rsSize;i = i + 1) begin
            if (readyRS == 1'b1 << (i - 1)) begin
                operandO <= rsDataO[i];
                operandT <= rsDataT[i];
                opCode <= rsOp[i];
                wrtTag <= rsTagW[i];
            end
        end
    end
endmodule