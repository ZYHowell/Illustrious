`include "defines.v"
//caution! not test if Status == 0
//CAUTION! there is a mistake that the input tagW has a prefix(ALU prefix)
module ALUrs(
    input rst,
    input clk,
    //from CDB
    input wire enCDBwrt, 
    input wire[`TagBus]    CDBTag, 
    input wire[`DataBus]   CDBData, 
    
    //from dispatcher
    input wire ALUen, 
    input wire[`DataBus]    ALUoperandO, 
    input wire[`DataBus]    ALUoperandT, 
    input wire[`TagBus]     ALUtagO, 
    input wire[`TagBus]     ALUtagT,
    input wire[`TagBus]     ALUtagW,
    input wire[`NameBus]    ALUnameW,  
    input wire[`OpBus]      ALUop, 
    input wire[`InstAddrBus]ALUaddr, 

    //to ALU
    output reg ALUworkEn, 
    output reg[`DataBus]    operandO, 
    output reg[`DataBus]    operandT,
    output reg[`TagBus]     wrtTag, 
    output reg[`NameBus]    wrtName, 
    output reg[`OpBus]      opCode, 
    output reg[`InstAddrBus]instAddr,
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
    reg [`InstAddrBus] rsPC[`rsSize - 1:0];

    assign issueRS = ready & -ready;

    assign ALUfreeStatus = empty;

    integer i;
    //check readyState and issue
    always @ (*) begin
      if (rst == `Enable) begin
        empty = {`rsSize{1'b1}};
        ready = {`rsSize{1'b0}};
      end else begin
        for (i = 1; i < `rsSize;i = i + 1) begin
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
          rsPC[i] <= `addrFree;
        end
      end
    end

    //push inst to RS, each tag can be assigned to an RS
    always @ (posedge clk) begin
      if (rst == `Disable) begin
        if (ALUen) begin
          rsOp[ALUtagW[`TagRootBus]]    <= ALUop;
          rsDataO[ALUtagW[`TagRootBus]] <= ALUoperandO;
          rsDataT[ALUtagW[`TagRootBus]] <= ALUoperandT;
          rsTagO[ALUtagW[`TagRootBus]]  <= ALUtagO;
          rsTagT[ALUtagW[`TagRootBus]]  <= ALUtagT;
          rsNameW[ALUtagW[`TagRootBus]] <= ALUnameW;
          rsPC[ALUtagW[`TagRootBus]]  <= ALUaddr;
        end
      end
    end

    always @ (posedge clk) begin
      if (rst == `Disable) begin
        for (i = 0;i < `rsSize;i = i + 1) begin
          if (issueRS == 1'b1 << (i - 1)) begin
            ALUworkEn <= `Enable;
            operandO <= rsDataO[i];
            operandT <= rsDataT[i];
            opCode <= rsOp[i];
            wrtName <= rsNameW[i];
            wrtTag <= {`ALUtagPrefix,i};
            instAddr <= rsPC[i];
          end
        end
      end else begin
        ALUworkEn <= `Disable;
        operandO <= `dataFree;
        operandT <= `dataFree;
        opCode <= `NOP;
        wrtName <= `nameFree;
        wrtTag <= `tagFree;
      end
    end
endmodule