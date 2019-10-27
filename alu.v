`include "defines.v"

module ALU(
    input wire clk, 
    input wire rst, 
    //from CDB
    input wire[`TagBus] CDBTag, 
    input wire[`DataBus] CDBData, 
    //from decoder
    input wire[`DataBus] operandO, 
    input wire[`DataBus] operandT, 
    input wire[`TagBus] DecTag

)
    reg [`rsSize - 1 : 0] ready;
    reg [`rsSize - 1 : 0] empty;
    reg [`DataBus] rsDataO[`rsSize - 1:0];
    reg [`DataBus] rsDataT[`rsSize - 1:0];
    reg [`TagBus] rsTagO[`rsSize - 1:0];
    reg [`TagBus] rsTagT[`rsSize - 1:0];
    reg [`OpBus] rsOp[`rsSize - 1:0];

    integer i;
    //deal with rst
    always @ (posedge rst) begin
      
    end
    //check readyState and issue
    always @ (*) begin
      for (i = 1; i < rsSize;i = i + 1) begin
        empty[i] = rsOp[i] == `NOP;
        ready[i] = !empty[i] && rsTagO[i] == freeTag && rsTagT[i] == freeTag;
      end
    end

    //receive boardcast from CDB
    always @ (negedge clk) begin
      if (CDBTag != tagFree) begin
        for (i = 0;i < rsSize;i = i + 1) begin
          if (rsTagO[i] == cdbtag) begin
            rsTagO[i] = `tagFree;
            rsDataO[i] = CDBData;
          end
          if (rsTagT[i] == CDBTag) begin
            rsTagT[i] = `tagFree;
            rsDataT[i] = CDBData;
          end
        end
      end
    end

    //push inst to RS.
    always @ (posedge ckl) begin
      r
    end

    //execute

endmodule