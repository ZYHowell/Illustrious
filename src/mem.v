`include "defines.v"
//a 512B cache
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

    assign hit = fetchEn & (memTag[Addr[`memAddrIndexBus]] == Addr[`memAddrTagBus]) & (memValid[Addr[`memAddrIndexBus]]);
    assign foundInst = (hit & memValid[Addr[`memAddrIndexBus]]) ? (memInst[Addr[`memAddrIndexBus]]) : `dataFree;
    
    assign memfetchEn = hit ? `Disable : fetchEn;
    assign memfetchAddr = hit ? `addrFree : Addr;

    integer i;
    always @ (posedge clk or posedge rst) begin
      if (rst == `Enable) begin
        for (i = 0; i < `memCacheSize;i = i + 1) begin
          memInst[i] <= `dataFree;
          memTag[i] <= `memTagFree;
          memValid[i] <= `Invalid;
        end
      end else if ((addEn == `Enable) && (addAddr[17:16] != 2'b11) && rdy) begin
        memInst[addAddr[`memAddrIndexBus]] <= addInst;
        memTag[addAddr[`memAddrIndexBus]] <= addAddr[`memAddrTagBus];
        memValid[addAddr[`memAddrIndexBus]] <= `Valid;
      end
    end
endmodule

module mem(
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    //with icache and PC
    input wire fetchEn, 
    input wire[`InstAddrBus]    fetchAddr, 
    output reg instOutEn, 
    output reg[`InstBus]        inst, 
    output reg[`InstAddrBus]    addAddr, 
    //with LS
    input wire LSen, 
    input wire LSRW, //always 0 for read and 1 for write
    input wire[`DataAddrBus]    LSaddr,
    input wire[2:0]             LSlen, 
    input wire[`DataBus]        Sdata, 
      //is DataFree when it is read
    output reg LSdone, 
    output reg[`DataBus]        LdData, 
    //with ram
    output wire RWstate, 
    output wire[`AddrBus]        RWaddr, 
    input wire[`RAMBus]         ReadData, 
    output wire[`RAMBus]         WrtData
    //with cache
    //input wire iHit
);
    reg status;
    //0:free,1:working
    
    reg[1:0]        Waiting;
    reg[1:0]        WaitingRW;
    //Waiting[0]:inst, Waiting[1]:LS
    reg [`AddrBus]  WaitingAddr[1:0];
    reg [`LenBus]   WaitingLen[1:0];
    reg [`DataBus]  WaitingData;
    //only Save can put something here
    
    reg             RW;
    reg             Port;//0 for inst and 1 for LS
    reg [`LenBus]   stage;
    reg [`AddrBus]  AddrPlatform, addrToCache;
    reg [`RAMBus]   DataPlatformW[3:0];
    reg [`LenBus]   Lens;

    assign RWstate = RW;
    assign RWaddr = AddrPlatform;
    assign WrtData = DataPlatformW[stage];

    integer i;

    always @ (posedge clk) begin
      if (rst == `Enable) begin
        status <= `IsFree;
        for (i = 0;i < 2;i = i + 1) begin
          Waiting[i] <= `NotUsing;
          WaitingRW[i] <= `Read;
          WaitingAddr[i] <= `addrFree;
          WaitingLen[i] <= `ZeroLen;
        end
        WaitingData <= `dataFree;
        RW <= `Read;
        stage <= `ZeroLen;
        AddrPlatform <= `addrFree;
        for (i = 0;i < 4;i = i + 1)
          DataPlatformW[i] <= 8'h00;

        //output
        instOutEn <= `Disable;
        inst <= `dataFree;
        LSdone <= `Disable;
        LdData <= `dataFree;
        addrToCache <= `addrFree;
      end else if (rdy) begin
        instOutEn <= `Disable;
        LSdone <= `Disable;
        //input and fill in
        if (fetchEn) begin
          Waiting[`instPort] <= `IsUsing;
          WaitingAddr[`instPort] <= fetchAddr;
          WaitingRW[`instPort] <= `Read;
          WaitingLen[`instPort] <= `WordLen;
        end
        //input and fill in
        if (LSen) begin
          Waiting[`LSport] <= `IsUsing;
          WaitingAddr[`LSport] <= LSaddr;
          WaitingRW[`LSport] <= LSRW;
          WaitingData <= Sdata;
          WaitingLen[`LSport] <= LSlen;
        end

        case (status)
          `IsFree: begin
            /* 
             * A free state cannot come up with a waiting inst which is thrown in the past
             * if it is thrown when the state is free, it is handle there, 
             * if it is thrown when the state is busy, it waited but then the state cannot turn to free
             */
            if (LSen) begin
              RW <= LSRW;
              DataPlatformW[0] <= Sdata[7:0];
              DataPlatformW[1] <= Sdata[15:8];
              DataPlatformW[2] <= Sdata[23:16];
              DataPlatformW[3] <= Sdata[31:24];
              AddrPlatform <= LSaddr;
              Lens <= LSlen;
              stage <= `ZeroLen;
              status <= `NotFree;
              Port <= `LSport;

              Waiting[`LSport] <= `NotUsing;
            end else if (fetchEn)begin
              RW <= `Read;
              for (i = 0; i < 4;i = i + 1)
                DataPlatformW[i] <= 8'h00;
              addrToCache <= fetchAddr;
              AddrPlatform <= fetchAddr;
              Lens <= `WordLen;
              stage <= `ZeroLen;
              status <= `NotFree;
              Port <= `instPort;

              Waiting[`instPort] <= `NotUsing;
            end else begin
              status <= `IsFree;
              RW <= `Read;
            end
          end
          `NotFree: begin
            if (Port == `instPort) begin
              case (stage)
                3'b001: inst[7:0] <= ReadData;
                3'b010: inst[15:8] <= ReadData;
                3'b011: inst[23:16] <= ReadData;
                3'b100: inst[31:24] <= ReadData;
              endcase
            end else begin
              case (stage)
                3'b001: LdData[7:0] <= ReadData;
                3'b010: LdData[15:8] <= ReadData;
                3'b011: LdData[23:16] <= ReadData;
                3'b100: LdData[31:24] <= ReadData;
              endcase
            end
            if (stage == Lens) begin
              //the port not read should remains, instead of make it dataFree;
              instOutEn <= Port == `instPort;
              LSdone <= Port == `LSport;
              addAddr <= addrToCache;
              if (Waiting[`LSport]) begin
                RW <= WaitingRW[`LSport];
                DataPlatformW[0] <= WaitingData[7:0];
                DataPlatformW[1] <= WaitingData[15:8];
                DataPlatformW[2] <= WaitingData[23:16];
                DataPlatformW[3] <= WaitingData[31:24];
                AddrPlatform <= WaitingAddr[`LSport];
                Lens <= WaitingLen[`LSport];
                stage <= `ZeroLen;
                status <= `NotFree;
                Port <= `LSport;

                Waiting[`LSport] <= `NotUsing;
              end else if (Waiting[`instPort]) begin
                RW <= WaitingRW[`instPort];
                for (i = 0; i < 4;i = i + 1)
                  DataPlatformW[i] <= 8'h00;
                AddrPlatform <= WaitingAddr[`instPort];
                addrToCache <= WaitingAddr[`instPort];
                Lens <= WaitingLen[`instPort];
                stage <= `ZeroLen;
                status <= `NotFree;
                Port <= `instPort;

                Waiting[`instPort] <= `NotUsing;
              end else if (LSen) begin
                RW <= LSRW;
                DataPlatformW[0] <= Sdata[7:0];
                DataPlatformW[1] <= Sdata[15:8];
                DataPlatformW[2] <= Sdata[23:16];
                DataPlatformW[3] <= Sdata[31:24];
                AddrPlatform <= LSaddr;
                Lens <= LSlen;
                stage <= `ZeroLen;
                status <= `NotFree;
                Port <= `LSport;

                Waiting[`LSport] <= `NotUsing;
              end else if (fetchEn) begin
                RW <= `Read;
                for (i = 0; i < 4;i = i + 1)
                  DataPlatformW[i] <= 8'h00;
                AddrPlatform <= fetchAddr;
                addrToCache <= fetchAddr;
                Lens <= `WordLen;
                stage <= `ZeroLen;
                status <= `NotFree;
                Port <= `instPort;

                Waiting[`instPort] <= `NotUsing;
              end else begin
                stage <= `ZeroLen;
                status <= `IsFree;
                RW <= `Read;
              end
            end else begin
              stage <= stage + 1;
              AddrPlatform <= AddrPlatform + 1;
              status <= `NotFree;
            end
          end
        endcase
      end
    end
endmodule