// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "defines.v"

module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	  input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)

	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles(wait till next cycle), write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

    wire stall;
    //output of mem
    wire memInstWaiting, memLSwaiting;
    wire instEn;
    wire [`InstAddrBus] instAddr;
    wire instOutEn;
    wire [`InstBus] FetchInst;

    wire LSoutEn;
    wire [`DataBus] mcuLdata;

    //output of fetcher
    wire DecEn;
    wire [`InstAddrBus] ToDecAddr;
    wire [`InstBus] ToDecInst;

    //output of decoder
    wire [`NameBus] DecNameO, DecNameT, DecRdName;
    wire [`OpBus] DecOp;
    wire [`OpClassBus]  DecOpClass;
    wire [`InstAddrBus] DecAddr;
    wire [`DataBus] DecImm, DecUimm, DecJimm, DecSimm, DecBimm;
    
    wire [`BranchTagBus]  DecBranchTag;
    wire BranchFree;

    //output of Table
    wire [`TagRootBus]  freeTagALUroot;

    //output of dispatcher
    wire enRegWrt;
    wire [`NameBus] RegWrtName;
    wire [`TagBus]  RegWrtTag;

    wire ALUrsEn;
    wire [`DataBus] ALUrsOperandO, ALUrsOperandT;
    wire [`TagBus]  ALUrsTagO, ALUrsTagT, ALUrsTagW;
    wire [`NameBus] ALUrsNameW;
    wire [`OpBus]   ALUrsOp;
    wire [`InstAddrBus] ALUrsAddr;

    wire BranchRsEn;
    wire [`DataBus] BranchRsOperandO, BranchRsOperandT, BranchRsImm;
    wire [`TagBus]  BranchRsTagO, BranchRsTagT;
    wire [`OpBus]   BranchRsOp;
    wire [`InstAddrBus] BranchRsAddr;

    wire LSbufEn;
    wire [`DataBus] LSbufOperandO, LSbufOperandT, LSbufImm;
    wire [`TagBus]  LSbufTagO, LSbufTagT, LSbufTagW;
    wire [`NameBus] LSbufNameW;
    wire [`OpBus]   LSbufOp;
    wire [`BranchTagBus] DispBranchTag;

    //output of regf
    wire [`DataBus] regDataO, regDataT;
    wire [`TagBus] regTagO, regTagT;

    //output of ALUrs
    wire ALUworkEn, ALUfree;
    wire [`DataBus] ALUoperandO, ALUoperandT;
    wire [`TagBus]  ALUwrtTag;
    wire [`NameBus] ALUwrtName;
    wire [`OpBus]   ALUopCode;
    wire [`InstAddrBus] ALUaddr;
    wire [`rsSize - 1 : 0]  ALUfreeStatus;
    wire[`BranchTagBus] ALUbranchTag;
    //output of ALU
    wire ALUROBen;
    wire[`TagBus] ALUROBtagW;
    wire[`DataBus] ALUROBdataW;
    wire[`NameBus] ALUROBnameW;
    wire[`BranchTagBus] ALUROBbranchW;
    wire jumpEn;
    wire [`InstAddrBus] jumpAddr;

    //output of BranchRS
    wire BranchWorkEn;
    wire[`DataBus] BranchOperandO, BranchOperandT, BranchImm;
    wire[`OpBus]  BranchOp;
    wire[`InstAddrBus] BranchPC;
    wire[1:0] BranchTagExNum;
    //output of Branch 
    wire BranchEn;
    wire[`InstAddrBus]  BranchAddr;
    wire[`BranchTagBus] bFreeNum;
    wire misTaken;
    //output of LSbuffer
    wire LSworkEn;
    wire[`DataBus] LSoperandO, LSoperandT, LSimm;
    wire[`TagBus] LSwrtTag;
    wire[`NameBus]  LSwrtName;
    wire[`OpBus]  LSop;
    wire LSbufFree;
    wire [`TagRootBus]  freeTagLSroot;

    //output of LS
    wire LSunwork;
    wire dataEn, LSRW;
    wire [`DataAddrBus] dataAddr;
    wire [`LenBus] LSlen;
    wire [`DataBus] Sdata;

    wire LSROBen, LSdone;
    wire [`DataBus] LSROBdata;
    wire [`TagBus]  LSROBtag;
    wire [`NameBus] LSROBname;

  //about icache
    wire hit, memfetchEn;
    wire [`InstBus] cacheInst;
    wire [`InstAddrBus] memfetchAddr;
    wire [`InstAddrBus] addAddr;
  //about ROB
    wire ROBrdO, ROBrdT;
    wire[`DataBus]  ROBrdDataO, ROBrdDataT;
    wire dispatchEn;
    wire ROBfree;
    wire enROBComO;
    wire[`TagBus] ROBComTagO;
    wire[`DataBus]  ROBComDataO;
    wire[`NameBus]  ROBComNameO;

  icache icache(
    .clk(clk_in),
    .rst(rst_in),
    .fetchEn(instEn), 
    .Addr(instAddr), 
    .addEn(instOutEn), 
    .addInst(FetchInst), 
    .addAddr(addAddr), 
    .hit(hit), 
    .foundInst(cacheInst), 
    .memfetchEn(memfetchEn), 
    .memfetchAddr(memfetchAddr)
  );

  mem mcu(
    .clk(clk_in), 
    .rst(rst_in), 
    //with PC
      .fetchEn(memfetchEn), 
      .fetchAddr(memfetchAddr), 
    //output
      .instOutEn(instOutEn), 
      .inst(FetchInst), 
      .addAddr(addAddr), 
    //with LS
    .LSen(dataEn), 
    .LSRW(LSRW), //always 0 for read and 1 for write
    .LSaddr(dataAddr),
    .LSlen(LSlen), 
    .Sdata(Sdata), //is DataFree when it is read
    //output below
      .LSdone(LSoutEn), 
      .LdData(mcuLdata), 
    //with ram
      .RWstate(mem_wr), 
      .RWaddr(mem_a), 
      .ReadData(mem_din), 
      .WrtData(mem_dout), 
    //branch
      .misTaken(misTaken)
  );

  assign stall = ~(ALUfree & LSbufFree & ROBfree & BranchFree);

  fetch fetcher(
      .clk(clk_in), 
      .rst(rst_in), 
      //.rdy(rdy_in),
      .stall(stall), 

      .enJump(jumpEn), 
      .JumpAddr(jumpAddr), 

      .enBranch(BranchEn), 
      .BranchAddr(BranchAddr),

    //to decoder
      .DecEn(DecEn), 
      .DecPC(ToDecAddr), 
      .DecInst(ToDecInst), 
    //with mem and cache
      .memInstOutEn(instOutEn), 
      .memInst(FetchInst), 

      .instEn(instEn), 
      .instAddr(instAddr), 
      .hit(hit), 
      .cacheInst(cacheInst), 
    //branch
      .misTaken(misTaken)
  );
  /*
   * decoder does not need to check if the current inst is mistaken, 
   * since this is finished by IF
   */
  decoder decoder(
    .clk(clk_in), 
    .rst(rst_in),
    .stall(stall),
    .DecEn(DecEn), 
    .instPC(ToDecAddr),
    .inst(ToDecInst),

    //simply output everything to the dispatcher
    .regNameO(DecNameO), 
    .regNameT(DecNameT), 
    .rdName(DecRdName),
    .opCode(DecOp), 
    .opClass(DecOpClass),
    .instAddr(DecAddr), 
    .imm(DecImm), 
    .Uimm(DecUimm), 
    .Jimm(DecJimm), 
    .Simm(DecSimm), 
    .Bimm(DecBimm), 
    .bFreeEn(BranchEn), 
    .bFreeNum(bFreeNum), 
    .BranchTag(DecBranchTag), 
    .BranchFree(BranchFree), 
    .misTaken(misTaken)
  );
  
  dispatcher dispatcher(
    //from decoder
      .rdName(DecRdName),
      .opCode(DecOp),
      .opClass(DecOpClass),
      .instAddr(DecAddr), 
      .imm(DecImm), 
      .Uimm(DecUimm), 
      .Jimm(DecJimm), 
      .Simm(DecSimm), 
      .Bimm(DecBimm), 
    //from regfile
      .regTagO(regTagO), 
      .regDataO(regDataO), 
      .regTagT(regTagT), 
      .regDataT(regDataT), 
    //from Table
      .ALUfreeTag(freeTagALUroot), 
    //from LSbuffer
      .LSfreeTag(freeTagLSroot),
    //to regfile(rename the rd)
      .enWrt(enRegWrt), 
      .wrtTag(RegWrtTag), 
      .wrtName(RegWrtName), 
    //to ALUrs
      .ALUen(ALUrsEn), 
      .ALUoperandO(ALUrsOperandO), 
      .ALUoperandT(ALUrsOperandT), 
      .ALUtagO(ALUrsTagO), 
      .ALUtagT(ALUrsTagT),
      .ALUtagW(ALUrsTagW), 
      .ALUnameW(ALUrsNameW), 
      .ALUop(ALUrsOp), 
      .ALUaddr(ALUrsAddr), 
    //to BranchRS
      .BranchEn(BranchRsEn), 
      .BranchOperandO(BranchRsOperandO), 
      .BranchOperandT(BranchRsOperandT), 
      .BranchTagO(BranchRsTagO), 
      .BranchTagT(BranchRsTagT), 
      .BranchOp(BranchRsOp), 
      .BranchImm(BranchRsImm),
      .BranchAddr(BranchRsAddr),  
    //to LSbuffer
      .LSen(LSbufEn), 
      .LSoperandO(LSbufOperandO), 
      .LSoperandT(LSbufOperandT), 
      .LStagO(LSbufTagO), 
      .LStagT(LSbufTagT),
      .LStagW(LSbufTagW), 
      .LSnameW(LSbufNameW), 
      .LSimm(LSbufImm), 
      .LSop(LSbufOp), 
    //from ROB
      .ROBtagOen(ROBrdO), 
      .ROBdataO(ROBrdDataO), 
      .ROBtagTen(ROBrdT), 
      .ROBdataT(ROBrdDataT), 
      .dispatchEn(dispatchEn), 
    //branchTag
      .bFreeEn(BranchEn), 
      .bFreeNum(bFreeNum), 
      .DecBranchTag(DecBranchTag), 
      .FinalBranchTag(DispBranchTag), 
      .misTaken(misTaken)
  );

  Regfile regf(
    .clk(clk_in), 
    .rst(rst_in), 
    .ALUwrtEn(enROBComO), 
    .ALUwrtData(ROBComDataO),
    .ALUwrtName(ROBComNameO), 
    .ALUwrtTag(ROBComTagO),
    .LSwrtEn(LSROBen), 
    .LSwrtData(LSROBdata),
    .LSwrtName(LSROBname), 
    .LSwrtTag(LSROBtag), 
    //from decoder
      .regNameO(DecNameO), 
      .regNameT(DecNameT), 
    //from dispatcher
      .enWrtDec(enRegWrt), 
      .wrtTagDec(RegWrtTag), 
      .wrtNameDec(RegWrtName), 
    //to dispatcher
      .regDataO(regDataO), 
      .regTagO(regTagO), 
      .regDataT(regDataT), 
      .regTagT(regTagT)
  );

  /*
   * all RS has no need to check if the assigned one should be discarded, 
   * since it is done in dispatcher: alloc is always safe
   */
  ALUrs ALUrs(
    .rst(rst_in),
    .clk(clk_in),
    //from ALU and LS
      .enALUwrt(ALUROBen),
      .ALUtag(ALUROBtagW),
      .ALUdata(ALUROBdataW),
      .enLSwrt(LSROBen), 
      .LStag(LSROBtag), 
      .LSdata(LSROBdata), 
    //from dispatcher
      .ALUen(ALUrsEn), 
      .ALUoperandO(ALUrsOperandO), 
      .ALUoperandT(ALUrsOperandT), 
      .ALUtagO(ALUrsTagO), 
      .ALUtagT(ALUrsTagT),
      .ALUtagW(ALUrsTagW),
      .ALUnameW(ALUrsNameW), 
      .ALUop(ALUrsOp), 
      .ALUaddr(ALUrsAddr), 
      .BranchTag(DispBranchTag), 

    //to ALU
      .ALUworkEn(ALUworkEn), 
      .operandO(ALUoperandO), 
      .operandT(ALUoperandT),
      .wrtTag(ALUwrtTag), 
      .wrtName(ALUwrtName), 
      .opCode(ALUopCode), 
      .instAddr(ALUaddr), 
      .instBranchTag(ALUbranchTag),
    //to dispatcher
      .ALUfree(ALUfree), 
    //branch
      .misTaken(misTaken), 
      .bFreeEn(BranchEn),
      .bFreeNum(bFreeNum)
  );

  ALU ALU(
    //from RS
      .ALUworkEn(ALUworkEn), 
      .operandO(ALUoperandO), 
      .operandT(ALUoperandT), 
      .wrtTag(ALUwrtTag), 
      .wrtName(ALUwrtName), 
      .opCode(ALUopCode), 
      .instAddr(ALUaddr),
      .instBranchTag(ALUbranchTag), 
    //to ROB
      .ROBen(ALUROBen), 
      .ROBtagW(ALUROBtagW), 
      .ROBdataW(ALUROBdataW),
      .ROBnameW(ALUROBnameW), 
      .ROBbranchW(ALUROBbranchW),
    //to PC
      .jumpEn(jumpEn), 
      .jumpAddr(jumpAddr), 
      .misTaken(misTaken), 
      .bFreeEn(BranchEn),
      .bFreeNum(bFreeNum)
  );

  BranchRS BranchRS(
    .rst(rst_in), 
    .clk(clk_in), 
    //from ALU and LS
      .enALUwrt(ALUROBen),
      .ALUtag(ALUROBtagW),
      .ALUdata(ALUROBdataW),
      .enLSwrt(LSROBen), 
      .LStag(LSROBtag), 
      .LSdata(LSROBdata),
    //input from dispatcher
      .BranchEn(BranchRsEn), 
      .BranchOperandO(BranchRsOperandO), 
      .BranchOperandT(BranchRsOperandT), 
      .BranchTagO(BranchRsTagO), 
      .BranchTagT(BranchRsTagT), 
      .BranchOp(BranchRsOp), 
      .BranchImm(BranchRsImm), 
      .BranchPC(BranchRsAddr),
      .BranchTag(DispBranchTag), 
    //to branchEx
      .BranchWorkEn(BranchWorkEn), 
      .operandO(BranchOperandO), 
      .operandT(BranchOperandT), 
      .imm(BranchImm), 
      .opCode(BranchOp), 
      .PC(BranchPC), 
      .bNum(BranchTagExNum), 
      .bFreeEn(BranchEn), 
      .bFreeNum(bFreeNum), 
      .misTaken(misTaken)
  );

  Branch Branch(
    //from the RS
      .BranchWorkEn(BranchWorkEn), 
      .operandO(BranchOperandO), 
      .operandT(BranchOperandT), 
      .imm(BranchImm), 
      .opCode(BranchOp), 
      .PC(BranchPC), 
      .bNum(BranchTagExNum),
    //to the PC
      .BranchResultEn(BranchEn), 
      .BranchAddr(BranchAddr),
      .bFreeNum(bFreeNum), 
      .misTaken(misTaken)
  );

  lsBuffer lsBuffer(
    .rst(rst_in), 
    .clk(clk_in), 
    //from ALU and LS
      .enALUwrt(ALUROBen),
      .ALUtag(ALUROBtagW),
      .ALUdata(ALUROBdataW),
      .enLSwrt(LSROBen), 
      .LStag(LSROBtag), 
      .LSdata(LSROBdata),
    //input from dispatcher
      .LSen(LSbufEn), 
      .LSoperandO(LSbufOperandO), 
      .LSoperandT(LSbufOperandT), 
      .LStagO(LSbufTagO), 
      .LStagT(LSbufTagT), 
      .LStagW(LSbufTagW), 
      .LSnameW(LSbufNameW), 
      .LSop(LSbufOp), 
      .LSimm(LSbufImm), 
      .BranchTag(DispBranchTag), 
    //from the LS
    .LSreadEn(LSunwork), 
    .LSdone(LSoutEn),
    //to LS
    .LSworkEn(LSworkEn), 
    .operandO(LSoperandO), 
    .operandT(LSoperandT),
    .imm(LSimm), 
    .wrtTag(LSwrtTag), 
    .wrtName(LSwrtName), 
    .opCode(LSop), 
    //to dispatcher
    .LSfreeTag(freeTagLSroot),
    .LSbufFree(LSbufFree), 
    //
    .bFreeEn(BranchEn), 
    .bFreeNum(bFreeNum), 
    .misTaken(misTaken)
  );

  LS LS(
    .clk(clk_in), 
    .rst(rst_in), 

    //from lsbuffer
      .LSworkEn(LSworkEn), 
      .operandO(LSoperandO), 
      .operandT(LSoperandT),
      .imm(LSimm), 
      .wrtTag(LSwrtTag), 
      .wrtName(LSwrtName), 
      .opCode(LSop), 

    //to lsbuffer
     .LSunwork(LSunwork), 

    //with mem
      .LSoutEn(LSoutEn), 
      .Ldata(mcuLdata), 

      .dataEn(dataEn), 
      .LSRW(LSRW), 
      .dataAddr(dataAddr),
      .LSlen(LSlen), 
      .Sdata(Sdata),
    //to ROB(fake)
      .LSROBen(LSROBen), 
      .LSROBdata(LSROBdata), 
      .LSROBtag(LSROBtag), 
      .LSROBname(LSROBname), 
      .LSdone(LSdone)
    //
      //.misTaken(misTaken), 
  );
//branchnisation done
  ROB rob(
    .clk(clk_in), 
    .rst(rst_in), 
    //input from alu
    .enWrtO(ALUROBen), 
    .WrtTagO(ALUROBtagW), 
    .WrtDataO(ALUROBdataW), 
    .WrtNameO(ALUROBnameW), 
    .WrtBranchTagO(ALUROBbranchW), 
    //input from LS for precise exception, but not now
    // input wire enWrtT, 
    // input wire[`TagBus] WrtTagT,
    // input wire[`DataBus] WrtDataT,
    // input wire[`NameBus] WrtNameT, 
    //communicate with dispatcher: about write out
    .ReadTagO(regTagO), 
    .ReadTagT(regTagT), 
    .enReadO(ROBrdO), 
    .enReadT(ROBrdT), 
    .ReadDataO(ROBrdDataO), 
    .ReadDataT(ROBrdDataT), 
    //output: commit to regfile
    .ROBfree(ROBfree), 
    .enComO(enROBComO), 
    .ComTagO(ROBComTagO), 
    .ComDataO(ROBComDataO), 
    .ComNameO(ROBComNameO), 
    // output reg enComT, 
    // output reg[`TagBus]     ComTagT, 
    // output reg[`DataBus]    ComDataT, 
    // output reg[`NameBus]    ComNameT, 
    //communicate with Dispatcher: about tagW
    .dispatchEn(dispatchEn), 
    .freeTag(freeTagALUroot), 
    .bFreeEn(BranchEn),
    .bFreeNum(bFreeNum), 
    .misTaken(misTaken)
  );
endmodule