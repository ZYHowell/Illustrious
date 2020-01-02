`include "defines.v"
module icache(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    input wire fetchEn, 
    input wire[`AddrBus]  Addr, 
    input wire addEn, 
    input wire[`DataBus]  addInst,
    input wire[`AddrBus]  addAddr, 

    output wire hit, 
    output wire [`DataBus]  foundInst, 

    output wire memfetchEn, 
    output wire[`InstAddrBus] memfetchAddr
);
    reg[`DataBus]   memInst[`memCacheSize - 1 : 0];
    reg[`memTagBus] memTag[`memCacheSize - 1:0];
    reg[`memCacheSize - 1 : 0] memValid;

    wire [`memTagBus]   tag;
    wire [`memIndexBus] index;
    assign tag    = Addr[`memAddrTagBus];
    assign index  = Addr[`memAddrIndexBus];

    assign hit = fetchEn & (memTag[index] == tag) & (memValid[index]);
    assign foundInst = memInst[index];
    
    assign memfetchEn = ~hit & fetchEn;
    assign memfetchAddr = Addr;

    always @ (posedge clk) begin
      if (rst) begin
        memValid <= `Invalid;
      end else if (addEn && rdy) begin
        memInst[addAddr[`memAddrIndexBus]]  <= addInst;
        memTag[addAddr[`memAddrIndexBus]]   <= addAddr[`memAddrTagBus];
        memValid[addAddr[`memAddrIndexBus]] <= `Valid;
      end
    end
endmodule